import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ahorro.dart';
import '../models/deuda.dart';
import '../models/gasto.dart';
import '../models/ingreso.dart';
import '../models/suscripcion.dart';
import '../models/user_config.dart';

class FinanceRepository {
  FinanceRepository(this._uid, {FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance,
        _isShared = false,
        _spaceId = null,
        _personalUid = null;

  /// Constructor para espacios compartidos
  FinanceRepository.shared(String spaceId, {FirebaseFirestore? firestore, required String uid})
      : _db = firestore ?? FirebaseFirestore.instance,
        _uid = uid,
        _isShared = true,
        _spaceId = spaceId,
        _personalUid = uid;

  final String _uid;
  final FirebaseFirestore _db;
  final bool _isShared;
  final String? _spaceId;
  final String? _personalUid;

  CollectionReference<Map<String, dynamic>> _col(String name) {
    if (_isShared) {
      return _db.collection('shared_spaces').doc(_spaceId).collection(name);
    }
    return _db.collection('users').doc(_uid).collection(name);
  }

  // ── GASTOS ──────────────────────────────────────────────────────────────
  Stream<List<Gasto>> gastosDelMes(int month, int year) {
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    return _col('gastos').orderBy('fecha', descending: true).snapshots().map(
        (s) => s.docs.map(Gasto.fromDoc)
            .where((g) => _ym(g.fecha) == prefix).toList());
  }

  Stream<List<Gasto>> gastosTodos() => _col('gastos')
      .orderBy('fecha', descending: true).snapshots()
      .map((s) => s.docs.map(Gasto.fromDoc).toList());

  Future<void> addGasto(Gasto g)    => _col('gastos').add(g.toMap());
  Future<void> updateGasto(Gasto g) => _col('gastos').doc(g.id).update(g.toMap());
  Future<void> deleteGasto(String id) => _col('gastos').doc(id).delete();

  // ── INGRESOS ─────────────────────────────────────────────────────────────
  Stream<List<Ingreso>> ingresosDelMes(int month, int year) {
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    return _col('ingresos').orderBy('fecha', descending: true).snapshots().map(
        (s) => s.docs.map(Ingreso.fromDoc)
            .where((i) => _ym(i.fecha) == prefix).toList());
  }

  Stream<List<Ingreso>> ingresosTodos() => _col('ingresos')
      .orderBy('fecha', descending: true).snapshots()
      .map((s) => s.docs.map(Ingreso.fromDoc).toList());

  Future<void> addIngreso(Ingreso i)    => _col('ingresos').add(i.toMap());
  Future<void> updateIngreso(Ingreso i) => _col('ingresos').doc(i.id).update(i.toMap());
  Future<void> deleteIngreso(String id) => _col('ingresos').doc(id).delete();

  // ── AHORRO ───────────────────────────────────────────────────────────────
  Stream<List<Ahorro>> ahorros() => _col('ahorro')
      .orderBy('fecha', descending: true).snapshots()
      .map((s) => s.docs.map(Ahorro.fromDoc).toList());

  Future<void> addAhorro(Ahorro a)    => _col('ahorro').add(a.toMap());
  Future<void> updateAhorro(Ahorro a) => _col('ahorro').doc(a.id).update(a.toMap());
  Future<void> deleteAhorro(String id) => _col('ahorro').doc(id).delete();

  // ── DEUDAS ───────────────────────────────────────────────────────────────
  Stream<List<Deuda>> deudas() => _col('deudas')
      .orderBy('createdAt', descending: true).snapshots()
      .map((s) => s.docs.map(Deuda.fromDoc).toList());

  Future<void> addDeuda(Deuda d)    => _col('deudas').add(d.toMap());
  Future<void> updateDeuda(Deuda d) => _col('deudas').doc(d.id).update(d.toMap());
  Future<void> deleteDeuda(String id) => _col('deudas').doc(id).delete();

  // ── SUSCRIPCIONES ─────────────────────────────────────────────────────────
  Stream<List<Suscripcion>> suscripciones() => _col('suscripciones')
      .where('activa', isEqualTo: true).snapshots()
      .map((s) => s.docs.map(Suscripcion.fromDoc).toList());

  Future<void> addSuscripcion(Suscripcion s)    => _col('suscripciones').add(s.toMap());
  Future<void> updateSuscripcion(Suscripcion s) =>
      _col('suscripciones').doc(s.id).update(s.toMap());
  Future<void> deleteSuscripcion(String id) =>
      _col('suscripciones').doc(id).update({'activa': false});

  // ── CONFIG ────────────────────────────────────────────────────────────────
  DocumentReference<Map<String, dynamic>> get _configRef =>
      _col('config').doc('finance');

  Stream<UserConfig> config() => _configRef.snapshots().map(
      (d) => d.exists ? UserConfig.fromMap(d.data()!) : UserConfig.defaults());

  Future<void> saveConfig(UserConfig c) =>
      _configRef.set(c.toMap(), SetOptions(merge: true));

  /// Renombra el campo `persona` en todas las colecciones del contexto actual.
  /// Solo relevante en espacios compartidos (en personal se usan "Yo"/"Pareja"/etc.)
  Future<void> renamePersona(String oldName, String newName) async {
    if (oldName.isEmpty || newName.isEmpty || oldName == newName) return;

    for (final colName in ['gastos', 'ingresos', 'ahorro', 'deudas', 'suscripciones']) {
      final snap = await _col(colName)
          .where('persona', isEqualTo: oldName)
          .get();
      if (snap.docs.isEmpty) continue;

      WriteBatch batch = _db.batch();
      int count = 0;
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'persona': newName});
        count++;
        if (count >= 499) {
          await batch.commit();
          batch = _db.batch();
          count = 0;
        }
      }
      if (count > 0) await batch.commit();
    }
  }

  /// Devuelve los valores de `persona` que existen en las transacciones pero
  /// ya no coinciden con ningún nombre activo en el espacio (nombres huérfanos).
  /// Útil para detectar y corregir nombres desactualizados.
  Future<Set<String>> findOrphanedPersonas(List<String> currentMemberNames) async {
    final orphaned = <String>{};
    for (final colName in ['gastos', 'ingresos', 'ahorro', 'deudas', 'suscripciones']) {
      final snap = await _col(colName).get();
      for (final doc in snap.docs) {
        final persona = (doc.data()['persona'] as String?) ?? '';
        if (persona.isNotEmpty && !currentMemberNames.contains(persona)) {
          orphaned.add(persona);
        }
      }
    }
    return orphaned;
  }

  // ── SETUP (primera vez) — solo para contexto personal ────────────────────
  Stream<bool> setupComplete() {
    final uid = _personalUid ?? _uid;
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((s) => (s.data()?['setupComplete'] as bool?) ?? true);
  }

  Future<void> completeSetup(UserConfig config) async {
    final uid = _personalUid ?? _uid;
    // Marcar primero para que si userChanges() dispara entre medio,
    // el stream ya lea true y no vuelva a mostrar el diálogo.
    await _db.collection('users').doc(uid)
        .set({'setupComplete': true}, SetOptions(merge: true));
    await saveConfig(config);
  }

  static String _ym(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';
}