import 'package:intl/intl.dart';

/// Formateo idéntico al de la web: moneda EUR, locale es-ES, 2 decimales.
class Fmt {
  Fmt._();

  static final NumberFormat _eur = NumberFormat.currency(
    locale: 'es_ES',
    symbol: '€',
    decimalDigits: 2,
  );

  static final DateFormat _date = DateFormat('dd MMM yyyy', 'es_ES');
  static final DateFormat _iso = DateFormat('yyyy-MM-dd');

  static String money(num? value) => _eur.format(value ?? 0);

  static String date(DateTime d) => _date.format(d);

  /// Formato almacenado en Firestore (compatible con la web: 'YYYY-MM-DD').
  static String iso(DateTime d) => _iso.format(d);

  static DateTime parseIso(String s) =>
      DateTime.tryParse(s) ?? DateTime.now();

  static const List<String> meses = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  static const List<String> mesesLargos = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  static String mesLabel(int month, int year) =>
      '${mesesLargos[month - 1]} $year';
}
