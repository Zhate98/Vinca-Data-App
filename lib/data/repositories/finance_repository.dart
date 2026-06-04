import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ahorro.dart';
import '../models/deuda.dart';
import '../models/gasto.dart';
import '../models/ingreso.dart';
import '../models/suscripcion.dart';
import '../models/user_config.dart';

class FinanceRepository {
  FinanceRepository(this._uid, {FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final String _uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db.collection('users').doc(_uid).collection(name);

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

  // ── SETUP (primera vez) ───────────────────────────────────────────────────
  Stream<bool> setupComplete() => _db
      .collection('users')
      .doc(_uid)
      .snapshots()
      .map((s) => (s.data()?['setupComplete'] as bool?) ?? true);

  Future<void> completeSetup(UserConfig config) async {
    await saveConfig(config);
    await _db.collection('users').doc(_uid)
        .update({'setupComplete': true});
  }

  static String _ym(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';
}