import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/formatters.dart';

/// Gasto (tabla `gastos` de la web).
class Gasto {
  final String id;
  final DateTime fecha;
  final String descripcion;
  final String categoria;
  final String metodo;
  final double monto;
  final String persona;
  final String tipo;
  final String comentario;

  const Gasto({
    required this.id,
    required this.fecha,
    required this.descripcion,
    required this.categoria,
    required this.metodo,
    required this.monto,
    required this.persona,
    required this.tipo,
    this.comentario = '',
  });

  Map<String, dynamic> toMap() => {
        'fecha': Fmt.iso(fecha),
        'descripcion': descripcion,
        'categoria': categoria,
        'metodo': metodo,
        'monto': monto,
        'persona': persona,
        'tipo': tipo,
        'comentario': comentario,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory Gasto.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Gasto(
      id: d.id,
      fecha: Fmt.parseIso(m['fecha'] as String? ?? ''),
      descripcion: m['descripcion'] as String? ?? '',
      categoria: m['categoria'] as String? ?? '📦 Otros',
      metodo: m['metodo'] as String? ?? '',
      monto: (m['monto'] as num?)?.toDouble() ?? 0,
      persona: m['persona'] as String? ?? '',
      tipo: m['tipo'] as String? ?? '',
      comentario: m['comentario'] as String? ?? '',
    );
  }
}
