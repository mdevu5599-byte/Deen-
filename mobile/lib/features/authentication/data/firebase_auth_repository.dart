import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  static const autoVerified = '__DEEN_PHONE_AUTO_VERIFIED__';

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? _map(fb.User? u) => u == null ? null : AppUser(u.uid, u.email, u.displayName);

  @override
  Stream<AppUser?> get changes => _auth.authStateChanges().map(_map);

  @override
  AppUser? get current => _map(_auth.currentUser);

  @override
  Future<void> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      await _ensureProfile(
        user,
        name: user.displayName ?? '',
        accountType: 'personal',
      );
    }
  }

  @override
  Future<void> register(
    String name,
    String email,
    String password, {
    required String accountType,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase did not return a newly created user.');
    }
    await user.updateDisplayName(name.trim());
    await _ensureProfile(user, name: name.trim(), accountType: accountType);
  }

  @override
  Future<void> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return; // User cancelled the Google account picker.
    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user != null) {
      await _ensureProfile(
        user,
        name: user.displayName ?? '',
        accountType: 'personal',
      );
    }
  }

  @override
  Future<String> sendPhoneCode(String phoneNumber) async {
    final result = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        try {
          final signedIn = await _auth.signInWithCredential(credential);
          final user = signedIn.user;
          if (user != null) {
            await _ensureProfile(user, name: user.displayName ?? '', accountType: 'personal');
          }
          if (!result.isCompleted) result.complete(autoVerified);
        } catch (error, stack) {
          if (!result.isCompleted) result.completeError(error, stack);
        }
      },
      verificationFailed: (error) {
        if (!result.isCompleted) result.completeError(error);
      },
      codeSent: (verificationId, resendToken) {
        if (!result.isCompleted) result.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!result.isCompleted) result.complete(verificationId);
      },
    );

    return result.future.timeout(
      const Duration(seconds: 70),
      onTimeout: () => throw TimeoutException('SMS verification timed out.'),
    );
  }

  @override
  Future<void> verifyPhoneCode(String verificationId, String smsCode) async {
    final credential = fb.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user != null) {
      await _ensureProfile(user, name: user.displayName ?? '', accountType: 'personal');
    }
  }

  /// Creates users/{uid} on first sign-in. Admin roles are never client-assigned.
  Future<void> _ensureProfile(
    fb.User user, {
    required String name,
    required String accountType,
  }) async {
    final reference = _db.collection('users').doc(user.uid);
    final snapshot = await reference.get();
    if (snapshot.exists) {
      // Complete profiles created by older app versions without changing user/admin roles.
      final current = snapshot.data() ?? <String, dynamic>{};
      final patch = <String, dynamic>{};
      if (current['uid'] == null) patch['uid'] = user.uid;
      if (current['email'] == null && user.email != null) patch['email'] = user.email;
      if (current['phoneNumber'] == null && user.phoneNumber != null) {
        patch['phoneNumber'] = user.phoneNumber;
      }
      if ((current['displayName'] ?? '').toString().isEmpty && name.trim().isNotEmpty) {
        patch['displayName'] = name.trim();
      }
      if (!['personal', 'public'].contains(current['accountType'])) {
        patch['accountType'] = accountType == 'public' ? 'public' : 'personal';
      }
      if (current['language'] == null) patch['language'] = 'bn';
      if (patch.isNotEmpty) {
        patch['updatedAt'] = FieldValue.serverTimestamp();
        await reference.update(patch);
      }
      return;
    }

    await reference.set({
      'uid': user.uid,
      'email': user.email,
      'phoneNumber': user.phoneNumber,
      'displayName': name.trim(),
      'accountType': accountType == 'public' ? 'public' : 'personal',
      'language': 'bn',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  @override
  Future<void> updateName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name.trim());
    await _db.collection('users').doc(user.uid).update({
      'displayName': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteAccount() async {
    // The callable deletes private records and the Auth account server-side.
    await FirebaseFunctions.instance.httpsCallable('deleteMyAccount').call();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  @override
  Future<String> role() async {
    final token = await _auth.currentUser?.getIdTokenResult(true);
    return (token?.claims?['role'] as String?) ?? 'user';
  }
}
