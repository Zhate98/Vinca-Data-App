import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kpi_card.dart';
import '../../../shared/widgets/section_card.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/category_donut.dart';
import '../widgets/evolution_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (d) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── KPIs (grid 2 columnas) ──────────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              KpiCard(
                  label: '💰 Saldo actual',
                  value: Fmt.money(d.saldoActual),
                  accent: AppColors.teal),
              KpiCard(
                  label: '📥 Ingresos mes',
                  value: Fmt.money(d.ingresosMes),
                  accent: AppColors.green),
              KpiCard(
                  label: '📤 Gastos mes',
                  value: Fmt.money(d.gastosMes),
                  accent: AppColors.red),
              KpiCard(
                  label: '🏦 Total ahorrado',
                  value: Fmt.money(d.ahorroTotal),
                  accent: AppColors.blue),
              KpiCard(
                  label: '📊 Balance del mes',
                  value: Fmt.money(d.balanceMes),
                  accent: d.balanceMes >= 0 ? AppColors.green : AppColors.red),
              KpiCard(
                  label: '🎯 Meta de ahorro',
                  value: '${(d.pctAhorro * 100).round()}%',
                  sub: 'Falta ${Fmt.money(d.faltaAhorro)}',
                  accent: AppColors.purple),
            ],
          ),
          const SizedBox(height: 16),

          // ── Gasto vs límite ─────────────────────────────────────────────
          SectionCard(
            title: '⚠️ Gasto vs límite (${Fmt.money(d.limite)})',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: d.pctLimite.clamp(0, 1),
                    minHeight: 10,
                    backgroundColor: AppColors.darkBorder,
                    color: d.pctLimite >= 1 ? AppColors.red : AppColors.yellow,
                  ),
                ),
                const SizedBox(height: 6),
                Text('${Fmt.money(d.gastosMes)} de ${Fmt.money(d.limite)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.darkMuted)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Donut categorías ────────────────────────────────────────────
          SectionCard(
              title: 'Gasto por categoría',
              child: CategoryDonut(data: d.porCategoria)),
          const SizedBox(height: 16),

          // ── Evolución 6 meses ───────────────────────────────────────────
          SectionCard(
            title: 'Evolución (6 meses)',
            child: EvolutionChart(
              ingresos: d.evol6mIngresos,
              gastos: d.evol6mGastos,
              labels: d.evol6mLabels,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
