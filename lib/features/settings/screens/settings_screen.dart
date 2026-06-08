import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_config.dart';
import '../../../shared/providers/finance_providers.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/section_card.dart';
import '../../auth/providers/auth_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _saldo = TextEditingController();
  final _limite = TextEditingController();
  final _objetivo = TextEditingController();
  final _aporte = TextEditingController();
  bool _filled = false;

  @override
  void dispose() {
    _saldo.dispose();
    _limite.dispose();
    _objetivo.dispose();
    _aporte.dispose();
    super.dispose();
  }

  void _fill(UserConfig c) {
    if (_filled) return;
    _saldo.text = c.saldoInicial.toStringAsFixed(0);
    _limite.text = c.limiteGasto.toStringAsFixed(0);
    _objetivo.text = c.objetivoAhorro.toStringAsFixed(0);
    _aporte.text = c.aporteMensual.toStringAsFixed(0);
    _filled = true;
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  Future<void> _deleteAccount() async {
    // 1. Confirmación inicial
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
            '¿Estás seguro? Se eliminarán todos tus datos y no podrás recuperarlos.'),
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
    if (confirm != true || !mounted) return;

    final controller = ref.read(authControllerProvider.notifier);

    // 2. Re-autenticar (Firebase lo exige si la sesión es antigua)
    final isGoogle = controller.isGoogleUser;
    bool reauthed = false;

    if (isGoogle) {
      // Usuario de Google: re-login con popup de Google
      reauthed = await controller.reauthWithGoogle();
    } else {
      // Usuario de email: pedir contraseña
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
                decoration:
                    const InputDecoration(labelText: 'Contraseña actual'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.red),
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ) ==
          true;
      if (reauthed && mounted) {
        reauthed = await controller.reauthWithEmail(passCtrl.text);
      }
      passCtrl.dispose();
    }

    if (!reauthed || !mounted) return;

    // 3. Borrar cuenta y datos
    try {
      await controller.deleteAccount();
      if (context.mounted) context.go('/login');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar cuenta: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final cfgAsync = ref.watch(configProvider);
    final themeMode = ref.watch(themeModeProvider);

    return cfgAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (cfg) {
        _fill(cfg);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            // ── Perfil ────────────────────────────────────────────────────
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
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
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

            // ── Apariencia ────────────────────────────────────────────────
            SectionCard(
              title: 'Apariencia',
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tema oscuro'),
                value: themeMode == ThemeMode.dark,
                activeColor: AppColors.teal,
                onChanged: (v) => ref
                    .read(themeModeProvider.notifier)
                    .set(v ? ThemeMode.dark : ThemeMode.light),
              ),
            ),
            const SizedBox(height: 16),

            // ── Configuración financiera ──────────────────────────────────
            SectionCard(
              title: '⚙️ Configuración financiera',
              child: Column(
                children: [
                  _field('💰 Saldo inicial (€)', _saldo),
                  _field('⚠️ Límite gasto mensual (€)', _limite),
                  _field('🎯 Objetivo de ahorro (€)', _objetivo),
                  _field('💎 Aporte mensual ahorro (€)', _aporte),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      await ref.read(financeRepositoryProvider)!.saveConfig(
                            UserConfig(
                              saldoInicial: _num(_saldo),
                              limiteGasto: _num(_limite),
                              objetivoAhorro: _num(_objetivo),
                              aporteMensual: _num(_aporte),
                            ),
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Configuración guardada'),
                              backgroundColor: AppColors.green),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Sesión ────────────────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
            const SizedBox(height: 12),

            // ── Eliminar cuenta ───────────────────────────────────────────
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
      },
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
