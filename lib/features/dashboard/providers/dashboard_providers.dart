import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_config.dart';
import '../../../shared/providers/finance_providers.dart';
import '../../../shared/providers/month_provider.dart';

/// Datos agregados del dashboard (equivalente a /api/dashboard de la web).
class DashboardData {
  final double saldoActual;
  final double ingresosMes;
  final double gastosMes;
  final double ahorroTotal;
  final double balanceMes;
  final double limite;
  final double metaAhorro;
  final Map<String, double> porCategoria; // categoría -> total del mes
  final List<double> evol6mGastos; // 6 meses (incluye actual)
  final List<double> evol6mIngresos;
  final List<String> evol6mLabels;

  const DashboardData({
    required this.saldoActual,
    required this.ingresosMes,
    required this.gastosMes,
    required this.ahorroTotal,
    required this.balanceMes,
    required this.limite,
    required this.metaAhorro,
    required this.porCategoria,
    required this.evol6mGastos,
    required this.evol6mIngresos,
    required this.evol6mLabels,
  });

  double get pctLimite => limite > 0 ? (gastosMes / limite).clamp(0, 1.5) : 0;
  double get pctAhorro =>
      metaAhorro > 0 ? (ahorroTotal / metaAhorro).clamp(0, 1) : 0;
  double get faltaAhorro =>
      (metaAhorro - ahorroTotal).clamp(0, double.infinity);
}

/// Combina todos los streams para calcular el dashboard del mes seleccionado.
/// Sin autoDispose: se mantiene vivo entre pantallas para que config y transacciones
/// se reflejen inmediatamente al volver al dashboard.
final dashboardProvider = Provider<AsyncValue<DashboardData>>((ref) {
  final gastosMes = ref.watch(gastosMesProvider);
  final ingresosMes = ref.watch(ingresosMesProvider);
  final gastosAll = ref.watch(gastosTodosProvider);
  final ingresosAll = ref.watch(ingresosTodosProvider);
  final ahorros = ref.watch(ahorrosProvider);
  final cfgAsync = ref.watch(configProvider);
  final month = ref.watch(_monthRefProvider);

  // Propaga loading/error si algún stream aún no resolvió.
  final loading = [gastosMes, ingresosMes, gastosAll, ingresosAll, ahorros, cfgAsync]
      .any((a) => a.isLoading && !a.hasValue);
  if (loading) return const AsyncValue.loading();

  final cfg = cfgAsync.valueOrNull ?? UserConfig.defaults();
  final gm = gastosMes.valueOrNull ?? [];
  final im = ingresosMes.valueOrNull ?? [];
  final gAll = gastosAll.valueOrNull ?? [];
  final iAll = ingresosAll.valueOrNull ?? [];
  final aAll = ahorros.valueOrNull ?? [];

  final ingresosMesT = im.fold<double>(0, (s, e) => s + e.monto);
  final gastosMesT = gm.fold<double>(0, (s, e) => s + e.monto);
  final totalIng = iAll.fold<double>(0, (s, e) => s + e.monto);
  final totalGas = gAll.fold<double>(0, (s, e) => s + e.monto);
  final ahorroTotal = aAll.fold<double>(0, (s, e) => s + e.monto);
  final saldo = cfg.saldoInicial + totalIng - totalGas;

  final porCat = <String, double>{};
  for (final g in gm) {
    porCat[g.categoria] = (porCat[g.categoria] ?? 0) + g.monto;
  }

  // Evolución 6 meses.
  final labels = <String>[];
  final eg = <double>[];
  final ei = <double>[];
  for (var i = 5; i >= 0; i--) {
    var mm = month.$1 - i;
    var yy = month.$2;
    while (mm <= 0) {
      mm += 12;
      yy -= 1;
    }
    final pre = '$yy-${mm.toString().padLeft(2, '0')}';
    eg.add(gAll
        .where((g) => _ym(g.fecha) == pre)
        .fold<double>(0, (s, e) => s + e.monto));
    ei.add(iAll
        .where((g) => _ym(g.fecha) == pre)
        .fold<double>(0, (s, e) => s + e.monto));
    labels.add(_mesCorto(mm));
  }

  return AsyncValue.data(DashboardData(
    saldoActual: saldo,
    ingresosMes: ingresosMesT,
    gastosMes: gastosMesT,
    ahorroTotal: ahorroTotal,
    balanceMes: ingresosMesT - gastosMesT,
    limite: cfg.limiteGasto,
    metaAhorro: cfg.objetivoAhorro,
    porCategoria: porCat,
    evol6mGastos: eg,
    evol6mIngresos: ei,
    evol6mLabels: labels,
  ));
});

// Pequeño provider auxiliar para acceder a (month, year) como tupla.
final _monthRefProvider = Provider<(int, int)>((ref) {
  final m = ref.watch(selectedMonthProvider);
  return (m.month, m.year);
});

String _ym(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';
String _mesCorto(int m) =>
    const ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'][m - 1];
