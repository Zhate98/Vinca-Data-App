import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/shared_space.dart';
import '../../data/repositories/finance_repository.dart';
import '../../data/repositories/shared_repository.dart';
import '../../features/auth/providers/auth_providers.dart';

// ── Repositorio compartido ────────────────────────────────────────────────────
final sharedRepositoryProvider = Provider<SharedRepository?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return SharedRepository(user.uid, user.displayName.isNotEmpty ? user.displayName : 'Usuario');
});

// ── Espacios del usuario ──────────────────────────────────────────────────────
final mySharedSpacesProvider = StreamProvider<List<SharedSpace>>((ref) {
  final repo = ref.watch(sharedRepositoryProvider);
  if (repo == null) return Stream.value([]);
  return repo.mySpaces();
});

// ── Contexto activo: null = personal, String = spaceId ───────────────────────
final activeSpaceProvider = StateProvider<String?>((ref) => null);

// ── FinanceRepository según contexto activo ───────────────────────────────────
final activeFinanceRepositoryProvider = Provider<FinanceRepository?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final spaceId = ref.watch(activeSpaceProvider);
  if (spaceId == null) {
    return FinanceRepository(user.uid);
  } else {
    return FinanceRepository.shared(spaceId, uid: user.uid);
  }
});

// ── Nombre del contexto activo ────────────────────────────────────────────────
final activeContextNameProvider = Provider<String>((ref) {
  final spaceId = ref.watch(activeSpaceProvider);
  if (spaceId == null) return 'Personal';

  final spaces = ref.watch(mySharedSpacesProvider).valueOrNull ?? [];
  final space = spaces.where((s) => s.id == spaceId).firstOrNull;
  return space?.name ?? 'Compartido';
});

// ── Lista de personas para el contexto activo ─────────────────────────────────
// [] = contexto personal (ocultar campo Persona en los forms)
// ["Yo", "Nombre2", ...] = contexto compartido
final activeSpacePersonasProvider = Provider<List<String>>((ref) {
  final spaceId = ref.watch(activeSpaceProvider);
  if (spaceId == null) return []; // Personal: sin campo persona

  final user = ref.watch(currentUserProvider);
  final spaces = ref.watch(mySharedSpacesProvider).valueOrNull ?? [];
  final space = spaces.where((s) => s.id == spaceId).firstOrNull;
  if (space == null) return ['Yo'];

  // "Yo" + nombres de los otros miembros
  final otherNames = space.memberNames.entries
      .where((e) => e.key != user?.uid)
      .map((e) => e.value)
      .toList()
    ..sort();
  return ['Yo', ...otherNames];
});
