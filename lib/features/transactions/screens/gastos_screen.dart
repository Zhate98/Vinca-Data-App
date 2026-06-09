import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/finance_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/gasto.dart';
import '../../../shared/providers/finance_providers.dart';
import '../../../shared/providers/shared_space_providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/providers/auth_providers.dart';

class GastosScreen extends ConsumerStatefulWidget {
  const GastosScreen({super.key});
  @override
  ConsumerState<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends ConsumerState<GastosScreen> {
  String? _selectedCat;

  @override
  Widget build(BuildContext context) {
    final async    = ref.watch(gastosMesProvider);
    final moneda = ref.watch(currencyProvider);
    final personas = ref.watch(activeSpacePersonasProvider);
    final myName   = ref.watch(currentUserProvider)?.displayName ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref, null, personas, myName),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo gasto'),
      ),
      body: Column(
        children: [
          _FilterBar(
            items: FinanceConstants.categorias,
            selected: _selectedCat,
            onSelected: (v) => setState(() => _selectedCat = v),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (gastos) {
                final filtered = _selectedCat == null
                    ? gastos
                    : gastos.where((g) => g.categoria == _selectedCat).toList();
                if (filtered.isEmpty) {
                  return const EmptyState(
                      icon: '💸',
                      message: 'No hay gastos este mes.\n¡Añade el primero!');
                }
                final total = filtered.fold<double>(0, (s, e) => s + e.monto);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  children: [
                    Text('Total: ${Fmt.money(total, moneda: moneda)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: AppColors.red)),
                    const SizedBox(height: 10),
                    for (final g in filtered)
                      _GastoTile(
                    moneda: moneda,
                    gasto: g,
                        displayPersona: personas.isNotEmpty
                            ? Fmt.resolvePersona(g.persona, myName)
                            : null,
                        onEdit: () => _openForm(context, ref, g, personas, myName),
                        onDelete: () => ref
                            .read(activeFinanceRepositoryProvider)!
                            .deleteGasto(g.id),
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


  void _openForm(BuildContext context, WidgetRef ref, Gasto? gasto,
      List<String> personas, String myName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GastoForm(
        gasto: gasto,
        personas: personas,
        myDisplayName: myName,
        moneda: ref.read(currencyProvider),
        onSubmit: (g) => gasto == null
            ? ref.read(activeFinanceRepositoryProvider)!.addGasto(g)
            : ref.read(activeFinanceRepositoryProvider)!.updateGasto(g),
      ),
    );
  }
}

// ── Barra de filtro ───────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  const _FilterBar(
      {required this.items,
      required this.selected,
      required this.onSelected});
  final List<String> items;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: const Text('Todas'),
              selected: selected == null,
              selectedColor: AppColors.teal,
              onSelected: (_) => onSelected(null),
              labelStyle: TextStyle(
                  color: selected == null ? AppColors.darkBg : null,
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
                onSelected: (_) => onSelected(selected == item ? null : item),
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

class _GastoTile extends StatelessWidget {
  const _GastoTile(
      {required this.gasto,
      required this.onEdit,
      required this.onDelete,
      required this.moneda,
      this.displayPersona});
  final Gasto gasto;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String moneda;
  final String? displayPersona;

  @override
  Widget build(BuildContext context) {
    final sub = displayPersona != null
        ? '${gasto.categoria} · ${Fmt.date(gasto.fecha)} · $displayPersona'
        : '${gasto.categoria} · ${Fmt.date(gasto.fecha)}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onEdit,
        title: Text(gasto.descripcion,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sub,
            style: const TextStyle(fontSize: 11, color: AppColors.darkMuted)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('-${Fmt.money(gasto.monto, moneda: moneda)}',
                style: const TextStyle(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
            IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.darkMuted),
                onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

class _GastoForm extends StatefulWidget {
  const _GastoForm(
      {required this.onSubmit,
      this.gasto,
      required this.personas,
      required this.myDisplayName,
      required this.moneda});
  final Future<void> Function(Gasto) onSubmit;
  final Gasto? gasto;
  final List<String> personas;
  final String myDisplayName;
  final String moneda;
  @override
  State<_GastoForm> createState() => _GastoFormState();
}

class _GastoFormState extends State<_GastoForm> {
  final _form = GlobalKey<FormState>();
  late final _desc  = TextEditingController(text: widget.gasto?.descripcion ?? '');
  late final _monto = TextEditingController(
      text: widget.gasto != null ? widget.gasto!.monto.toStringAsFixed(2) : '');
  late DateTime _fecha  = widget.gasto?.fecha ?? DateTime.now();
  late String   _cat    = widget.gasto?.categoria ?? FinanceConstants.categorias.first;
  late String   _metodo = widget.gasto?.metodo    ?? FinanceConstants.metodos.first;
  late String   _tipo   = widget.gasto?.tipo      ?? FinanceConstants.tiposGasto.first;
  late String   _persona = _initPersona();

  String _initPersona() {
    if (widget.personas.isEmpty) return FinanceConstants.personasBase.first;
    final saved = widget.gasto?.persona ?? '';
    if (saved.isEmpty) return 'Yo';
    if (widget.myDisplayName.isNotEmpty && saved == widget.myDisplayName) return 'Yo';
    if (widget.personas.contains(saved)) return saved;
    return 'Yo';
  }

  @override
  void dispose() { _desc.dispose(); _monto.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final personaFinal = (widget.personas.isNotEmpty && _persona == 'Yo')
        ? (widget.myDisplayName.isNotEmpty ? widget.myDisplayName : 'Yo')
        : _persona;
    await widget.onSubmit(Gasto(
      id: widget.gasto?.id ?? '',
      fecha: _fecha,
      descripcion: _desc.text.trim(),
      categoria: _cat,
      metodo: _metodo,
      monto: double.parse(_monto.text.replaceAll(',', '.')),
      persona: personaFinal,
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
              Text(widget.gasto == null ? '➕ Nuevo gasto' : '✏️ Editar gasto',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _monto,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: widget.moneda == 'USD' ? 'Importe (\$)' : 'Importe (€)'),
                validator: (v) =>
                    double.tryParse((v ?? '').replaceAll(',', '.')) == null
                        ? 'Número no válido' : null,
              ),
              const SizedBox(height: 12),
              _DD(label: 'Categoría', value: _cat,
                  items: FinanceConstants.categorias,
                  onChanged: (v) => setState(() => _cat = v)),
              const SizedBox(height: 12),
              _DD(label: 'Método', value: _metodo,
                  items: FinanceConstants.metodos,
                  onChanged: (v) => setState(() => _metodo = v)),
              const SizedBox(height: 12),
              _DD(label: 'Tipo', value: _tipo,
                  items: FinanceConstants.tiposGasto,
                  onChanged: (v) => setState(() => _tipo = v)),
              if (widget.personas.isNotEmpty) ...[
                const SizedBox(height: 12),
                _DD(label: 'Persona', value: _persona,
                    items: widget.personas,
                    onChanged: (v) => setState(() => _persona = v)),
              ],
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha'),
                trailing: Text(Fmt.date(_fecha),
                    style: const TextStyle(color: AppColors.teal)),
                onTap: () async {
                  final p = await showDatePicker(
                      context: context, initialDate: _fecha,
                      firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (p != null) setState(() => _fecha = p);
                },
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _save, child: const Text('Guardar')),
            ],
          ),
        ),
      ),
    );
  }
}

class _DD extends StatelessWidget {
  const _DD({required this.label, required this.value,
      required this.items, required this.onChanged});
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => onChanged(v ?? value),
    );
  }
}
