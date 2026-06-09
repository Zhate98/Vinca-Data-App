import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/shared_space.dart';

class SharedRepository {
  SharedRepository(this._uid, this._displayName, {FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final String _uid;
  final String _displayName;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _spaces =>
      _db.collection('shared_spaces');

  // ── Generar código único ──────────────────────────────────────────────────
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    final part1 = List.generate(3, (_) => chars[rng.nextInt(chars.length)]).join();
    final part2 = List.generate(3, (_) => chars[rng.nextInt(chars.length)]).join();
    return '$part1-$part2';
  }

  // ── Crear espacio compartido ──────────────────────────────────────────────
  Future<SharedSpace> createSpace(String name) async {
    String code;
    bool exists = true;

    // Asegura que el código sea único
    do {
      code = _generateCode();
      final q = await _spaces.where('code', isEqualTo: code).limit(1).get();
      exists = q.docs.isNotEmpty;
    } while (exists);

    final space = SharedSpace(
      id: '',
      name: name,
      code: code,
      members: [_uid],
      memberNames: {_uid: _displayName},
      createdBy: _uid,
      createdAt: DateTime.now(),
      ownerId: _uid, // creador = dueño inicial
    );

    final ref = await _spaces.add(space.toMap());

    await _db
        .collection('users')
        .doc(_uid)
        .collection('shared_spaces')
        .doc(ref.id)
        .set({'joinedAt': FieldValue.serverTimestamp()});

    return SharedSpace(
      id: ref.id,
      name: space.name,
      code: space.code,
      members: space.members,
      memberNames: space.memberNames,
      createdBy: space.createdBy,
      createdAt: space.createdAt,
      ownerId: space.ownerId,
    );
  }

  // ── Unirse con código ─────────────────────────────────────────────────────
  Future<SharedSpace> joinByCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    final q = await _spaces.where('code', isEqualTo: trimmed).limit(1).get();

    if (q.docs.isEmpty) {
      throw Exception('Código no encontrado');
    }

    final doc = q.docs.first;
    final space = SharedSpace.fromDoc(doc);

    if (space.members.contains(_uid)) {
      throw Exception('Ya formas parte de este espacio');
    }

    if (space.members.length >= 10) {
      throw Exception('El espacio ya tiene demasiados miembros');
    }

    // Añadir uid a members y nombre a memberNames
    await doc.reference.update({
      'members': FieldValue.arrayUnion([_uid]),
      'memberNames.$_uid': _displayName,
    });

    await _db
        .collection('users')
        .doc(_uid)
        .collection('shared_spaces')
        .doc(doc.id)
        .set({'joinedAt': FieldValue.serverTimestamp()});

    return SharedSpace(
      id: doc.id,
      name: space.name,
      code: space.code,
      members: [...space.members, _uid],
      memberNames: {...space.memberNames, _uid: _displayName},
      createdBy: space.createdBy,
      createdAt: space.createdAt,
      ownerId: space.ownerId,
    );
  }

  // ── Espacios del usuario ──────────────────────────────────────────────────
  Stream<List<SharedSpace>> mySpaces() {
    return _spaces
        .where('members', arrayContains: _uid)
        .snapshots()
        .map((snap) => snap.docs.map(SharedSpace.fromDoc).toList());
  }

  // ── Salir de un espacio ───────────────────────────────────────────────────
  // Si el que sale es el dueño y quedan miembros, transfiere ownership al
  // primero en la lista de members (orden de inserción = orden de unión).
  Future<void> leaveSpace(String spaceId) async {
    final spaceDoc = await _spaces.doc(spaceId).get();
    if (!spaceDoc.exists) return;

    final data = spaceDoc.data()!;
    final members = List<String>.from(data['members'] as List? ?? []);
    final ownerId = data['ownerId'] as String? ?? data['createdBy'] as String? ?? '';

    final remaining = members.where((m) => m != _uid).toList();

    if (remaining.isEmpty) {
      // Último miembro: eliminar el espacio entero
      await _deleteSpaceData(spaceId, members);
      return;
    }

    final Map<String, dynamic> updates = {
      'members': FieldValue.arrayRemove([_uid]),
      'memberNames.$_uid': FieldValue.delete(),
    };

    // Transferir ownership si el que sale es el dueño
    if (ownerId == _uid) {
      updates['ownerId'] = remaining.first;
    }

    await _spaces.doc(spaceId).update(updates);

    // Limpiar referencia en el documento personal
    await _db
        .collection('users')
        .doc(_uid)
        .collection('shared_spaces')
        .doc(spaceId)
        .delete();
  }

  // ── Eliminar espacio (solo el dueño) ─────────────────────────────────────
  Future<void> deleteSpace(String spaceId) async {
    final spaceDoc = await _spaces.doc(spaceId).get();
    if (!spaceDoc.exists) return;

    final members = List<String>.from(
        (spaceDoc.data()!['members'] as List?) ?? []);

    await _deleteSpaceData(spaceId, members);
  }

  // ── Borrado interno: sub-colecciones + doc + refs de usuarios ─────────────
  Future<void> _deleteSpaceData(String spaceId, List<String> members) async {
    final spaceRef = _spaces.doc(spaceId);

    // Eliminar documentos de cada sub-colección
    for (final col in [
      'gastos',
      'ingresos',
      'ahorro',
      'deudas',
      'suscripciones',
      'config',
    ]) {
      final snap = await spaceRef.collection(col).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }

    // Eliminar el documento principal
    await spaceRef.delete();

    // Solo borramos nuestra propia referencia (reglas de Firestore no permiten
    // escribir en documentos de otros usuarios). Los demás miembros dejarán de
    // ver el espacio porque el documento raíz ya fue eliminado y mySpaces()
    // usa arrayContains sobre esa colección.
    await _db
        .collection('users')
        .doc(_uid)
        .collection('shared_spaces')
        .doc(spaceId)
        .delete();
  }

  // ── Obtener espacio por ID ────────────────────────────────────────────────
  Future<SharedSpace?> getSpace(String spaceId) async {
    final doc = await _spaces.doc(spaceId).get();
    if (!doc.exists) return null;
    return SharedSpace.fromDoc(doc);
  }

  // ── Actualizar nombre del miembro en todos sus espacios ──────────────────
  Future<void> updateMemberName(String newName) async {
    final snap = await _spaces
        .where('members', arrayContains: _uid)
        .get();
    if (snap.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'memberNames.$_uid': newName});
    }
    await batch.commit();
  }
}
