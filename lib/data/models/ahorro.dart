import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/formatters.dart';

/// Aporte de ahorro (tabla `ahorro` de la web).
class Ahorro {
  final String id;
  final DateTime fecha;
  final double monto;
  final String persona;
  final String concepto;

  const Ahorro({
    required this.id,
    required this.fecha,
    required this.monto,
    required this.persona,
    this.concepto = 'Ahorro',
  });

  Map<String, dynamic> toMap() => {
        'fecha': Fmt.iso(fecha),
        'monto': monto,
        'persona': persona,
        'concepto': concepto,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory Ahorro.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Ahorro(
      id: d.id,
      fecha: Fmt.parseIso(m['fecha'] as String? ?? ''),
      monto: (m['monto'] as num?)?.toDouble() ?? 0,
      persona: m['persona'] as String? ?? '',
      concepto: m['concepto'] as String? ?? 'Ahorro',
    );
  }
}
