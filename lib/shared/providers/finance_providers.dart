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

final financeRepositoryProvider = Provider<FinanceRepository?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return FinanceRepository(user.uid);
});

FinanceRepository _repo(Ref ref) {
  final r = ref.watch(financeRepositoryProvider);
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

final configProvider =
    StreamProvider.autoDispose<UserConfig>((ref) => _repo(ref).config());

/// true = ya configuró / false = primera vez, mostrar diálogo
final setupCompleteProvider = StreamProvider.autoDispose<bool>((ref) {
  final repo = ref.watch(financeRepositoryProvider);
  if (repo == null) return Stream.value(true);
  return repo.setupComplete();
});