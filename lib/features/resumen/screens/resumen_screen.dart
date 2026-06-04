import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/finance_providers.dart';
import '../../../shared/widgets/section_card.dart';

/// Año seleccionado en el resumen.
final _resumenYearProvider =
    StateProvider.autoDispose<int>((ref) => DateTime.now().year);

class ResumenScreen extends ConsumerWidget {
  const ResumenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(_resumenYearProvider);
    final gastos = ref.watch(gastosTodosProvider);
    final ingresos = ref.watch(ingresosTodosProvider);
    final ahorros = ref.watch(ahorrosProvider);

    final loading = gastos.isLoading || ingresos.isLoading || ahorros.isLoading;
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final gs = gastos.valueOrNull ?? [];
    final is_ = ingresos.valueOrNull ?? [];
    final as_ = ahorros.valueOrNull ?? [];

    // 12 meses del año.
    final rows = List.generate(12, (idx) {
      final mm = idx + 1;
      bool inMonth(DateTime d) => d.year == year && d.month == mm;
      final ing = is_
          .where((e) => inMonth(e.fecha))
          .fold<double>(0, (s, e) => s + e.monto);
      final gas = gs
          .where((e) => inMonth(e.fecha))
          .fold<double>(0, (s, e) => s + e.monto);
      final aho = as_
          .where((e) => inMonth(e.fecha))
          .fold<double>(0, (s, e) => s + e.monto);
      return (mm, ing, gas, aho, ing - gas);
    });

    // Ranking de categorías del año.
    final ranking = <String, double>{};
    for (final g in gs.where((e) => e.fecha.year == year)) {
      ranking[g.categoria] = (ranking[g.categoria] ?? 0) + g.monto;
    }
    final rankSorted = ranking.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Selector de año.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                onPressed: () =>
                    ref.read(_resumenYearProvider.notifier).state = year - 1,
                icon: const Icon(Icons.chevron_left)),
            Text('$year',
                style: const TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            IconButton(
                onPressed: () =>
                    ref.read(_resumenYearProvider.notifier).state = year + 1,
                icon: const Icon(Icons.chevron_right)),
          ],
        ),
        const SizedBox(height: 8),

        // Tabla 12 meses.
        SectionCard(
          title: 'Resumen mensual $year',
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 36,
              dataRowMinHeight: 34,
              dataRowMaxHeight: 40,
              columnSpacing: 22,
              headingTextStyle: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
              columns: const [
                DataColumn(label: Text('MES')),
                DataColumn(label: Text('INGRESOS')),
                DataColumn(label: Text('GASTOS')),
                DataColumn(label: Text('AHORRO')),
                DataColumn(label: Text('BALANCE')),
              ],
              rows: [
                for (final r in rows)
                  DataRow(cells: [
                    DataCell(Text(Fmt.meses[r.$1 - 1])),
                    DataCell(Text(Fmt.money(r.$2),
                        style: const TextStyle(color: AppColors.green))),
                    DataCell(Text(Fmt.money(r.$3),
                        style: const TextStyle(color: AppColors.red))),
                    DataCell(Text(Fmt.money(r.$4),
                        style: const TextStyle(color: AppColors.blue))),
                    DataCell(Text(Fmt.money(r.$5),
                        style: TextStyle(
                            color: r.$5 >= 0 ? AppColors.green : AppColors.red,
                            fontWeight: FontWeight.w700))),
                  ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Ranking de categorías.
        SectionCard(
          title: '🏆 Ranking categorías — $year',
          child: rankSorted.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Sin gastos este año',
                      style: TextStyle(color: AppColors.darkMuted)),
                )
              : Column(
                  children: [
                    for (var i = 0; i < rankSorted.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Text('${i + 1}.',
                                style: const TextStyle(
                                    color: AppColors.darkMuted,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(rankSorted[i].key)),
                            Text(Fmt.money(rankSorted[i].value),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
