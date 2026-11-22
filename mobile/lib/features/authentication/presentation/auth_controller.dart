import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/foundation.dart';

import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../notifications/data/push_service.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthRepository? _repo;
  AppUser? user;
  bool busy = false;
  String? error;
  String role = 'user';
  String? phoneVerificationId;
  bool phoneCodeSent = false;
  StreamSubscription<AppUser?>? _sub;
  final SettingsController? settings;

  AuthController({this.settings}) {
    if (Fb.ready) {
      _repo = FirebaseAuthRepository();
      user = _repo!.current;
      _sub = _repo!.changes.listen((currentUser) async {
        user = currentUser;
        try {
          role = currentUser == null ? 'user' : await _repo!.role();
        } catch (_) {
          role = 'user';
        }
        if (currentUser != null) {
          unawaited(_syncSignedInUser(currentUser.uid));
        }
        notifyListeners();
      });
    }
  }

  Future<void> _syncSignedInUser(String uid) async {
    await CloudSyncService().syncUser(uid);
    settings?.reloadFromPrefs();
    await PushService.sync(uid);
  }

  bool get available => _repo != null;

  String _msg(Object exception) {
    if (exception is FirebaseAuthException) {
      switch (exception.code) {
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
        case 'invalid-phone-number':
          return 'ফোন নম্বরটি আন্তর্জাতিক ফরম্যাটে লিখুন, যেমন +8801XXXXXXXXX।';
        case 'invalid-verification-code':
          return 'SMS কোডটি সঠিক নয়।';
        case 'session-expired':
          return 'কোডের মেয়াদ শেষ হয়েছে। নতুন কোড নিন।';
        case 'operation-not-allowed':
          return 'Firebase Console-এ এই Login পদ্ধতি চালু করা নেই।';
        case 'quota-exceeded':
          return 'SMS পাঠানোর সীমা শেষ হয়েছে। পরে আবার চেষ্টা করুন।';
        case 'network-request-failed':
          return 'ইন্টারনেট সংযোগ পাওয়া যায়নি।';
        case 'too-many-requests':
          return 'অনেকবার চেষ্টা করা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন।';
      }
    }
    if (exception is TimeoutException) {
      return 'SMS যাচাই করতে সময় বেশি লাগছে। আবার চেষ্টা করুন।';
    }
    return 'কিছু ভুল হয়েছে। আবার চেষ্টা করুন।';
  }

  Future<bool> _run(Future<void> Function() action) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (exception) {
      error = _msg(exception);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) =>
      _run(() => _repo!.signIn(email, password));

  Future<bool> register(String name, String email, String password, String type) =>
      _run(() => _repo!.register(name, email, password, accountType: type));

  Future<bool> google() => _run(() => _repo!.signInWithGoogle());

  Future<bool> sendPhoneCode(String phoneNumber) async {
    final ok = await _run(() async {
      final id = await _repo!.sendPhoneCode(phoneNumber);
      if (id == FirebaseAuthRepository.autoVerified) {
        phoneVerificationId = null;
        phoneCodeSent = false;
      } else {
        phoneVerificationId = id;
        phoneCodeSent = true;
      }
    });
    notifyListeners();
    return ok;
  }

  Future<bool> verifyPhoneCode(String code) async {
    final id = phoneVerificationId;
    if (id == null) {
      error = 'আগে ফোন নম্বরে OTP পাঠান।';
      notifyListeners();
      return false;
    }
    final ok = await _run(() => _repo!.verifyPhoneCode(id, code));
    if (ok) {
      phoneVerificationId = null;
      phoneCodeSent = false;
    }
    notifyListeners();
    return ok;
  }

  void resetPhoneFlow() {
    phoneVerificationId = null;
    phoneCodeSent = false;
    error = null;
    notifyListeners();
  }

  Future<bool> reset(String email) => _run(() => _repo!.sendPasswordReset(email));

  Future<void> signOut() async {
    await _repo?.signOut();
    user = null;
    role = 'user';
    notifyListeners();
  }

  Future<bool> updateName(String name) => _run(() => _repo!.updateName(name));

  Future<bool> deleteAccount() async {
    final success = await _run(() => _repo!.deleteAccount());
    if (success) user = null;
    notifyListeners();
    return success;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
