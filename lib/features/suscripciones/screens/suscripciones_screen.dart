import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/finance_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/suscripcion.dart';
import '../../../shared/providers/finance_providers.dart';
import '../../../shared/providers/shared_space_providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/kpi_card.dart';
import '../../auth/providers/auth_providers.dart';

class SuscripcionesScreen extends ConsumerWidget {
  const SuscripcionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async    = ref.watch(suscripcionesProvider);
    final moneda = ref.watch(currencyProvider);
    final personas = ref.watch(activeSpacePersonasProvider);
    final myName   = ref.watch(currentUserProvider)?.displayName ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref, null, personas, myName),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          final mensual = list.fold<double>(0, (s, e) => s + e.precioMes);
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
                  KpiCard(label: '💶 Mensual', value: Fmt.money(mensual, moneda: moneda), accent: AppColors.pink),
                  KpiCard(label: '📅 Anual', value: Fmt.money(mensual * 12, moneda: moneda), accent: AppColors.purple),
                  KpiCard(label: '📱 Activas', value: '${list.length}', accent: AppColors.teal),
                ],
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                const EmptyState(icon: '📱', message: 'No tienes suscripciones activas.')
              else
                for (final s in list)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => _openForm(context, ref, s, personas, myName),
                      title: Text(s.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          personas.isNotEmpty
                              ? '${s.renovacion} · ${s.categoria} · ${Fmt.resolvePersona(s.persona, myName)}'
                              : '${s.renovacion} · ${s.categoria}',
                          style: const TextStyle(fontSize: 11, color: AppColors.darkMuted)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${Fmt.money(s.precioMes, moneda: moneda)}/mes',
                              style: const TextStyle(color: AppColors.pink, fontWeight: FontWeight.w700)),
                          IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.darkMuted),
                              onPressed: () => ref
                                  .read(activeFinanceRepositoryProvider)!
                                  .deleteSuscripcion(s.id)),
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


  void _openForm(BuildContext context, WidgetRef ref, Suscripcion? suscripcion,
      List<String> personas, String myName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SuscForm(
        suscripcion: suscripcion,
        personas: personas,
        myDisplayName: myName,
        moneda: ref.read(currencyProvider),
        onSubmit: (s) => suscripcion == null
            ? ref.read(activeFinanceRepositoryProvider)!.addSuscripcion(s)
            : ref.read(activeFinanceRepositoryProvider)!.updateSuscripcion(s),
      ),
    );
  }
}

class _SuscForm extends StatefulWidget {
  const _SuscForm(
      {required this.onSubmit,
      this.suscripcion,
      required this.personas,
      required this.myDisplayName,
      required this.moneda});
  final Future<void> Function(Suscripcion) onSubmit;
  final Suscripcion? suscripcion;
  final List<String> personas;
  final String myDisplayName;
  final String moneda;
  @override
  State<_SuscForm> createState() => _SuscFormState();
}

class _SuscFormState extends State<_SuscForm> {
  final _form    = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.suscripcion?.nombre ?? '');
  late final _precio = TextEditingController(
      text: widget.suscripcion != null ? widget.suscripcion!.precioMes.toStringAsFixed(2) : '');
  late String _categoria  = widget.suscripcion?.categoria  ?? FinanceConstants.categorias.first;
  late String _renovacion = widget.suscripcion?.renovacion ?? FinanceConstants.renovaciones.first;
  late String _persona    = _initPersona();

  String _initPersona() {
    if (widget.personas.isEmpty) return FinanceConstants.personasBase.first;
    final saved = widget.suscripcion?.persona ?? '';
    if (saved.isEmpty) return 'Yo';
    if (widget.myDisplayName.isNotEmpty && saved == widget.myDisplayName) return 'Yo';
    if (widget.personas.contains(saved)) return saved;
    return 'Yo';
  }

  @override
  void dispose() { _nombre.dispose(); _precio.dispose(); super.dispose(); }

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
              Text(widget.suscripcion == null ? '➕ Nueva suscripción' : '✏️ Editar suscripción',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombre,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _precio,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: widget.moneda == 'USD' ? 'Precio/mes (\$)' : 'Precio/mes (€)'),
                validator: (v) =>
                    double.tryParse((v ?? '').replaceAll(',', '.')) == null
                        ? 'Número no válido' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _categoria,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: FinanceConstants.categorias
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v ?? _categoria),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _renovacion,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Renovación'),
                items: FinanceConstants.renovaciones
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _renovacion = v ?? _renovacion),
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
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  final personaFinal = (widget.personas.isNotEmpty && _persona == 'Yo')
                      ? (widget.myDisplayName.isNotEmpty ? widget.myDisplayName : 'Yo')
                      : _persona;
                  await widget.onSubmit(Suscripcion(
                    id: widget.suscripcion?.id ?? '',
                    nombre: _nombre.text.trim(),
                    precioMes: double.parse(_precio.text.replaceAll(',', '.')),
                    categoria: _categoria,
                    renovacion: _renovacion,
                    persona: personaFinal,
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
