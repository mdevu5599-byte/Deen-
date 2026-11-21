class PrayerDay {
  final DateTime date;
  final DateTime fajr, sunrise, dhuhr, asr, maghrib, isha;
  const PrayerDay(this.date, this.fajr, this.sunrise, this.dhuhr, this.asr, this.maghrib, this.isha);

  Map<String, DateTime> get fivePrayers =>
      {'fajr': fajr, 'dhuhr': dhuhr, 'asr': asr, 'maghrib': maghrib, 'isha': isha};

  /// Returns the next prayer after [now] within this day, or null if all have passed.
  MapEntry<String, DateTime>? nextAfter(DateTime now) {
    for (final e in fivePrayers.entries) {
      if (e.value.isAfter(now)) return e;
    }
    return null;
  }
}
