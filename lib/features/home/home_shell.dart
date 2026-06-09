import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_config.dart';
import '../../shared/providers/finance_providers.dart';
import '../../shared/providers/shared_space_providers.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/widgets/month_selector.dart';
import '../auth/providers/auth_providers.dart';
import '../ahorro/screens/ahorro_screen.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../deudas/screens/deudas_screen.dart';
import '../resumen/screens/resumen_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../shared/screens/shared_space_screen.dart';
import '../suscripciones/screens/suscripciones_screen.dart';
import '../transactions/screens/gastos_screen.dart';
import '../transactions/screens/ingresos_screen.dart';

enum AppSection {
  dashboard('🏠 Dashboard', Icons.home_outlined, Icons.home),
  gastos('💸 Gastos', Icons.south_west, Icons.south_west),
  ingresos('📋 Ingresos', Icons.north_east, Icons.north_east),
  ahorro('💎 Ahorro', Icons.savings_outlined, Icons.savings),
  deudas('💳 Deudas', Icons.credit_card_outlined, Icons.credit_card),
  suscripciones('📱 Suscripciones', Icons.subscriptions_outlined, Icons.subscriptions),
  resumen('📊 Resumen', Icons.bar_chart_outlined, Icons.bar_chart),
  compartido('👥 Compartido', Icons.group_outlined, Icons.group),
  config('⚙️ Configuración', Icons.settings_outlined, Icons.settings);

  const AppSection(this.title, this.icon, this.activeIcon);
  final String title;
  final IconData icon;
  final IconData activeIcon;
}

final sectionProvider =
    StateProvider<AppSection>((ref) => AppSection.dashboard);
final _scaffoldKey = GlobalKey<ScaffoldState>();

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  // ── Timeout de sesión ─────────────────────────────────────────────────────
  static const _timeout = Duration(minutes: 2);
  DateTime? _pausedAt;

  // ── Diálogo primera vez ───────────────────────────────────────────────────
  bool _setupDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Siempre abre en Dashboard al entrar/re-entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(sectionProvider.notifier).state = AppSection.dashboard;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Ciclo de vida de la app ───────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _pausedAt != null) {
      final elapsed = DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      if (elapsed >= _timeout) _sessionExpired();
    }
  }

  Future<void> _sessionExpired() async {
    if (!mounted) return;
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) context.go('/login');
  }

  // ── Diálogo de configuración inicial ─────────────────────────────────────
  void _showSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: _SetupDialogContent(ref: ref),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  bool _showsMonthNav(AppSection s) =>
      s == AppSection.dashboard ||
      s == AppSection.gastos ||
      s == AppSection.ingresos;

  Widget _body(AppSection s) {
    switch (s) {
      case AppSection.dashboard:     return const DashboardScreen();
      case AppSection.gastos:        return const GastosScreen();
      case AppSection.ingresos:      return const IngresosScreen();
      case AppSection.ahorro:        return const AhorroScreen();
      case AppSection.deudas:        return const DeudasScreen();
      case AppSection.suscripciones: return const SuscripcionesScreen();
      case AppSection.resumen:       return const ResumenScreen();
      case AppSection.compartido:    return const SharedSpaceScreen();
      case AppSection.config:        return const SettingsScreen();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final section       = ref.watch(sectionProvider);
    final user          = ref.watch(currentUserProvider);
    final themeMode     = ref.watch(themeModeProvider);
    final contextName   = ref.watch(activeContextNameProvider);
    final isShared      = ref.watch(activeSpaceProvider) != null;

    ref.listen(setupCompleteProvider, (_, next) {
      if (!_setupDialogShown && next.valueOrNull == false) {
        _setupDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showSetupDialog();
        });
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.title),
            if (section != AppSection.compartido && section != AppSection.config)
              Text(
                isShared ? '👥 $contextName' : '👤 Personal',
                style: TextStyle(
                  fontSize: 11,
                  color: isShared ? AppColors.teal : AppColors.darkMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          if (_showsMonthNav(section)) const MonthSelector(),
          IconButton(
            tooltip: 'Cambiar tema',
            icon: Icon(themeMode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            onPressed: () =>
                ref.read(themeModeProvider.notifier).toggle(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: _SideMenu(user: user),
      body: SafeArea(child: _body(section)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _barIndex(section),
        onDestinationSelected: _onBarTap,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio'),
          NavigationDestination(
              icon: Icon(Icons.north_east), label: 'Ingresos'),
          NavigationDestination(
              icon: Icon(Icons.south_west), label: 'Gastos'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Resumen'),
          NavigationDestination(
              icon: Icon(Icons.menu), label: 'Más'),
        ],
      ),
    );
  }

  int _barIndex(AppSection s) {
    switch (s) {
      case AppSection.dashboard: return 0;
      case AppSection.ingresos:  return 1;
      case AppSection.gastos:    return 2;
      case AppSection.resumen:   return 3;
      default:                   return 4;
    }
  }

  void _onBarTap(int i) {
    switch (i) {
      case 0:
        ref.read(sectionProvider.notifier).state = AppSection.dashboard;
      case 1:
        ref.read(sectionProvider.notifier).state = AppSection.ingresos;
      case 2:
        ref.read(sectionProvider.notifier).state = AppSection.gastos;
      case 3:
        ref.read(sectionProvider.notifier).state = AppSection.resumen;
      case 4:
        _scaffoldKey.currentState?.openDrawer();
    }
  }
}

// ── Diálogo de configuración inicial ─────────────────────────────────────────
class _SetupDialogContent extends StatefulWidget {
  const _SetupDialogContent({required this.ref});
  final WidgetRef ref;
  @override
  State<_SetupDialogContent> createState() => _SetupDialogContentState();
}

class _SetupDialogContentState extends State<_SetupDialogContent> {
  late final _nombre = TextEditingController(
      text: widget.ref.read(currentUserProvider)?.displayName ?? '');
  final _saldo  = TextEditingController(text: '0');
  final _limite = TextEditingController(text: '2500');
  final _obj    = TextEditingController(text: '10000');
  final _aporte = TextEditingController(text: '300');
  String _moneda = 'EUR';
  bool _saving   = false;

  @override
  void dispose() {
    _nombre.dispose();
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
      // 1. Marcar setup completo PRIMERO para que si userChanges() dispara
      //    durante updateName, el stream ya lea true y no reabra el diálogo.
      await widget.ref.read(financeRepositoryProvider)!.completeSetup(
        UserConfig(
          saldoInicial:   _n(_saldo),
          limiteGasto:    _n(_limite),
          objetivoAhorro: _n(_obj),
          aporteMensual:  _n(_aporte),
          moneda:         _moneda,
        ),
      );
      // 2. Nombre después (puede disparar userChanges → recreación de providers)
      final name = _nombre.text.trim();
      if (name.isNotEmpty) {
        await widget.ref.read(authControllerProvider.notifier).updateName(name);
      }
      if (mounted) Navigator.pop(context);
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
          const Text('🌿', style: TextStyle(fontSize: 38)),
          const SizedBox(height: 6),
          const Text(
            '¡Bienvenido a Vinca Data!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.teal),
          ),
          const SizedBox(height: 6),
          const Text(
            'Configura tus datos iniciales\npara empezar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.darkMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _field('👤 Tu nombre', _nombre, isText: true),
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
          _field('💰 Saldo actual (${_moneda == "EUR" ? "€" : "\$"})', _saldo),
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
                : const Text('Guardar y empezar'),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Completar después',
              style: TextStyle(color: AppColors.darkMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {bool isText = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          keyboardType: isText
              ? TextInputType.name
              : const TextInputType.numberWithOptions(decimal: true),
          textCapitalization: isText ? TextCapitalization.words : TextCapitalization.none,
          decoration: InputDecoration(labelText: label),
        ),
      );
}

// ── Menú lateral ──────────────────────────────────────────────────────────────
class _SideMenu extends ConsumerWidget {
  const _SideMenu({this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current     = ref.watch(sectionProvider);
    final contextName = ref.watch(activeContextNameProvider);
    final isShared    = ref.watch(activeSpaceProvider) != null;

    // Secciones del menú lateral (excluye config que va aparte)
    final mainSections = AppSection.values
        .where((e) => e != AppSection.config)
        .toList();

    // Forzar tema oscuro dentro del drawer independientemente del tema de la app
    return Theme(
      data: AppTheme.dark,
      child: NavigationDrawer(
      backgroundColor: AppColors.darkSidebar,
      selectedIndex: AppSection.values.indexOf(current),
      onDestinationSelected: (i) {
        ref.read(sectionProvider.notifier).state = AppSection.values[i];
        Navigator.pop(context);
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🌿 Vinca Data',
                style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 19,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '👤 ${user?.displayName ?? ''}',
                style: const TextStyle(
                    color: AppColors.darkMuted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isShared
                      ? AppColors.teal.withOpacity(0.15)
                      : AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isShared ? '👥 $contextName' : '👤 Personal',
                  style: TextStyle(
                    color: isShared ? AppColors.teal : AppColors.darkMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        for (final s in mainSections)
          NavigationDrawerDestination(
              icon: Icon(s.icon),
              selectedIcon: Icon(s.activeIcon),
              label: Text(s.title.replaceAll(RegExp(r'^\S+\s'), ''))),
        const Divider(),
        NavigationDrawerDestination(
          icon: Icon(AppSection.config.icon),
          selectedIcon: Icon(AppSection.config.activeIcon),
          label: const Text('Configuración'),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: () async {
              await ref
                  .read(authControllerProvider.notifier)
                  .signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Cerrar sesión'),
          ),
        ),
      ],
    )); // Theme + NavigationDrawer
  }
}
