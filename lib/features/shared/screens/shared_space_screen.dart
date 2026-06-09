import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/shared_space.dart';
import '../../../data/models/user_config.dart';
import '../../../data/repositories/finance_repository.dart';
import '../../../shared/providers/shared_space_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../home/home_shell.dart';

class SharedSpaceScreen extends ConsumerStatefulWidget {
  const SharedSpaceScreen({super.key});

  @override
  ConsumerState<SharedSpaceScreen> createState() => _SharedSpaceScreenState();
}

class _SharedSpaceScreenState extends ConsumerState<SharedSpaceScreen> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _createSpace() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(sharedRepositoryProvider);
      if (repo == null) return;
      final space = await repo.createSpace(name);
      if (!mounted) return;
      _nameCtrl.clear();
      // Mostrar diálogo de bienvenida al espacio compartido (con config inicial)
      _showSharedWelcomeDialog(space);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSharedWelcomeDialog(SharedSpace space) {
    final uid = ref.read(currentUserProvider)?.uid ?? '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: _SharedSetupDialogContent(
            space: space,
            uid: uid,
            onDone: () => _showCodeDialog(space),
          ),
        ),
      ),
    );
  }

  Future<void> _joinSpace() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(sharedRepositoryProvider);
      if (repo == null) return;
      await repo.joinByCode(code);
      if (!mounted) return;
      _codeCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Te has unido al espacio compartido!'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _leaveSpace(SharedSpace space) async {
    final isOwner = space.ownerId == (ref.read(currentUserProvider)?.uid ?? '');
    final hasOthers = space.memberNames.length > 1;

    String subtitle = '¿Salir de "${space.name}"? Perderás acceso a sus datos.';
    if (isOwner && hasOthers) {
      subtitle += '\n\nEres el dueño; el siguiente miembro tomará el control.';
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salir del espacio'),
        content: Text(subtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final repo = ref.read(sharedRepositoryProvider);
      await repo?.leaveSpace(space.id);

      // Si estaba activo este espacio, volver a personal
      if (ref.read(activeSpaceProvider) == space.id) {
        ref.read(activeSpaceProvider.notifier).state = null;
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _deleteSpace(SharedSpace space) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar espacio'),
        content: Text(
          '¿Eliminar "${space.name}" para todos los miembros?\n\n'
          'Se borrarán todos los datos del espacio. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final repo = ref.read(sharedRepositoryProvider);
      await repo?.deleteSpace(space.id);

      // Si estaba activo, volver a personal
      if (ref.read(activeSpaceProvider) == space.id) {
        ref.read(activeSpaceProvider.notifier).state = null;
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  void _showCodeDialog(SharedSpace space) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Espacio creado ✅'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Comparte este código con quien quieras:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.teal),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    space.code,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppColors.teal),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: space.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código copiado')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacesAsync = ref.watch(mySharedSpacesProvider);
    final activeSpaceId = ref.watch(activeSpaceProvider);
    final currentUid = ref.watch(currentUserProvider)?.uid ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // ── Mis espacios ─────────────────────────────────────────────────────
        spacesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (spaces) {
            if (spaces.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Aún no tienes espacios compartidos.',
                  style: TextStyle(color: AppColors.darkMuted),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mis espacios',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 10),
                for (final space in spaces)
                  _SpaceTile(
                    space: space,
                    isActive: space.id == activeSpaceId,
                    isOwner: space.ownerId == currentUid,
                    onActivate: () {
                      ref.read(activeSpaceProvider.notifier).state =
                          space.id == activeSpaceId ? null : space.id;
                      // Navegar al Dashboard del contexto seleccionado
                      ref.read(sectionProvider.notifier).state =
                          AppSection.dashboard;
                    },
                    onLeave: () => _leaveSpace(space),
                    onShowCode: () => _showCodeDialog(space),
                    onDelete: () => _deleteSpace(space),
                  ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),

        // ── Crear espacio ─────────────────────────────────────────────────────
        const Text(
          'Crear espacio compartido',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre del espacio (ej: Familia, Con mi pareja…)',
            prefixIcon: Icon(Icons.group_outlined),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _loading ? null : _createSpace,
          icon: const Icon(Icons.add),
          label: const Text('Crear y obtener código'),
        ),

        const SizedBox(height: 32),

        // ── Unirse con código ─────────────────────────────────────────────────
        const Text(
          'Unirse a un espacio',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _codeCtrl,
          decoration: const InputDecoration(
            labelText: 'Código (ej: ABC-123)',
            prefixIcon: Icon(Icons.vpn_key_outlined),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _loading ? null : _joinSpace,
          icon: const Icon(Icons.login),
          label: const Text('Unirse'),
        ),
      ],
    );
  }
}

class _SpaceTile extends StatelessWidget {
  const _SpaceTile({
    required this.space,
    required this.isActive,
    required this.isOwner,
    required this.onActivate,
    required this.onLeave,
    required this.onShowCode,
    required this.onDelete,
  });

  final SharedSpace space;
  final bool isActive;
  final bool isOwner;
  final VoidCallback onActivate;
  final VoidCallback onLeave;
  final VoidCallback onShowCode;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? const BorderSide(color: AppColors.teal, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: () {
          final nombres = space.memberNames.values.toList()..sort();
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('\u{1F465} ${space.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${space.memberNames.length} miembro${space.memberNames.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: AppColors.darkMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ...nombres.map((n) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.teal,
                          child: Icon(Icons.person, size: 16, color: AppColors.darkBg),
                        ),
                        const SizedBox(width: 10),
                        Text(n, style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: isActive
              ? AppColors.teal
              : AppColors.teal.withValues(alpha: 0.15),
          child: Icon(
            Icons.group,
            color: isActive ? AppColors.darkBg : AppColors.teal,
          ),
        ),
        title: Text(
          space.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${space.memberNames.length} miembro${space.memberNames.length == 1 ? '' : 's'} · Toca para ver miembros',
          style: const TextStyle(fontSize: 12, color: AppColors.darkMuted),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'activate') onActivate();
            if (v == 'code') onShowCode();
            if (v == 'leave') onLeave();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'activate',
              child: Text(isActive ? 'Volver a personal' : 'Ver este espacio'),
            ),
            const PopupMenuItem(
              value: 'code',
              child: Text('Ver código'),
            ),
            const PopupMenuItem(
              value: 'leave',
              child: Text('Salir del espacio',
                  style: TextStyle(color: AppColors.red)),
            ),
            if (isOwner)
              const PopupMenuItem(
                value: 'delete',
                child: Text('Eliminar espacio',
                    style: TextStyle(color: AppColors.red)),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Diálogo de configuración inicial del espacio compartido ───────────────────
class _SharedSetupDialogContent extends StatefulWidget {
  const _SharedSetupDialogContent({
    required this.space,
    required this.uid,
    required this.onDone,
  });
  final SharedSpace space;
  final String uid;
  final VoidCallback onDone;

  @override
  State<_SharedSetupDialogContent> createState() =>
      _SharedSetupDialogContentState();
}

class _SharedSetupDialogContentState
    extends State<_SharedSetupDialogContent> {
  final _saldo  = TextEditingController(text: '0');
  final _limite = TextEditingController(text: '2500');
  final _obj    = TextEditingController(text: '10000');
  final _aporte = TextEditingController(text: '300');
  String _moneda = 'EUR';
  bool _saving   = false;

  @override
  void dispose() {
    _saldo.dispose();
    _limite.dispose();
    _obj.dispose();
    _aporte.dispose();
    super.dispose();
  }

  double _n(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = FinanceRepository.shared(widget.space.id, uid: widget.uid);
      await repo.saveConfig(UserConfig(
        saldoInicial:   _n(_saldo),
        limiteGasto:    _n(_limite),
        objetivoAhorro: _n(_obj),
        aporteMensual:  _n(_aporte),
        moneda:         _moneda,
      ));
      if (mounted) {
        Navigator.pop(context);
        widget.onDone();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👥', style: TextStyle(fontSize: 38)),
          const SizedBox(height: 6),
          Text(
            '¡Bienvenido a ${widget.space.name}!',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.teal),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bienvenido a tu espacio compartido',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.darkMuted, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'Configura los valores iniciales del espacio.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.darkMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          // Selector de moneda
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Moneda: ', style: TextStyle(fontSize: 13)),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'EUR', label: Text('€ EUR')),
                  ButtonSegment(value: 'USD', label: Text('\$ USD')),
                ],
                selected: {_moneda},
                onSelectionChanged: (s) => setState(() => _moneda = s.first),
                style: const ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _field('💰 Saldo inicial compartido (${_moneda == "EUR" ? "€" : "\$"})', _saldo),
          _field('⚠️ Límite de gasto mensual (${_moneda == "EUR" ? "€" : "\$"})', _limite),
          _field('🎯 Objetivo de ahorro (${_moneda == "EUR" ? "€" : "\$"})', _obj),
          _field('💎 Aporte mensual de ahorro (${_moneda == "EUR" ? "€" : "\$"})', _aporte),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.darkBg))
                : const Text('Guardar y continuar'),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDone();
            },
            child: const Text(
              'Configurar después',
              style: TextStyle(color: AppColors.darkMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
        ),
      );
}
