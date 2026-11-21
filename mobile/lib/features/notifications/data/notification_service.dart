import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../../../core/constants.dart';
import '../../prayer_times/data/prayer_calculator.dart';
import '../../reminders/data/content_repository.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/notification_prefs.dart';

class _Pending {
  final DateTime at;
  final String channel; // prayer id or content key
  final String title;
  final String body;
  final bool isPrayer;
  final PrayerNotif? prayerCfg;
  _Pending(this.at, this.channel, this.title, this.body, this.isPrayer, this.prayerCfg);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static bool get _supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> init() async {
    if (!_supported) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {}
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
          requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
    );
    await _plugin.initialize(settings);
    _ready = true;
  }

  static Future<bool> requestPermissions() async {
    if (!_ready) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    bool ok = true;
    if (android != null) {
      ok = (await android.requestNotificationsPermission()) ?? true;
      await android.requestExactAlarmsPermission();
    }
    if (ios != null) {
      ok = (await ios.requestPermissions(alert: true, badge: true, sound: true)) ?? false;
    }
    return ok;
  }

  static Future<bool> canScheduleExact() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    return (await android.canScheduleExactNotifications()) ?? false;
  }

  // ---- localized prayer copy -------------------------------------------------
  static const _bnGen = {
    'fajr': 'ফজরের',
    'dhuhr': 'যোহরের',
    'asr': 'আসরের',
    'maghrib': 'মাগরিবের',
    'isha': 'ইশার',
  };
  static const _enName = {'fajr': 'Fajr', 'dhuhr': 'Dhuhr', 'asr': 'Asr', 'maghrib': 'Maghrib', 'isha': 'Isha'};
  static const _arName = {'fajr': 'الفجر', 'dhuhr': 'الظهر', 'asr': 'العصر', 'maghrib': 'المغرب', 'isha': 'العشاء'};

  static String _num(String lang, int n) {
    if (lang != 'bn') return '$n';
    const d = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return '$n'.split('').map((c) => d[int.parse(c)]).join();
  }

  static String prayerTitle(String lang, String id) {
    switch (lang) {
      case 'en':
        return 'It is time for ${_enName[id]} prayer.';
      case 'ar':
        return 'حان وقت صلاة ${_arName[id]}.';
      default:
        return '${_bnGen[id]} নামাজের সময় হয়েছে।';
    }
  }

  static String prayerBody(String lang) {
    switch (lang) {
      case 'en':
        return 'Take a break from worldly busyness. It is time to stand before Allah.';
      case 'ar':
        return 'خذ استراحة من مشاغل الدنيا. حان وقت الوقوف بين يدي الله.';
      default:
        return 'দুনিয়ার ব্যস্ততা থেকে কিছুক্ষণ বিরতি নিন। আল্লাহর সামনে দাঁড়ানোর সময় হয়েছে।';
    }
  }

  static String earlyTitle(String lang, String id, int m) {
    switch (lang) {
      case 'en':
        return '${_enName[id]} in $m minutes';
      case 'ar':
        return 'صلاة ${_arName[id]} بعد $m دقيقة';
      default:
        return '${_bnGen[id]} নামাজের আর ${_num(lang, m)} মিনিট বাকি';
    }
  }

  static const _contentTitle = {
    'hadith': {'bn': 'আজকের হাদিস', 'en': 'Hadith of the day', 'ar': 'حديث اليوم'},
    'akhirah': {'bn': 'আখিরাতকে স্মরণ করুন', 'en': 'Remember the Hereafter', 'ar': 'تذكّر الآخرة'},
    'reminder': {'bn': 'ইসলামিক স্মরণ', 'en': 'Islamic reminder', 'ar': 'تذكير إسلامي'},
    'night': {'bn': 'রাতের আত্মসমালোচনা', 'en': 'Night reflection', 'ar': 'محاسبة الليل'},
    'evening_adhkar': {'bn': 'সন্ধ্যার আজকার', 'en': 'Evening Adhkar', 'ar': 'أذكار المساء'},
    'morning_adhkar': {'bn': 'সকালের আজকার', 'en': 'Morning Adhkar', 'ar': 'أذكار الصباح'},
    'quran': {'bn': 'কুরআন তিলাওয়াত', 'en': 'Quran reading', 'ar': 'تلاوة القرآن'},
    'tawbah': {'bn': 'তওবা ও ইস্তিগফার', 'en': 'Repentance', 'ar': 'التوبة والاستغفار'},
  };

  // Generic prompts contain no religious attribution, so they need no citation.
  static const _generic = {
    'evening_adhkar': 'সন্ধ্যার আজকার পড়ার সময় হয়েছে। কিছুক্ষণ আল্লাহকে স্মরণ করুন।',
    'morning_adhkar': 'সকালের আজকার দিয়ে দিনটি শুরু করুন।',
    'quran': 'আজ কুরআনের কিছু অংশ তিলাওয়াত করার জন্য একটু সময় রাখুন।',
    'tawbah': 'এক মুহূর্ত থেমে আল্লাহর কাছে ক্ষমা চান।',
    'night': 'ঘুমানোর আগে আজকের দিনটি নিয়ে একটু ভাবুন। "আজকের আত্মসমালোচনা" খুলুন।',
  };

  static String _t(String key, String lang) => _contentTitle[key]![lang] ?? _contentTitle[key]!['bn']!;

  // ---- scheduling ---------------------------------------------------------------
  static Future<int> rescheduleAll(SettingsController st, ContentRepository content) async {
    if (!_ready) return 0;
    await _plugin.cancelAll();
    final prefs = st.notif;
    final now = DateTime.now();
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final horizonDays = isIos ? 4 : 7;
    final pending = <_Pending>[];

    for (int d = 0; d < horizonDays; d++) {
      final date = DateTime(now.year, now.month, now.day).add(Duration(days: d));
      final day = PrayerCalculator.compute(
          lat: st.lat, lng: st.lng, date: date, method: st.method, madhab: st.madhab, adjust: st.adjust);
      final times = day.fivePrayers;

      for (final id in prayerIds) {
        final cfg = prefs.prayers[id]!;
        if (!cfg.enabled) continue;
        final t = times[id]!;
        String body = prayerBody(st.lang);
        // Attach a verified hadith on prayer importance only when one exists.
        final h = await content.hadithFor(date, category: 'নামাজের গুরুত্ব');
        if (h != null) body = '$body\n${h.bn} (${h.reference})';
        if (t.isAfter(now)) pending.add(_Pending(t, id, prayerTitle(st.lang, id), body, true, cfg));
        if (cfg.early > 0) {
          final e = t.subtract(Duration(minutes: cfg.early));
          if (e.isAfter(now)) {
            pending.add(_Pending(e, id, earlyTitle(st.lang, id, cfg.early), prayerBody(st.lang), true, cfg));
          }
        }
      }

      final dayContent = <_Pending>[];
      for (final entry in prefs.content.entries) {
        final c = entry.value;
        if (!c.enabled) continue;
        final at = c.anchor != null
            ? times[c.anchor]!
            : DateTime(date.year, date.month, date.day, c.hour, c.minute);
        if (!at.isAfter(now)) continue;
        if (prefs.inQuietHours(at.hour * 60 + at.minute)) continue;
        final body = await _contentBody(entry.key, date, content, st.lang);
        if (body == null) continue;
        dayContent.add(_Pending(at, entry.key, _t(entry.key, st.lang), body, false, null));
      }
      dayContent.sort((a, b) => a.at.compareTo(b.at));
      pending.addAll(dayContent.take(prefs.dailyLimit));
    }

    pending.sort((a, b) => a.at.compareTo(b.at));
    final capped = isIos ? pending.take(60).toList() : pending;
    final mode = (await canScheduleExact())
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    int id = 1000;
    for (final p in capped) {
      await _plugin.zonedSchedule(
        id++,
        p.title,
        p.body,
        tz.TZDateTime.from(p.at, tz.local),
        _details(p),
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
    return capped.length;
  }

  static Future<String?> _contentBody(String key, DateTime date, ContentRepository c, String lang) async {
    switch (key) {
      case 'hadith':
        final h = await c.hadithFor(date);
        if (h == null) return null; // never send unverified / missing Hadith
        return '${h.bn}\n(${h.reference})';
      case 'akhirah':
        return (await c.reflectionFor('akhirah', date))?.bn;
      case 'reminder':
        return (await c.reflectionFor('reminder', date))?.bn;
      default:
        return _generic[key];
    }
  }

  static NotificationDetails _details(_Pending p) {
    if (p.isPrayer) {
      final cfg = p.prayerCfg!;
      final useAdhan = cfg.adhan && kAdhanBundled;
      return NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_${p.channel}_${useAdhan ? 'a' : 'n'}_${cfg.vibrate ? 'v' : 'q'}',
          'Prayer - ${p.channel}',
          channelDescription: 'Prayer time notifications',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          enableVibration: cfg.vibrate,
          playSound: true,
          sound: useAdhan ? const RawResourceAndroidNotificationSound('adhan') : null,
          styleInformation: BigTextStyleInformation(p.body),
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );
    }
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'content_${p.channel}',
        'Reminders - ${p.channel}',
        channelDescription: 'Islamic reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        styleInformation: BigTextStyleInformation(p.body),
      ),
      iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
  }

  static Future<void> sendTest(String lang) async {
    if (!_ready) return;
    await _plugin.show(
      1,
      prayerTitle(lang, 'fajr'),
      prayerBody(lang),
      const NotificationDetails(
        android: AndroidNotificationDetails('test', 'Test',
            importance: Importance.high, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<List<PendingNotificationRequest>> pending() =>
      _ready ? _plugin.pendingNotificationRequests() : Future.value([]);
}
