import 'package:cloud_firestore/cloud_firestore.dart';

class SharedSpace {
  const SharedSpace({
    required this.id,
    required this.name,
    required this.code,
    required this.members,
    required this.memberNames,
    required this.createdBy,
    required this.createdAt,
    required this.ownerId,
  });

  final String id;
  final String name;
  final String code;
  final List<String> members;           // uids
  final Map<String, String> memberNames; // uid → displayName
  final String createdBy;
  final DateTime createdAt;
  final String ownerId; // dueño actual (puede cambiar al salir)

  factory SharedSpace.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final rawNames = d['memberNames'] as Map<String, dynamic>? ?? {};
    final creator = d['createdBy'] as String;
    return SharedSpace(
      id: doc.id,
      name: d['name'] as String? ?? 'Espacio compartido',
      code: d['code'] as String,
      members: List<String>.from(d['members'] as List),
      memberNames: rawNames.map((k, v) => MapEntry(k, v as String)),
      createdBy: creator,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      // Compatibilidad hacia atrás: espacios sin ownerId usan createdBy
      ownerId: d['ownerId'] as String? ?? creator,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'code': code,
        'members': members,
        'memberNames': memberNames,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'ownerId': ownerId,
      };
}
