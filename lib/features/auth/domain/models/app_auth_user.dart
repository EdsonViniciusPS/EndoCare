/// Representação desacoplada da usuária autenticada no EndoCare.
class AppAuthUser {
  const AppAuthUser({
    required this.uid,
    required this.email,
    required this.emailVerified,
    this.displayName,
  });

  final String uid;
  final String email;
  final bool emailVerified;
  final String? displayName;

  AppAuthUser copyWith({
    String? uid,
    String? email,
    bool? emailVerified,
    String? displayName,
  }) {
    return AppAuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      displayName: displayName ?? this.displayName,
    );
  }
}

