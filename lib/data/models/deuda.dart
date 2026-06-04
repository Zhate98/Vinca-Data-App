import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/formatters.dart';

/// Deuda (tabla `deudas` de la web).
class Deuda {
  final String id;
  final String descripcion;
  final double total;
  final double pagado;
  final DateTime? vencimiento;
  final String persona;

  const Deuda({
    required this.id,
    required this.descripcion,
    required this.total,
    this.pagado = 0,
    this.vencimiento,
    this.persona = '',
  });

  double get pendiente => (total - pagado).clamp(0, double.infinity);
  double get progreso => total > 0 ? (pagado / total).clamp(0, 1) : 0;

  Map<String, dynamic> toMap() => {
        'descripcion': descripcion,
        'total': total,
        'pagado': pagado,
        'vencimiento': vencimiento == null ? '' : Fmt.iso(vencimiento!),
        'persona': persona,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory Deuda.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final v = m['vencimiento'] as String? ?? '';
    return Deuda(
      id: d.id,
      descripcion: m['descripcion'] as String? ?? '',
      total: (m['total'] as num?)?.toDouble() ?? 0,
      pagado: (m['pagado'] as num?)?.toDouble() ?? 0,
      vencimiento: v.isEmpty ? null : Fmt.parseIso(v),
      persona: m['persona'] as String? ?? '',
    );
  }
}
