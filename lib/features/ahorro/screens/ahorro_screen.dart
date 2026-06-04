import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/finance_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/ahorro.dart';
import '../../../shared/providers/finance_providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/kpi_card.dart';

class AhorroScreen extends ConsumerWidget {
  const AhorroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aportes = ref.watch(ahorrosProvider);
    final cfg = ref.watch(configProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Añadir aporte'),
      ),
      body: aportes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          final total = list.fold<double>(0, (s, e) => s + e.monto);
          final objetivo = cfg?.objetivoAhorro ?? 10000;
          final pct = objetivo > 0 ? (total / objetivo).clamp(0, 1) : 0.0;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  KpiCard(label: '🏦 Total ahorrado', value: Fmt.money(total), accent: AppColors.blue),
                  KpiCard(label: '🎯 Objetivo', value: Fmt.money(objetivo), accent: AppColors.purple),
                  KpiCard(label: '📈 Progreso', value: '${(pct * 100).round()}%', accent: AppColors.teal),
                  KpiCard(label: '💰 Falta', value: Fmt.money((objetivo - total).clamp(0, double.infinity)), accent: AppColors.yellow),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                    value: pct.toDouble(),
                    minHeight: 12,
                    backgroundColor: AppColors.darkBorder,
                    color: AppColors.teal),
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                const EmptyState(icon: '💎', message: 'Aún no hay aportes.')
              else
                for (final a in list)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => _openForm(context, ref, a),
                      title: Text(a.concepto,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(Fmt.date(a.fecha),
                          style: const TextStyle(fontSize: 11, color: AppColors.darkMuted)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('+${Fmt.money(a.monto)}',
                              style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700)),
                          IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.darkMuted),
                              onPressed: () => ref.read(financeRepositoryProvider)!.deleteAhorro(a.id)),
                        ],
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref, Ahorro? ahorro) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AporteForm(
        ahorro: ahorro,
        onSubmit: (a) => ahorro == null
            ? ref.read(financeRepositoryProvider)!.addAhorro(a)
            : ref.read(financeRepositoryProvider)!.updateAhorro(a),
      ),
    );
  }
}

class _AporteForm extends StatefulWidget {
  const _AporteForm({required this.onSubmit, this.ahorro});
  final Future<void> Function(Ahorro) onSubmit;
  final Ahorro? ahorro;
  @override
  State<_AporteForm> createState() => _AporteFormState();
}

class _AporteFormState extends State<_AporteForm> {
  final _form = GlobalKey<FormState>();
  late final _monto = TextEditingController(
      text: widget.ahorro != null ? widget.ahorro!.monto.toStringAsFixed(2) : '');
  late final _concepto = TextEditingController(text: widget.ahorro?.concepto ?? 'Ahorro');
  late DateTime _fecha = widget.ahorro?.fecha ?? DateTime.now();
  late String _persona = widget.ahorro?.persona ?? FinanceConstants.personasBase.first;

  @override
  void dispose() {
    _monto.dispose();
    _concepto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.ahorro == null ? '➕ Añadir aporte' : '✏️ Editar aporte',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _monto,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Importe (€)'),
                validator: (v) =>
                    double.tryParse((v ?? '').replaceAll(',', '.')) == null
                        ? 'Número no válido'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _concepto,
                decoration: const InputDecoration(labelText: 'Concepto'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _persona,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Persona'),
                items: FinanceConstants.personasBase
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _persona = v ?? _persona),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha'),
                trailing: Text(Fmt.date(_fecha),
                    style: const TextStyle(color: AppColors.teal)),
                onTap: () async {
                  final picked = await showDatePicker(
                      context: context,
                      initialDate: _fecha,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100));
                  if (picked != null) setState(() => _fecha = picked);
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  await widget.onSubmit(Ahorro(
                    id: widget.ahorro?.id ?? '',
                    fecha: _fecha,
                    monto: double.parse(_monto.text.replaceAll(',', '.')),
                    persona: _persona,
                    concepto: _concepto.text.trim().isEmpty ? 'Ahorro' : _concepto.text.trim(),
                  ));
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}