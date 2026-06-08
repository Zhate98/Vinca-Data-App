import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/finance_constants.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db   = firestore ?? FirebaseFirestore.instance,
        _google = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _google;

  Stream<User?> authState() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  AppUser? mapUser(User? u) {
    if (u == null) return null;
    return AppUser(
      uid: u.uid,
      email: u.email ?? '',
      displayName: u.displayName ?? (u.email?.split('@').first ?? 'Usuario'),
      photoUrl: u.photoURL,
    );
  }

  Future<void> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) throw const _AuthCancelled();
    final gAuth = await account.authentication;
    final cred = await _auth.signInWithCredential(
      GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      ),
    );
    await _ensureUserDoc(cred.user!);
  }

  Future<void> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);

  Future<void> registerWithEmail(
      String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    await cred.user?.updateDisplayName(displayName.trim());
    await _ensureUserDoc(cred.user!, nameOverride: displayName.trim());
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _deleteUserData(user.uid);
    await user.delete();
    await _google.signOut();
  }

  /// Re-autentica con email+contraseña antes de deleteAccount()
  /// cuando Firebase lanza requires-recent-login.
  Future<void> reauthenticateWithEmail(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw const _AuthCancelled();
    final cred = EmailAuthProvider.credential(
        email: user.email!, password: password);
    await user.reauthenticateWithCredential(cred);
  }

  /// Re-autentica con Google para usuarios que iniciaron sesión con Google.
  Future<void> reauthenticateWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) throw const _AuthCancelled();
    final account = await _google.signIn();
    if (account == null) throw const _AuthCancelled();
    final gAuth = await account.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );
    await user.reauthenticateWithCredential(cred);
  }

  /// true si el usuario inició sesión con Google.
  bool get isGoogleUser =>
      _auth.currentUser?.providerData
          .any((p) => p.providerId == 'google.com') ??
      false;

  Future<void> _deleteUserData(String uid) async {
    final userRef = _db.collection('users').doc(uid);
    for (final col in
        ['gastos','ingresos','ahorro','deudas','suscripciones','config']) {
      final snap = await userRef.collection(col).get();
      for (final doc in snap.docs) await doc.reference.delete();
    }
    await userRef.delete();
  }

  Future<void> _ensureUserDoc(User user, {String? nameOverride}) async {
    final ref  = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;

    final appUser = AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: nameOverride ??
          user.displayName ??
          (user.email?.split('@').first ?? 'Usuario'),
      photoUrl: user.photoURL,
    );
    await ref.set({
      ...appUser.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'setupComplete': false,          // ← marca primera vez
    });
    await ref.collection('config').doc('finance')
        .set(FinanceConstants.configDefaults);
  }
}

class _AuthCancelled implements Exception {
  const _AuthCancelled();
  @override
  String toString() => 'Inicio de sesión cancelado';
}