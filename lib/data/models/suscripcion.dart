import 'package:cloud_firestore/cloud_firestore.dart';

/// Suscripción (tabla `suscripciones` de la web).
class Suscripcion {
  final String id;
  final String nombre;
  final double precioMes;
  final String persona;
  final String categoria;
  final String renovacion;
  final bool activa;

  const Suscripcion({
    required this.id,
    required this.nombre,
    required this.precioMes,
    this.persona = '',
    this.categoria = '',
    this.renovacion = 'Mensual',
    this.activa = true,
  });

  double get costeAnual => precioMes * 12;

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'precioMes': precioMes,
        'persona': persona,
        'categoria': categoria,
        'renovacion': renovacion,
        'activa': activa,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory Suscripcion.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Suscripcion(
      id: d.id,
      nombre: m['nombre'] as String? ?? '',
      precioMes: (m['precioMes'] as num?)?.toDouble() ?? 0,
      persona: m['persona'] as String? ?? '',
      categoria: m['categoria'] as String? ?? '',
      renovacion: m['renovacion'] as String? ?? 'Mensual',
      activa: m['activa'] as bool? ?? true,
    );
  }
}
