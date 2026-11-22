class AppUser {
  final String uid;
  final String? email;
  final String? name;
  const AppUser(this.uid, this.email, this.name);
}

abstract class AuthRepository {
  Stream<AppUser?> get changes;
  AppUser? get current;
  Future<void> signIn(String email, String password);
  Future<void> register(String name, String email, String password, {required String accountType});
  Future<void> signInWithGoogle();
  Future<String> sendPhoneCode(String phoneNumber);
  Future<void> verifyPhoneCode(String verificationId, String smsCode);
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
  Future<void> updateName(String name);
  Future<void> deleteAccount();
  /// Server-assigned role from custom claims: user | admin | super_admin.
  Future<String> role();
}
