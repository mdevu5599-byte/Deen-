import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/foundation.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../notifications/data/push_service.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthRepository? _repo;
  AppUser? user;
  bool busy = false;
  String? error;
  String role = 'user';
  StreamSubscription<AppUser?>? _sub;

  AuthController() {
    if (Fb.ready) {
      _repo = FirebaseAuthRepository();
      user = _repo!.current;
      _sub = _repo!.changes.listen((u) async {
        user = u;
        role = u == null ? 'user' : await _repo!.role();
        if (u != null) PushService.sync(u.uid);
        notifyListeners();
      });
    }
  }

  bool get available => _repo != null;

  String _msg(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'ইমেইল ঠিকানাটি সঠিক নয়।';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'ইমেইল বা পাসওয়ার্ড সঠিক নয়।';
        case 'email-already-in-use':
          return 'এই ইমেইল দিয়ে আগেই অ্যাকাউন্ট খোলা হয়েছে।';
        case 'weak-password':
          return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।';
        case 'network-request-failed':
          return 'ইন্টারনেট সংযোগ পাওয়া যায়নি।';
        case 'too-many-requests':
          return 'অনেকবার চেষ্টা করা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন।';
      }
    }
    return 'কিছু ভুল হয়েছে। আবার চেষ্টা করুন।';
  }

  Future<bool> _run(Future<void> Function() f) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await f();
      return true;
    } catch (e) {
      error = _msg(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String e, String p) => _run(() => _repo!.signIn(e, p));
  Future<bool> register(String n, String e, String p, String type) =>
      _run(() => _repo!.register(n, e, p, accountType: type));
  Future<bool> google() => _run(() => _repo!.signInWithGoogle());
  Future<bool> reset(String e) => _run(() => _repo!.sendPasswordReset(e));
  Future<void> signOut() async {
    await _repo?.signOut();
    user = null;
    role = 'user';
    notifyListeners();
  }

  Future<bool> updateName(String n) => _run(() => _repo!.updateName(n));
  Future<bool> deleteAccount() async {
    final ok = await _run(() => _repo!.deleteAccount());
    if (ok) user = null;
    notifyListeners();
    return ok;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
