import '../../core/constants/finance_constants.dart';

/// Configuración financiera del usuario (tabla `config` de la web).
class UserConfig {
  final double saldoInicial;
  final double limiteGasto;
  final double objetivoAhorro;
  final double aporteMensual;
  final String moneda; // 'EUR' | 'USD'

  const UserConfig({
    required this.saldoInicial,
    required this.limiteGasto,
    required this.objetivoAhorro,
    required this.aporteMensual,
    this.moneda = 'EUR',
  });

  factory UserConfig.defaults() => const UserConfig(
        saldoInicial: 0,
        limiteGasto: 2500,
        objetivoAhorro: 10000,
        aporteMensual: 300,
        moneda: 'EUR',
      );

  String get simbolo => FinanceConstants.simbolos[moneda] ?? '€';

  Map<String, dynamic> toMap() => {
        FinanceConstants.kSaldoInicial:   saldoInicial,
        FinanceConstants.kLimiteGasto:    limiteGasto,
        FinanceConstants.kObjetivoAhorro: objetivoAhorro,
        FinanceConstants.kAporteMensual:  aporteMensual,
        FinanceConstants.kMoneda:         moneda,
      };

  factory UserConfig.fromMap(Map<String, dynamic> m) => UserConfig(
        saldoInicial:   (m[FinanceConstants.kSaldoInicial]   as num?)?.toDouble() ?? 0,
        limiteGasto:    (m[FinanceConstants.kLimiteGasto]    as num?)?.toDouble() ?? 2500,
        objetivoAhorro: (m[FinanceConstants.kObjetivoAhorro] as num?)?.toDouble() ?? 10000,
        aporteMensual:  (m[FinanceConstants.kAporteMensual]  as num?)?.toDouble() ?? 300,
        moneda:         (m[FinanceConstants.kMoneda] as String?)?.toUpperCase() == 'USD' ? 'USD' : 'EUR',
      );

  UserConfig copyWith({
    double? saldoInicial,
    double? limiteGasto,
    double? objetivoAhorro,
    double? aporteMensual,
    String? moneda,
  }) =>
      UserConfig(
        saldoInicial:   saldoInicial   ?? this.saldoInicial,
        limiteGasto:    limiteGasto    ?? this.limiteGasto,
        objetivoAhorro: objetivoAhorro ?? this.objetivoAhorro,
        aporteMensual:  aporteMensual  ?? this.aporteMensual,
        moneda:         moneda         ?? this.moneda,
      );
}
