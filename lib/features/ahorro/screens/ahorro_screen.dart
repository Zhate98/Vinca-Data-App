import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/finance_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/ahorro.dart';
import '../../../shared/providers/finance_providers.dart';
import '../../../shared/providers/shared_space_providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/kpi_card.dart';
import '../../auth/providers/auth_providers.dart';

class AhorroScreen extends ConsumerWidget {
  const AhorroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aportes  = ref.watch(ahorrosProvider);
    final moneda = ref.watch(currencyProvider);
    final cfg      = ref.watch(configProvider).valueOrNull;
    final personas = ref.watch(activeSpacePersonasProvider);
    final myName   = ref.watch(currentUserProvider)?.displayName ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref, null, personas, myName),
        icon: const Icon(Icons.add),
        label: const Text('Añadir aporte'),
      ),
      body: aportes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          final total   = list.fold<double>(0, (s, e) => s + e.monto);
          final objetivo = cfg?.objetivoAhorro ?? 10000;
          final pct     = objetivo > 0 ? (total / objetivo).clamp(0, 1) : 0.0;
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
                  KpiCard(label: '🏦 Total ahorrado', value: Fmt.money(total, moneda: moneda), accent: AppColors.blue),
                  KpiCard(label: '🎯 Objetivo', value: Fmt.money(objetivo, moneda: moneda), accent: AppColors.purple),
                  KpiCard(label: '📈 Progreso', value: '${(pct * 100).round()}%', accent: AppColors.teal),
                  KpiCard(label: '💰 Falta', value: Fmt.money((objetivo - total).clamp(0, double.infinity), moneda: moneda), accent: AppColors.yellow),
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
                      onTap: () => _openForm(context, ref, a, personas, myName),
                      title: Text(a.concepto,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          personas.isNotEmpty
                              ? '${Fmt.date(a.fecha)} · ${_resolvePersona(a.persona, myName)}'
                              : Fmt.date(a.fecha),
                          style: const TextStyle(fontSize: 11, color: AppColors.darkMuted)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('+${Fmt.money(a.monto, moneda: moneda)}',
                              style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700)),
                          IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.darkMuted),
                              onPressed: () => ref
                                  .read(activeFinanceRepositoryProvider)!
                                  .deleteAhorro(a.id)),
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

  String _resolvePersona(String persona, String myName) {
    if (myName.isNotEmpty && persona == myName) return 'Yo';
    return persona;
  }

  void _openForm(BuildContext context, WidgetRef ref, Ahorro? ahorro,
      List<String> personas, String myName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AporteForm(
        ahorro: ahorro,
        personas: personas,
        myDisplayName: myName,
        moneda: ref.read(currencyProvider),
        onSubmit: (a) => ahorro == null
            ? ref.read(activeFinanceRepositoryProvider)!.addAhorro(a)
            : ref.read(activeFinanceRepositoryProvider)!.updateAhorro(a),
      ),
    );
  }
}

class _AporteForm extends StatefulWidget {
  const _AporteForm(
      {required this.onSubmit,
      this.ahorro,
      required this.personas,
      required this.myDisplayName,
      required this.moneda});
  final Future<void> Function(Ahorro) onSubmit;
  final Ahorro? ahorro;
  final List<String> personas;
  final String myDisplayName;
  final String moneda;
  @override
  State<_AporteForm> createState() => _AporteFormState();
}

class _AporteFormState extends State<_AporteForm> {
  final _form    = GlobalKey<FormState>();
  late final _monto   = TextEditingController(
      text: widget.ahorro != null ? widget.ahorro!.monto.toStringAsFixed(2) : '');
  late final _concepto = TextEditingController(text: widget.ahorro?.concepto ?? 'Ahorro');
  late DateTime _fecha   = widget.ahorro?.fecha ?? DateTime.now();
  late String   _persona = _initPersona();

  String _initPersona() {
    if (widget.personas.isEmpty) return FinanceConstants.personasBase.first;
    final saved = widget.ahorro?.persona ?? '';
    if (saved.isEmpty) return 'Yo';
    if (widget.myDisplayName.isNotEmpty && saved == widget.myDisplayName) return 'Yo';
    if (widget.personas.contains(saved)) return saved;
    return 'Yo';
  }

  @override
  void dispose() { _monto.dispose(); _concepto.dispose(); super.dispose(); }

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
                decoration: InputDecoration(labelText: widget.moneda == 'USD' ? 'Importe (\$)' : 'Importe (€)'),
                validator: (v) =>
                    double.tryParse((v ?? '').replaceAll(',', '.')) == null
                        ? 'Número no válido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _concepto,
                decoration: const InputDecoration(labelText: 'Concepto'),
              ),
              if (widget.personas.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _persona,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Persona'),
                  items: widget.personas
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _persona = v ?? _persona),
                ),
              ],
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
                  final personaFinal = (widget.personas.isNotEmpty && _persona == 'Yo')
                      ? (widget.myDisplayName.isNotEmpty ? widget.myDisplayName : 'Yo')
                      : _persona;
                  await widget.onSubmit(Ahorro(
                    id: widget.ahorro?.id ?? '',
                    fecha: _fecha,
                    monto: double.parse(_monto.text.replaceAll(',', '.')),
                    persona: personaFinal,
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
