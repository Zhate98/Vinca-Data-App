import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/finance_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/deuda.dart';
import '../../../shared/providers/finance_providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/kpi_card.dart';

class DeudasScreen extends ConsumerWidget {
  const DeudasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(deudasProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Nueva deuda'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          final total = list.fold<double>(0, (s, e) => s + e.total);
          final pagado = list.fold<double>(0, (s, e) => s + e.pagado);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
                children: [
                  KpiCard(label: '💳 Total', value: Fmt.money(total), accent: AppColors.red),
                  KpiCard(label: '✅ Pagado', value: Fmt.money(pagado), accent: AppColors.green),
                  KpiCard(label: '⏳ Pendiente', value: Fmt.money(total - pagado), accent: AppColors.yellow),
                ],
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                const EmptyState(icon: '💳', message: 'Sin deudas registradas.')
              else
                for (final d in list)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _openForm(context, ref, d),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(d.descripcion,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                                IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20, color: AppColors.darkMuted),
                                    onPressed: () => ref
                                        .read(financeRepositoryProvider)!
                                        .deleteDeuda(d.id)),
                              ],
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                  value: d.progreso,
                                  minHeight: 8,
                                  backgroundColor: AppColors.darkBorder,
                                  color: AppColors.green),
                            ),
                            const SizedBox(height: 6),
                            Text(
                                '${Fmt.money(d.pagado)} / ${Fmt.money(d.total)} · pendiente ${Fmt.money(d.pendiente)}'
                                '${d.vencimiento != null ? ' · vence ${Fmt.date(d.vencimiento!)}' : ''}',
                                style: const TextStyle(fontSize: 11, color: AppColors.darkMuted)),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref, Deuda? deuda) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DeudaForm(
        deuda: deuda,
        onSubmit: (d) => deuda == null
            ? ref.read(financeRepositoryProvider)!.addDeuda(d)
            : ref.read(financeRepositoryProvider)!.updateDeuda(d),
      ),
    );
  }
}

class _DeudaForm extends StatefulWidget {
  const _DeudaForm({required this.onSubmit, this.deuda});
  final Future<void> Function(Deuda) onSubmit;
  final Deuda? deuda;
  @override
  State<_DeudaForm> createState() => _DeudaFormState();
}

class _DeudaFormState extends State<_DeudaForm> {
  final _form = GlobalKey<FormState>();
  late final _desc = TextEditingController(text: widget.deuda?.descripcion ?? '');
  late final _total = TextEditingController(
      text: widget.deuda != null ? widget.deuda!.total.toStringAsFixed(2) : '');
  late final _pagado = TextEditingController(
      text: widget.deuda != null ? widget.deuda!.pagado.toStringAsFixed(2) : '0');
  late DateTime? _venc = widget.deuda?.vencimiento;
  late String _persona = widget.deuda?.persona ?? FinanceConstants.personasBase.first;

  @override
  void dispose() {
    _desc.dispose();
    _total.dispose();
    _pagado.dispose();
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
              Text(widget.deuda == null ? '➕ Nueva deuda' : '✏️ Editar deuda',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _total,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Total (€)'),
                validator: (v) =>
                    double.tryParse((v ?? '').replaceAll(',', '.')) == null
                        ? 'Número no válido'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pagado,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Ya pagado (€)'),
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
                title: const Text('Vencimiento (opcional)'),
                trailing: Text(_venc == null ? 'Sin fecha' : Fmt.date(_venc!),
                    style: const TextStyle(color: AppColors.teal)),
                onTap: () async {
                  final picked = await showDatePicker(
                      context: context,
                      initialDate: _venc ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100));
                  if (picked != null) setState(() => _venc = picked);
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  await widget.onSubmit(Deuda(
                    id: widget.deuda?.id ?? '',
                    descripcion: _desc.text.trim(),
                    total: double.parse(_total.text.replaceAll(',', '.')),
                    pagado: double.tryParse(_pagado.text.replaceAll(',', '.')) ?? 0,
                    vencimiento: _venc,
                    persona: _persona,
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