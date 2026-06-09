/// Constantes de dominio, copiadas literalmente de la web (index.html).
class FinanceConstants {
  FinanceConstants._();

  /// Categorías de gasto (CATS en la web).
  static const List<String> categorias = [
    '🍔 Comida',
    '🚗 Transporte',
    '🏠 Vivienda',
    '🎬 Entretenimiento',
    '💊 Salud',
    '🛍️ Compras',
    '📱 Suscripciones',
    '✈️ Viajes',
    '🐾 Mascotas',
    '📦 Otros',
  ];

  /// Métodos de pago (METHODS).
  static const List<String> metodos = [
    '💵 Efectivo',
    '💳 Tarjeta débito',
    '💎 Tarjeta crédito',
    '📱 Bizum',
    '🏦 Transferencia',
  ];

  /// Tipos de gasto (EXP_TYPES).
  static const List<String> tiposGasto = [
    '📆 Diario',
    '📅 Semanal',
    '🗓️ Mensual',
    '⚡ Extraordinario',
    '🏠 Gasto fijo',
  ];

  /// Tipos de ingreso (INC_TYPES).
  static const List<String> tiposIngreso = [
    '💼 Nómina',
    '🔧 Freelance',
    '🎁 Regalo',
    '📈 Inversión',
    '🏦 Intereses',
    '💰 Otros',
  ];

  /// Personas (PERSONS). El primero se sustituye por el nombre del usuario.
  static const List<String> personasBase = ['Yo', 'Pareja', 'Otro'];

  /// Periodicidad de suscripciones.
  static const List<String> renovaciones = ['Mensual', 'Trimestral', 'Anual'];

  // Claves de configuración (tabla `config` en la web).
  static const String kSaldoInicial  = 'saldo_inicial';
  static const String kLimiteGasto   = 'limite_gasto';
  static const String kObjetivoAhorro = 'objetivo_ahorro';
  static const String kAporteMensual  = 'aporte_mensual';
  static const String kMoneda         = 'moneda';

  /// Monedas disponibles con su símbolo.
  static const List<String> monedas = ['EUR', 'USD'];
  static const Map<String, String> simbolos = {
    'EUR': '€',
    'USD': '\$',
  };

  static const Map<String, double> configDefaults = {
    kSaldoInicial: 000,
    kLimiteGasto: 2500,
    kObjetivoAhorro: 10000,
    kAporteMensual: 300,
  };
}
