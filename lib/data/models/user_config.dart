import '../../core/constants/finance_constants.dart';

/// Configuración financiera del usuario (tabla `config` de la web).
class UserConfig {
  final double saldoInicial;
  final double limiteGasto;
  final double objetivoAhorro;
  final double aporteMensual;

  const UserConfig({
    required this.saldoInicial,
    required this.limiteGasto,
    required this.objetivoAhorro,
    required this.aporteMensual,
  });

  factory UserConfig.defaults() => const UserConfig(
        saldoInicial: 5000,
        limiteGasto: 2500,
        objetivoAhorro: 10000,
        aporteMensual: 300,
      );

  Map<String, dynamic> toMap() => {
        FinanceConstants.kSaldoInicial: saldoInicial,
        FinanceConstants.kLimiteGasto: limiteGasto,
        FinanceConstants.kObjetivoAhorro: objetivoAhorro,
        FinanceConstants.kAporteMensual: aporteMensual,
      };

  factory UserConfig.fromMap(Map<String, dynamic> m) => UserConfig(
        saldoInicial: (m[FinanceConstants.kSaldoInicial] as num?)?.toDouble() ?? 0000,
        limiteGasto: (m[FinanceConstants.kLimiteGasto] as num?)?.toDouble() ?? 2500,
        objetivoAhorro: (m[FinanceConstants.kObjetivoAhorro] as num?)?.toDouble() ?? 10000,
        aporteMensual: (m[FinanceConstants.kAporteMensual] as num?)?.toDouble() ?? 300,
      );

  UserConfig copyWith({
    double? saldoInicial,
    double? limiteGasto,
    double? objetivoAhorro,
    double? aporteMensual,
  }) =>
      UserConfig(
        saldoInicial: saldoInicial ?? this.saldoInicial,
        limiteGasto: limiteGasto ?? this.limiteGasto,
        objetivoAhorro: objetivoAhorro ?? this.objetivoAhorro,
        aporteMensual: aporteMensual ?? this.aporteMensual,
      );
}
