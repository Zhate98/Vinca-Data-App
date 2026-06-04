import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/formatters.dart';

/// Ingreso (tabla `ingresos` de la web).
class Ingreso {
  final String id;
  final DateTime fecha;
  final String descripcion;
  final double monto;
  final String persona;
  final String tipo;
  final String comentario;

  const Ingreso({
    required this.id,
    required this.fecha,
    required this.descripcion,
    required this.monto,
    required this.persona,
    required this.tipo,
    this.comentario = '',
  });

  Map<String, dynamic> toMap() => {
        'fecha': Fmt.iso(fecha),
        'descripcion': descripcion,
        'monto': monto,
        'persona': persona,
        'tipo': tipo,
        'comentario': comentario,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory Ingreso.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Ingreso(
      id: d.id,
      fecha: Fmt.parseIso(m['fecha'] as String? ?? ''),
      descripcion: m['descripcion'] as String? ?? '',
      monto: (m['monto'] as num?)?.toDouble() ?? 0,
      persona: m['persona'] as String? ?? '',
      tipo: m['tipo'] as String? ?? '💰 Otros',
      comentario: m['comentario'] as String? ?? '',
    );
  }
}
