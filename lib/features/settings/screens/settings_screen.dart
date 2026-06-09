import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_config.dart';
import '../../../data/repositories/finance_repository.dart';
import '../../../shared/providers/finance_providers.dart';
import '../../../shared/providers/shared_space_providers.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/section_card.dart';
import '../../auth/providers/auth_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nombre   = TextEditingController();
  final _saldo    = TextEditingController();
  final _limite   = TextEditingController();
  final _objetivo = TextEditingController();
  final _aporte   = TextEditingController();
  String _moneda  = 'EUR';

  bool _configFilled = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final name = ref.read(currentUserProvider)?.displayName ?? '';
      if (_nombre.text.isEmpty && name.isNotEmpty) _nombre.text = name;
      // Pre-cargar config si ya está disponible (ref.listen no dispara
      // en la primera carga si el provider ya tenía valor al abrir la pantalla)
      final config = ref.read(configProvider).valueOrNull;
      if (config != null) _fillConfig(config);
    });
  }

  @override
  void dispose() {
    _nombre.dispose();
    _saldo.dispose();
    _limite.dispose();
    _objetivo.dispose();
    _aporte.dispose();
    super.dispose();
  }

  void _fillConfig(UserConfig c) {
    if (_configFilled) return;
    _configFilled = true;
    _saldo.text    = c.saldoInicial.toStringAsFixed(0);
    _limite.text   = c.limiteGasto.toStringAsFixed(0);
    _objetivo.text = c.objetivoAhorro.toStringAsFixed(0);
    _aporte.text   = c.aporteMensual.toStringAsFixed(0);
    setState(() => _moneda = c.moneda);
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
            '¿Estás seguro? Se eliminarán todos tus datos y no podrás recuperarlos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final controller = ref.read(authControllerProvider.notifier);
    bool reauthed = false;

    if (controller.isGoogleUser) {
      reauthed = await controller.reauthWithGoogle();
    } else {
      final passCtrl = TextEditingController();
      if (!mounted) return;
      reauthed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Confirma tu contraseña'),
              content: TextField(
                controller: passCtrl,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Contraseña actual'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.red),
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ) == true;
      if (reauthed && mounted) reauthed = await controller.reauthWithEmail(passCtrl.text);
      passCtrl.dispose();
    }

    if (!reauthed || !mounted) return;
    try {
      await controller.deleteAccount();
      if (context.mounted) context.go('/login');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user      = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Rellenar config una sola vez cuando el stream emita
    ref.listen<AsyncValue<UserConfig>>(configProvider, (_, next) {
      if (!_configFilled && next.hasValue) _fillConfig(next.value!);
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [

        // ── Nombre ─────────────────────────────────────────────────────────
        SectionCard(
          title: '👤 Mi nombre',
          child: TextField(
            controller: _nombre,
            decoration: const InputDecoration(
              labelText: 'Nombre visible',
              hintText: 'Ej: Victor',
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ),
        const SizedBox(height: 16),

        // ── Perfil ──────────────────────────────────────────────────────────
        SectionCard(
          title: 'Perfil',
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.teal,
                backgroundImage: (user?.photoUrl != null)
                    ? NetworkImage(user!.photoUrl!)
                    : null,
                child: user?.photoUrl == null
                    ? Text(
                        (user?.displayName.isNotEmpty ?? false)
                            ? user!.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: AppColors.darkBg,
                            fontWeight: FontWeight.w700,
                            fontSize: 20))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.displayName ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(user?.email ?? '',
                        style: const TextStyle(
                            color: AppColors.darkMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Apariencia ──────────────────────────────────────────────────────
        SectionCard(
          title: 'Apariencia',
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tema oscuro'),
            value: themeMode == ThemeMode.dark,
            activeColor: AppColors.teal,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).set(v ? ThemeMode.dark : ThemeMode.light),
          ),
        ),
        const SizedBox(height: 16),

        // ── Configuración financiera ────────────────────────────────────────
        SectionCard(
          title: '⚙️ Configuración financiera',
          child: Column(
            children: [
              // Selector de moneda
              Row(
                children: [
                  const Text('Moneda', style: TextStyle(fontSize: 13, color: AppColors.darkMuted)),
                  const SizedBox(width: 16),
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
              _field('💰 Saldo inicial (${_moneda == "EUR" ? "€" : "\$"})',         _saldo),
              _field('⚠️ Límite gasto mensual (${_moneda == "EUR" ? "€" : "\$"})', _limite),
              _field('🎯 Objetivo de ahorro (${_moneda == "EUR" ? "€" : "\$"})',   _objetivo),
              _field('💎 Aporte mensual ahorro (${_moneda == "EUR" ? "€" : "\$"})', _aporte),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : () async {
                  setState(() => _saving = true);
                  try {
                    // 0. Capturar todo ANTES de cualquier cambio que recree providers
                    final oldName   = ref.read(currentUserProvider)?.displayName ?? '';
                    final uid       = ref.read(currentUserProvider)?.uid ?? '';
                    final newName   = _nombre.text.trim();
                    final sharedRepo = ref.read(sharedRepositoryProvider);
                    final spaces    = ref.read(mySharedSpacesProvider).valueOrNull ?? [];

                    // 1. Config primero
                    final repo = ref.read(activeFinanceRepositoryProvider);
                    if (repo != null) {
                      await repo.saveConfig(UserConfig(
                        saldoInicial:   _num(_saldo),
                        limiteGasto:    _num(_limite),
                        objetivoAhorro: _num(_objetivo),
                        aporteMensual:  _num(_aporte),
                        moneda:         _moneda,
                      ));
                    }
                    // 2. Forzar refresh del provider para que el dashboard recoja el nuevo valor
                    ref.invalidate(configProvider);

                    // 3. Nombre después (puede disparar userChanges → recreación de providers)
                    if (newName.isNotEmpty) {
                      await ref.read(authControllerProvider.notifier).updateName(newName);
                    }

                    // 4. Sincronizar nombre en espacios compartidos.
                    if (newName.isNotEmpty && uid.isNotEmpty) {
                      for (final space in spaces) {
                        final repo = FinanceRepository.shared(space.id, uid: uid);
                        final storedName = space.memberNames[uid] ?? '';

                        if (storedName != newName) {
                          // Camino normal: renombrar desde el nombre guardado en memberNames
                          await repo.renamePersona(storedName, newName);
                        } else {
                          // memberNames ya está actualizado pero las transacciones pueden
                          // tener un nombre antiguo (estado roto de sesión anterior).
                          // Buscar nombres huérfanos y renombrarlos.
                          final currentNames = space.memberNames.values.toList();
                          final orphaned = await repo.findOrphanedPersonas(currentNames);
                          for (final old in orphaned) {
                            await repo.renamePersona(old, newName);
                          }
                        }
                      }

                      // Actualizar memberNames en todos los espacios
                      await sharedRepo?.updateMemberName(newName);
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Guardado'),
                          backgroundColor: AppColors.green,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
                icon: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkBg))
                    : const Icon(Icons.save_outlined),
                label: const Text('Guardar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Sesión ──────────────────────────────────────────────────────────
        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(authControllerProvider.notifier).signOut();
            if (context.mounted) context.go('/login');
          },
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
        const SizedBox(height: 12),

        // ── Eliminar cuenta ─────────────────────────────────────────────────
        OutlinedButton.icon(
          onPressed: _deleteAccount,
          icon: const Icon(Icons.delete_forever, color: AppColors.red),
          label: const Text('Eliminar cuenta',
              style: TextStyle(color: AppColors.red)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.red),
          ),
        ),
      ],
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
