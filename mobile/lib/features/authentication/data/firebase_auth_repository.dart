import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? _map(fb.User? u) => u == null ? null : AppUser(u.uid, u.email, u.displayName);

  @override
  Stream<AppUser?> get changes => _auth.authStateChanges().map(_map);

  @override
  AppUser? get current => _map(_auth.currentUser);

  @override
  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  @override
  Future<void> register(String name, String email, String password, {required String accountType}) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    await cred.user!.updateDisplayName(name.trim());
    await _ensureProfile(cred.user!, name: name.trim(), accountType: accountType);
  }

  @override
  Future<void> signInWithGoogle() async {
    final g = await GoogleSignIn().signIn();
    if (g == null) return; // cancelled
    final a = await g.authentication;
    final cred = fb.GoogleAuthProvider.credential(accessToken: a.accessToken, idToken: a.idToken);
    final res = await _auth.signInWithCredential(cred);
    await _ensureProfile(res.user!, name: res.user!.displayName ?? '', accountType: 'personal');
  }

  /// Creates users/{uid} on first sign-in. Security rules only allow the roles
  /// "personal" / "public" from the client; admin roles are custom claims set server-side.
  Future<void> _ensureProfile(fb.User u, {required String name, required String accountType}) async {
    final ref = _db.collection('users').doc(u.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'uid': u.uid,
      'email': u.email,
      'displayName': name,
      'accountType': accountType == 'public' ? 'public' : 'personal',
      'language': 'bn',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  @override
  Future<void> updateName(String name) async {
    final u = _auth.currentUser;
    if (u == null) return;
    await u.updateDisplayName(name.trim());
    await _db.collection('users').doc(u.uid).update({
      'displayName': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteAccount() async {
    // Server-side deletion removes all user-owned documents and the auth record.
    await FirebaseFunctions.instance.httpsCallable('deleteMyAccount').call();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  @override
  Future<String> role() async {
    final t = await _auth.currentUser?.getIdTokenResult(true);
    return (t?.claims?['role'] as String?) ?? 'user';
  }
}
