import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_user.dart';
import '../../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authState();
});

final currentUserProvider = Provider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  return repo.mapUser(user);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repo) : super(const AsyncData(null));
  final AuthRepository _repo;

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(_friendly(e), st);
      return false;
    }
  }

  Future<bool> google() => _run(_repo.signInWithGoogle);
  Future<bool> login(String email, String pass) =>
      _run(() => _repo.signInWithEmail(email, pass));
  Future<bool> register(String email, String pass, String name) =>
      _run(() => _repo.registerWithEmail(email, pass, name));
  Future<bool> reset(String email) =>
      _run(() => _repo.sendPasswordReset(email));
  Future<void> signOut() => _repo.signOut();
  Future<void> deleteAccount() => _run(_repo.deleteAccount);

  String _friendly(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'El correo no es válido.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Correo o contraseña incorrectos.';
        case 'email-already-in-use':
          return 'Ya existe una cuenta con ese correo.';
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 caracteres.';
        case 'network-request-failed':
          return 'Sin conexión. Revisa tu internet.';
        default:
          return e.message ?? 'Error de autenticación.';
      }
    }
    return e.toString().replaceFirst('Exception: ', '');
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});