import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/prefs.dart';
import '../../notifications/domain/notification_prefs.dart';

class SettingsController extends ChangeNotifier {
  String lang = Prefs.s('lang') ?? 'bn';
  double fontScale = Prefs.d('fontScale') ?? 1.0;
  String method = Prefs.s('method') ?? 'karachi';
  String madhab = Prefs.s('madhab') ?? 'hanafi';
  int hijriOffset = Prefs.i('hijriOffset') ?? 0;
  Map<String, int> adjust = {
    for (final p in prayerIds) p: Prefs.i('adj_$p') ?? 0,
  };
  double lat = Prefs.d('lat') ?? 23.8103;
  double lng = Prefs.d('lng') ?? 90.4125;
  String placeName = Prefs.s('placeName') ?? 'ঢাকা';
  bool autoLocation = Prefs.b('autoLocation') ?? false;
  bool guestMode = Prefs.b('guest') ?? false;
  NotificationPrefs notif = NotificationPrefs.fromJson(Prefs.json('notif'));

  void _queueCloudSync() {
    unawaited(CloudSyncService().pushSettings());
  }

  /// Reload values after a signed-in account has restored its cloud settings.
  void reloadFromPrefs() {
    lang = Prefs.s('lang') ?? 'bn';
    fontScale = Prefs.d('fontScale') ?? 1.0;
    method = Prefs.s('method') ?? 'karachi';
    madhab = Prefs.s('madhab') ?? 'hanafi';
    hijriOffset = Prefs.i('hijriOffset') ?? 0;
    adjust = {for (final p in prayerIds) p: Prefs.i('adj_$p') ?? 0};
    lat = Prefs.d('lat') ?? 23.8103;
    lng = Prefs.d('lng') ?? 90.4125;
    placeName = Prefs.s('placeName') ?? 'ঢাকা';
    autoLocation = Prefs.b('autoLocation') ?? false;
    notif = NotificationPrefs.fromJson(Prefs.json('notif'));
    notifyListeners();
  }

  Future<void> setLang(String v) async {
    lang = v;
    await Prefs.setS('lang', v);
    notifyListeners();
    _queueCloudSync();
  }

  Future<void> setFontScale(double v) async {
    fontScale = v;
    await Prefs.setD('fontScale', v);
    notifyListeners();
    _queueCloudSync();
  }

  Future<void> setMethod(String v) async {
    method = v;
    await Prefs.setS('method', v);
    notifyListeners();
    _queueCloudSync();
  }

  Future<void> setMadhab(String v) async {
    madhab = v;
    await Prefs.setS('madhab', v);
    notifyListeners();
    _queueCloudSync();
  }

  Future<void> setAdjust(String prayer, int v) async {
    adjust[prayer] = v;
    await Prefs.setI('adj_$prayer', v);
    notifyListeners();
    _queueCloudSync();
  }

  Future<void> setHijriOffset(int v) async {
    hijriOffset = v;
    await Prefs.setI('hijriOffset', v);
    notifyListeners();
    _queueCloudSync();
  }

  Future<void> setLocation(double la, double lo, String name, {bool auto = false}) async {
    lat = la;
    lng = lo;
    placeName = name;
    autoLocation = auto;
    await Prefs.setD('lat', la);
    await Prefs.setD('lng', lo);
    await Prefs.setS('placeName', name);
    await Prefs.setB('autoLocation', auto);
    notifyListeners();
    _queueCloudSync();
  }

  Future<void> setGuest(bool v) async {
    guestMode = v;
    await Prefs.setB('guest', v);
    notifyListeners();
  }

  Future<void> saveNotif() async {
    await Prefs.setJson('notif', notif.toJson());
    notifyListeners();
    _queueCloudSync();
  }
}
