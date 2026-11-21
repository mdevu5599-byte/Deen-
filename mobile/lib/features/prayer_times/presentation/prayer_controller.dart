import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/prayer_calculator.dart';
import '../domain/prayer_day.dart';

class PrayerController extends ChangeNotifier {
  final SettingsController settings;
  late PrayerDay today;
  Timer? _timer;
  int _lastDay = -1;

  PrayerController(this.settings) {
    _compute();
    settings.addListener(_compute);
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (DateTime.now().day != _lastDay) _compute();
    });
  }

  void _compute() {
    final now = DateTime.now();
    _lastDay = now.day;
    today = PrayerCalculator.compute(
      lat: settings.lat, lng: settings.lng, date: now,
      method: settings.method, madhab: settings.madhab, adjust: settings.adjust,
    );
    notifyListeners();
  }

  PrayerDay tomorrow() => PrayerCalculator.compute(
        lat: settings.lat, lng: settings.lng, date: DateTime.now().add(const Duration(days: 1)),
        method: settings.method, madhab: settings.madhab, adjust: settings.adjust,
      );

  /// Next prayer id and time (rolls over to tomorrow's Fajr after Isha).
  MapEntry<String, DateTime> next([DateTime? now]) {
    final n = now ?? DateTime.now();
    return today.nextAfter(n) ?? MapEntry('fajr', tomorrow().fajr);
  }

  @override
  void dispose() {
    _timer?.cancel();
    settings.removeListener(_compute);
    super.dispose();
  }
}
