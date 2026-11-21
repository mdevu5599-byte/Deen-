import 'package:adhan/adhan.dart';
import '../domain/prayer_day.dart';

const calculationMethods = <String, String>{
  'karachi': 'University of Islamic Sciences, Karachi',
  'muslim_world_league': 'Muslim World League',
  'egyptian': 'Egyptian General Authority of Survey',
  'umm_al_qura': 'Umm al-Qura, Makkah',
  'dubai': 'Dubai',
  'qatar': 'Qatar',
  'kuwait': 'Kuwait',
  'singapore': 'Singapore',
  'turkey': 'Turkey (Diyanet)',
  'tehran': 'Tehran',
  'north_america': 'ISNA (North America)',
  'moon_sighting_committee': 'Moonsighting Committee',
};

class PrayerCalculator {
  /// Bangladesh default: Karachi method + Hanafi Asr, the common standard in South Asia.
  static PrayerDay compute({
    required double lat,
    required double lng,
    required DateTime date,
    required String method,
    required String madhab,
    required Map<String, int> adjust,
  }) {
    final m = CalculationMethod.values.firstWhere((e) => e.name == method,
        orElse: () => CalculationMethod.karachi);
    final params = m.getParameters();
    params.madhab = madhab == 'shafi' ? Madhab.shafi : Madhab.hanafi;
    params.adjustments.fajr = adjust['fajr'] ?? 0;
    params.adjustments.dhuhr = adjust['dhuhr'] ?? 0;
    params.adjustments.asr = adjust['asr'] ?? 0;
    params.adjustments.maghrib = adjust['maghrib'] ?? 0;
    params.adjustments.isha = adjust['isha'] ?? 0;

    final pt = PrayerTimes(Coordinates(lat, lng), DateComponents.from(date), params);
    return PrayerDay(
      DateTime(date.year, date.month, date.day),
      pt.fajr!.toLocal(),
      pt.sunrise!.toLocal(),
      pt.dhuhr!.toLocal(),
      pt.asr!.toLocal(),
      pt.maghrib!.toLocal(),
      pt.isha!.toLocal(),
    );
  }
}
