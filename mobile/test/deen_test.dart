import 'package:deen/features/notifications/domain/notification_prefs.dart';
import 'package:deen/features/prayer_times/data/prayer_calculator.dart';
import 'package:deen/features/reminders/data/content_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('prayer calculation', () {
    final adj = {for (final p in prayerIds) p: 0};

    test('Dhaka times are strictly ordered through the day', () {
      final d = PrayerCalculator.compute(
          lat: 23.8103, lng: 90.4125, date: DateTime(2026, 6, 15), method: 'karachi', madhab: 'hanafi', adjust: adj);
      expect(d.fajr.isBefore(d.sunrise), isTrue);
      expect(d.sunrise.isBefore(d.dhuhr), isTrue);
      expect(d.dhuhr.isBefore(d.asr), isTrue);
      expect(d.asr.isBefore(d.maghrib), isTrue);
      expect(d.maghrib.isBefore(d.isha), isTrue);
    });

    test('Hanafi Asr is later than Shafi Asr', () {
      final h = PrayerCalculator.compute(lat: 23.8103, lng: 90.4125, date: DateTime(2026, 3, 1), method: 'karachi', madhab: 'hanafi', adjust: adj);
      final s = PrayerCalculator.compute(lat: 23.8103, lng: 90.4125, date: DateTime(2026, 3, 1), method: 'karachi', madhab: 'shafi', adjust: adj);
      expect(h.asr.isAfter(s.asr), isTrue);
    });

    test('manual adjustment shifts a prayer by that many minutes', () {
      final a = PrayerCalculator.compute(lat: 23.8103, lng: 90.4125, date: DateTime(2026, 3, 1), method: 'karachi', madhab: 'hanafi', adjust: adj);
      final b = PrayerCalculator.compute(lat: 23.8103, lng: 90.4125, date: DateTime(2026, 3, 1), method: 'karachi', madhab: 'hanafi', adjust: {...adj, 'fajr': 3});
      expect(b.fajr.difference(a.fajr).inMinutes, 3);
    });
  });

  group('notification preferences', () {
    test('quiet hours spanning midnight', () {
      final p = NotificationPrefs(quietEnabled: true, quietStart: 23 * 60, quietEnd: 4 * 60);
      expect(p.inQuietHours(23 * 60 + 30), isTrue);
      expect(p.inQuietHours(2 * 60), isTrue);
      expect(p.inQuietHours(12 * 60), isFalse);
    });

    test('json round trip keeps defaults and edits', () {
      final p = NotificationPrefs();
      p.prayers['fajr']!.early = 15;
      final q = NotificationPrefs.fromJson(p.toJson());
      expect(q.prayers['fajr']!.early, 15);
      expect(q.content['hadith']!.hour, 10);
    });
  });

  test('content rotation does not repeat within one cycle', () {
    final seen = <int>{};
    final start = DateTime(2026, 1, 1);
    for (int i = 0; i < 10; i++) {
      seen.add(ContentRepository.rotate(start.add(Duration(days: i)), 5, 10));
    }
    expect(seen.length, 10);
  });
}
