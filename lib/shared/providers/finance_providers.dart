import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ahorro.dart';
import '../../data/models/deuda.dart';
import '../../data/models/gasto.dart';
import '../../data/models/ingreso.dart';
import '../../data/models/suscripcion.dart';
import '../../data/models/user_config.dart';
import '../../data/repositories/finance_repository.dart';
import '../../features/auth/providers/auth_providers.dart';
import 'month_provider.dart';
import 'shared_space_providers.dart';
export 'shared_space_providers.dart' show activeFinanceRepositoryProvider;

// Repo personal (siempre apunta al usuario)
final financeRepositoryProvider = Provider<FinanceRepository?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return FinanceRepository(user.uid);
});

// Repo activo (personal o compartido según contexto)
FinanceRepository _repo(Ref ref) {
  final r = ref.watch(activeFinanceRepositoryProvider);
  if (r == null) throw StateError('Sin sesión activa');
  return r;
}

final gastosMesProvider = StreamProvider.autoDispose<List<Gasto>>((ref) {
  final m = ref.watch(selectedMonthProvider);
  return _repo(ref).gastosDelMes(m.month, m.year);
});

final ingresosMesProvider = StreamProvider.autoDispose<List<Ingreso>>((ref) {
  final m = ref.watch(selectedMonthProvider);
  return _repo(ref).ingresosDelMes(m.month, m.year);
});

final gastosTodosProvider =
    StreamProvider.autoDispose<List<Gasto>>((ref) => _repo(ref).gastosTodos());
final ingresosTodosProvider =
    StreamProvider.autoDispose<List<Ingreso>>((ref) => _repo(ref).ingresosTodos());

final ahorrosProvider =
    StreamProvider.autoDispose<List<Ahorro>>((ref) => _repo(ref).ahorros());
final deudasProvider =
    StreamProvider.autoDispose<List<Deuda>>((ref) => _repo(ref).deudas());
final suscripcionesProvider =
    StreamProvider.autoDispose<List<Suscripcion>>((ref) => _repo(ref).suscripciones());

// Sin autoDispose: el stream de Firestore se mantiene vivo entre pantallas,
// así el dashboard refleja cambios de config inmediatamente.
final configProvider =
    StreamProvider<UserConfig>((ref) => _repo(ref).config());

/// Moneda activa del contexto actual ('EUR' o 'USD').
final currencyProvider = Provider<String>((ref) {
  return ref.watch(configProvider).valueOrNull?.moneda ?? 'EUR';
});

/// true = ya configuró / false = primera vez, mostrar diálogo
final setupCompleteProvider = StreamProvider.autoDispose<bool>((ref) {
  final repo = ref.watch(financeRepositoryProvider);
  if (repo == null) return Stream.value(true);
  return repo.setupComplete();
});
