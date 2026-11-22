const prayerIds = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

class PrayerNotif {
  bool enabled;
  int early; // 0, 5, 10, 15, 30
  bool adhan;
  bool vibrate;
  PrayerNotif({this.enabled = true, this.early = 0, this.adhan = false, this.vibrate = true});

  Map<String, dynamic> toJson() => {'e': enabled, 'early': early, 'adhan': adhan, 'v': vibrate};
  factory PrayerNotif.fromJson(Map<String, dynamic> j) => PrayerNotif(
      enabled: j['e'] ?? true, early: j['early'] ?? 0, adhan: j['adhan'] ?? false, vibrate: j['v'] ?? true);
}

class ContentNotif {
  bool enabled;
  int hour;
  int minute;
  /// If set (e.g. 'maghrib'), the notification fires at that prayer time instead of hour:minute.
  String? anchor;
  ContentNotif({this.enabled = true, this.hour = 9, this.minute = 0, this.anchor});

  Map<String, dynamic> toJson() => {'e': enabled, 'h': hour, 'm': minute, 'a': anchor};
  factory ContentNotif.fromJson(Map<String, dynamic> j) =>
      ContentNotif(enabled: j['e'] ?? true, hour: j['h'] ?? 9, minute: j['m'] ?? 0, anchor: j['a']);
}

/// Periodic "remember death" hadith notifications: every [everyHours] hours between
/// [startHour] and [endHour] (inclusive), rotating through death/akhirah hadith.
class DeathPrefs {
  bool enabled;
  int everyHours; // 1, 2, 3, 4, 6
  int startHour;
  int endHour;
  DeathPrefs({this.enabled = true, this.everyHours = 3, this.startHour = 8, this.endHour = 21});

  Map<String, dynamic> toJson() => {'e': enabled, 'h': everyHours, 's': startHour, 'x': endHour};
  factory DeathPrefs.fromJson(Map<String, dynamic> j) => DeathPrefs(
      enabled: j['e'] ?? true, everyHours: j['h'] ?? 3, startHour: j['s'] ?? 8, endHour: j['x'] ?? 21);
}

class NotificationPrefs {
  final Map<String, PrayerNotif> prayers;
  final Map<String, ContentNotif> content;
  bool quietEnabled;
  int quietStart; // minutes from midnight
  int quietEnd;
  int dailyLimit;
  DeathPrefs death;

  NotificationPrefs({
    Map<String, PrayerNotif>? prayers,
    Map<String, ContentNotif>? content,
    this.quietEnabled = false,
    this.quietStart = 23 * 60,
    this.quietEnd = 4 * 60,
    this.dailyLimit = 20,
    DeathPrefs? death,
  })  : death = death ?? DeathPrefs(),
         prayers = prayers ?? {for (final p in prayerIds) p: PrayerNotif()},
        content = content ??
            {
              'hadith': ContentNotif(hour: 10, minute: 0),
              'akhirah': ContentNotif(hour: 13, minute: 0),
              'reminder': ContentNotif(hour: 16, minute: 0),
              'evening_adhkar': ContentNotif(anchor: 'maghrib'),
              'night': ContentNotif(hour: 21, minute: 0),
              'morning_adhkar': ContentNotif(enabled: false, hour: 6, minute: 30),
              'quran': ContentNotif(enabled: false, hour: 8, minute: 0),
              'tawbah': ContentNotif(enabled: false, hour: 20, minute: 0),
            };

  Map<String, dynamic> toJson() => {
        'prayers': prayers.map((k, v) => MapEntry(k, v.toJson())),
        'content': content.map((k, v) => MapEntry(k, v.toJson())),
        'qe': quietEnabled,
        'qs': quietStart,
        'qend': quietEnd,
        'limit': dailyLimit,
        'death': death.toJson(),
      };

  factory NotificationPrefs.fromJson(Map<String, dynamic>? j) {
    final d = NotificationPrefs();
    if (j == null) return d;
    final p = (j['prayers'] as Map?)?.cast<String, dynamic>();
    final c = (j['content'] as Map?)?.cast<String, dynamic>();
    if (p != null) {
      for (final k in prayerIds) {
        if (p[k] != null) d.prayers[k] = PrayerNotif.fromJson((p[k] as Map).cast<String, dynamic>());
      }
    }
    if (c != null) {
      for (final k in d.content.keys.toList()) {
        if (c[k] != null) d.content[k] = ContentNotif.fromJson((c[k] as Map).cast<String, dynamic>());
      }
    }
    d.quietEnabled = j['qe'] ?? false;
    d.quietStart = j['qs'] ?? d.quietStart;
    d.quietEnd = j['qend'] ?? d.quietEnd;
    d.dailyLimit = j['limit'] ?? 20;
    if (j['death'] is Map) d.death = DeathPrefs.fromJson((j['death'] as Map).cast<String, dynamic>());
    return d;
  }

  bool inQuietHours(int minuteOfDay) {
    if (!quietEnabled) return false;
    if (quietStart <= quietEnd) return minuteOfDay >= quietStart && minuteOfDay < quietEnd;
    return minuteOfDay >= quietStart || minuteOfDay < quietEnd;
  }
}
