/// Usuario de la app, creado automáticamente desde Firebase Auth
/// (Google o email/contraseña). Sustituye la tabla `users` de la web.
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
      };

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        email: m['email'] as String? ?? '',
        displayName: m['displayName'] as String? ?? 'Usuario',
        photoUrl: m['photoUrl'] as String?,
      );
}
