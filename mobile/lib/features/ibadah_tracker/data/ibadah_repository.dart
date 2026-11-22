import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/services/prefs.dart';

const ibadahItems = [
  'fajr', 'dhuhr', 'asr', 'maghrib', 'isha',
  'quran', 'morning_adhkar', 'evening_adhkar', 'istighfar', 'good_deeds', 'charity',
];
const _prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Local-first worship tracker. Writes are mirrored to Firestore (owner-only
/// documents) when the user is signed in; failures never block the UI.
class IbadahRepository extends ChangeNotifier {
  Map<String, bool> forDay(DateTime d) {
    final j = Prefs.json('ibadah_${dayKey(d)}') ?? {};
    return {for (final k in ibadahItems) k: j[k] == true};
  }

  Future<void> set(DateTime d, String item, bool value) async {
    final m = forDay(d);
    m[item] = value;
    final key = dayKey(d);
    await Prefs.setJson('ibadah_$key', m);
    await Prefs.setI('ibadah_updated_$key', DateTime.now().millisecondsSinceEpoch);
    notifyListeners();
    _sync(d, m);
  }

  Future<void> _sync(DateTime d, Map<String, bool> m) async {
    final uid = Fb.uid;
    if (uid == null) return;
    try {
      final key = dayKey(d);
      final db = FirebaseFirestore.instance;
      await db.collection('ibadah_records').doc('${uid}_$key').set({
        'uid': uid,
        'date': key,
        'items': m,
        'clientUpdatedAt': Prefs.i('ibadah_updated_$key') ?? DateTime.now().millisecondsSinceEpoch,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await db.collection('prayer_records').doc('${uid}_$key').set({
        'uid': uid,
        'date': key,
        'prayers': {for (final p in _prayers) p: m[p] ?? false},
        'clientUpdatedAt': Prefs.i('ibadah_updated_$key') ?? DateTime.now().millisecondsSinceEpoch,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  int doneCount(DateTime d) => forDay(d).values.where((v) => v).length;
  double progress(DateTime d) => doneCount(d) / ibadahItems.length;

  /// Number of days (out of [days] ending today) on which all five prayers were completed.
  int prayerConsistency(int days) {
    int c = 0;
    final today = DateTime.now();
    for (int i = 0; i < days; i++) {
      final m = forDay(today.subtract(Duration(days: i)));
      if (_prayers.every((p) => m[p] == true)) c++;
    }
    return c;
  }

  Map<String, int> totals(int days) {
    final out = {for (final k in ibadahItems) k: 0};
    final today = DateTime.now();
    for (int i = 0; i < days; i++) {
      final m = forDay(today.subtract(Duration(days: i)));
      m.forEach((k, v) {
        if (v) out[k] = out[k]! + 1;
      });
    }
    return out;
  }
}
