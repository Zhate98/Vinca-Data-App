import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/finance_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/ingreso.dart';
import '../../../shared/providers/finance_providers.dart';
import '../../../shared/widgets/empty_state.dart';

class IngresosScreen extends ConsumerStatefulWidget {
  const IngresosScreen({super.key});
  @override
  ConsumerState<IngresosScreen> createState() => _IngresosScreenState();
}

class _IngresosScreenState extends ConsumerState<IngresosScreen> {
  String? _selectedTipo;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ingresosMesProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo ingreso'),
      ),
      body: Column(
        children: [
          _FilterBar(
            items: FinanceConstants.tiposIngreso,
            selected: _selectedTipo,
            allLabel: 'Todos',
            onSelected: (v) => setState(() => _selectedTipo = v),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) {
                final filtered = _selectedTipo == null
                    ? items
                    : items.where((i) => i.tipo == _selectedTipo).toList();
                if (filtered.isEmpty) {
                  return const EmptyState(
                      icon: '📋',
                      message: 'No hay ingresos este mes.');
                }
                final total =
                    filtered.fold<double>(0, (s, e) => s + e.monto);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  children: [
                    Text('Total: ${Fmt.money(total)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.green)),
                    const SizedBox(height: 10),
                    for (final i in filtered)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () => _openForm(context, ref, i),
                          title: Text(i.descripcion,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${i.tipo} · ${Fmt.date(i.fecha)}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.darkMuted)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('+${Fmt.money(i.monto)}',
                                  style: const TextStyle(
                                      color: AppColors.green,
                                      fontWeight: FontWeight.w700)),
                              IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 20,
                                      color: AppColors.darkMuted),
                                  onPressed: () => ref
                                      .read(financeRepositoryProvider)!
                                      .deleteIngreso(i.id)),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref, Ingreso? ingreso) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _IngresoForm(
        ingreso: ingreso,
        onSubmit: (i) => ingreso == null
            ? ref.read(financeRepositoryProvider)!.addIngreso(i)
            : ref.read(financeRepositoryProvider)!.updateIngreso(i),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar(
      {required this.items,
      required this.selected,
      required this.onSelected,
      this.allLabel = 'Todas'});
  final List<String> items;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(allLabel),
              selected: selected == null,
              selectedColor: AppColors.teal,
              onSelected: (_) => onSelected(null),
              labelStyle: TextStyle(
                  color:
                      selected == null ? AppColors.darkBg : null,
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
            ),
          ),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(item),
                selected: selected == item,
                selectedColor: AppColors.teal,
                onSelected: (_) =>
                    onSelected(selected == item ? null : item),
                labelStyle: TextStyle(
                    color: selected == item ? AppColors.darkBg : null,
                    fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _IngresoForm extends StatefulWidget {
  const _IngresoForm({required this.onSubmit, this.ingreso});
  final Future<void> Function(Ingreso) onSubmit;
  final Ingreso? ingreso;
  @override
  State<_IngresoForm> createState() => _IngresoFormState();
}

class _IngresoFormState extends State<_IngresoForm> {
  final _form  = GlobalKey<FormState>();
  late final _desc  = TextEditingController(
      text: widget.ingreso?.descripcion ?? '');
  late final _monto = TextEditingController(
      text: widget.ingreso != null
          ? widget.ingreso!.monto.toStringAsFixed(2) : '');
  late DateTime _fecha  = widget.ingreso?.fecha ?? DateTime.now();
  late String   _tipo   = widget.ingreso?.tipo   ?? FinanceConstants.tiposIngreso.first;
  late String   _persona= widget.ingreso?.persona ?? FinanceConstants.personasBase.first;

  @override
  void dispose() {
    _desc.dispose(); _monto.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    await widget.onSubmit(Ingreso(
      id: widget.ingreso?.id ?? '',
      fecha: _fecha,
      descripcion: _desc.text.trim(),
      monto: double.parse(_monto.text.replaceAll(',', '.')),
      persona: _persona,
      tipo: _tipo,
    ));
    if (mounted) Navigator.pop(context);
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
              Text(widget.ingreso == null
                      ? '➕ Nuevo ingreso' : '✏️ Editar ingreso',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _desc,
                decoration:
                    const InputDecoration(labelText: 'Descripción'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _monto,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Importe (€)'),
                validator: (v) =>
                    double.tryParse((v ?? '').replaceAll(',', '.')) == null
                        ? 'Número no válido' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _tipo,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: FinanceConstants.tiposIngreso
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _tipo = v ?? _tipo),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _persona,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Persona'),
                items: FinanceConstants.personasBase
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _persona = v ?? _persona),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha'),
                trailing: Text(Fmt.date(_fecha),
                    style: const TextStyle(color: AppColors.teal)),
                onTap: () async {
                  final p = await showDatePicker(
                      context: context, initialDate: _fecha,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100));
                  if (p != null) setState(() => _fecha = p);
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: _save, child: const Text('Guardar')),
            ],
          ),
        ),
      ),
    );
  }
}