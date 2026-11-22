import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_bootstrap.dart';
import 'prefs.dart';

/// Local-first cross-device sync for the signed-in user's private DEEN data.
/// Journals remain owner-only; this service never grants admin access to them.
class CloudSyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> syncUser(String uid) async {
    await _syncSettings(uid);
    await _syncIbadah(uid);
    await _syncTasbih(uid);
    await _syncJournals(uid);
  }

  Future<void> pushSettings() async {
    final uid = Fb.uid;
    if (uid == null) return;
    try {
      await _writeSettings(uid);
    } catch (_) {}
  }

  Future<void> _syncSettings(String uid) async {
    try {
      final refs = await Future.wait([
        _db.collection('user_settings').doc(uid).get(),
        _db.collection('prayer_settings').doc(uid).get(),
        _db.collection('notification_preferences').doc(uid).get(),
      ]);

      final user = refs[0].data();
      if (user != null) {
        if (user['language'] is String) await Prefs.setS('lang', user['language'] as String);
        if (user['fontScale'] is num) await Prefs.setD('fontScale', (user['fontScale'] as num).toDouble());
      }

      final prayer = refs[1].data();
      if (prayer != null) {
        if (prayer['method'] is String) await Prefs.setS('method', prayer['method'] as String);
        if (prayer['madhab'] is String) await Prefs.setS('madhab', prayer['madhab'] as String);
        if (prayer['hijriOffset'] is num) await Prefs.setI('hijriOffset', (prayer['hijriOffset'] as num).toInt());
        if (prayer['lat'] is num) await Prefs.setD('lat', (prayer['lat'] as num).toDouble());
        if (prayer['lng'] is num) await Prefs.setD('lng', (prayer['lng'] as num).toDouble());
        if (prayer['placeName'] is String) await Prefs.setS('placeName', prayer['placeName'] as String);
        if (prayer['autoLocation'] is bool) await Prefs.setB('autoLocation', prayer['autoLocation'] as bool);
        final adjust = prayer['adjust'];
        if (adjust is Map) {
          for (final entry in adjust.entries) {
            if (entry.value is num) {
              await Prefs.setI('adj_${entry.key}', (entry.value as num).toInt());
            }
          }
        }
      }

      final notification = refs[2].data();
      final prefs = notification?['prefs'];
      if (prefs is Map) await Prefs.setJson('notif', Map<String, dynamic>.from(prefs));

      await _writeSettings(uid);
    } catch (_) {
      // Keep the local app usable when the device is offline or a query is denied.
    }
  }

  Future<void> _writeSettings(String uid) async {
    final user = {
      'uid': uid,
      'language': Prefs.s('lang') ?? 'bn',
      'fontScale': Prefs.d('fontScale') ?? 1.0,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final prayer = {
      'uid': uid,
      'method': Prefs.s('method') ?? 'karachi',
      'madhab': Prefs.s('madhab') ?? 'hanafi',
      'hijriOffset': Prefs.i('hijriOffset') ?? 0,
      'adjust': {
        for (final key in const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'])
          key: Prefs.i('adj_$key') ?? 0,
      },
      'lat': Prefs.d('lat') ?? 23.8103,
      'lng': Prefs.d('lng') ?? 90.4125,
      'placeName': Prefs.s('placeName') ?? 'ঢাকা',
      'autoLocation': Prefs.b('autoLocation') ?? false,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await Future.wait([
      _db.collection('user_settings').doc(uid).set(user, SetOptions(merge: true)),
      _db.collection('prayer_settings').doc(uid).set(prayer, SetOptions(merge: true)),
      _db.collection('notification_preferences').doc(uid).set({
        'uid': uid,
        'prefs': Prefs.json('notif') ?? {},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    ]);
  }

  Future<void> _syncIbadah(String uid) async {
    try {
      final snap = await _db.collection('ibadah_records')
          .where('uid', isEqualTo: uid)
          .limit(500)
          .get();
      final cloudDates = <String>{};
      for (final document in snap.docs) {
        final data = document.data();
        final date = (data['date'] ?? '').toString();
        if (date.isEmpty) continue;
        cloudDates.add(date);
        final remoteItems = data['items'];
        final localItems = Prefs.json('ibadah_$date');
        final remote = remoteItems is Map ? Map<String, dynamic>.from(remoteItems) : <String, dynamic>{};
        final local = localItems ?? <String, dynamic>{};
        final merged = <String, dynamic>{
          for (final key in {...remote.keys, ...local.keys})
            key: remote[key] == true || local[key] == true,
        };
        await Prefs.setJson('ibadah_$date', merged);
      }

      for (final key in Prefs.keys().where((k) => k.startsWith('ibadah_'))) {
        final date = key.substring('ibadah_'.length);
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) continue;
        final items = Prefs.json(key);
        if (items == null) continue;
        final recordId = '${uid}_$date';
        await _db.collection('ibadah_records').doc(recordId).set({
          'uid': uid,
          'date': date,
          'items': items,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await _db.collection('prayer_records').doc(recordId).set({
          'uid': uid,
          'date': date,
          'prayers': {
            for (final prayer in const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'])
              prayer: items[prayer] == true,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  Future<void> _syncTasbih(String uid) async {
    try {
      final snap = await _db.collection('tasbih_records')
          .where('uid', isEqualTo: uid)
          .limit(500)
          .get();
      for (final document in snap.docs) {
        final data = document.data();
        final date = (data['date'] ?? '').toString();
        final remoteCounts = data['counts'];
        if (date.isEmpty || remoteCounts is! Map) continue;
        final local = Prefs.json('tasbih_$date') ?? <String, dynamic>{};
        final remote = Map<String, dynamic>.from(remoteCounts);
        final merged = <String, dynamic>{
          for (final key in {...remote.keys, ...local.keys})
            key: ((remote[key] is num ? remote[key] as num : 0)
                    .toInt() >
                (local[key] is num ? local[key] as num : 0).toInt())
                ? (remote[key] as num).toInt()
                : (local[key] as num? ?? 0).toInt(),
        };
        await Prefs.setJson('tasbih_$date', merged);
        final targets = data['targets'];
        if (targets is Map) {
          for (final entry in targets.entries) {
            if (entry.value is num && Prefs.i('tasbih_target_${entry.key}') == null) {
              await Prefs.setI('tasbih_target_${entry.key}', (entry.value as num).toInt());
            }
          }
        }
      }

      final targetValues = <String, int>{};
      for (final key in Prefs.keys().where((k) => k.startsWith('tasbih_target_'))) {
        final value = Prefs.i(key);
        if (value != null) targetValues[key.substring('tasbih_target_'.length)] = value;
      }
      for (final key in Prefs.keys().where((k) => k.startsWith('tasbih_') && !k.startsWith('tasbih_target_'))) {
        final date = key.substring('tasbih_'.length);
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) continue;
        final counts = Prefs.json(key);
        if (counts == null) continue;
        await _db.collection('tasbih_records').doc('${uid}_$date').set({
          'uid': uid,
          'date': date,
          'counts': counts,
          'targets': targetValues,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  Future<void> _syncJournals(String uid) async {
    try {
      final snap = await _db.collection('journals')
          .where('uid', isEqualTo: uid)
          .limit(500)
          .get();
      for (final document in snap.docs) {
        final data = document.data();
        final date = (data['date'] ?? '').toString();
        final answers = data['answers'];
        if (date.isEmpty || answers is! Map) continue;
        final local = Prefs.json('journal_$date') ?? <String, dynamic>{};
        final remote = Map<String, dynamic>.from(answers);
        await Prefs.setJson('journal_$date', {...remote, ...local});
      }

      for (final key in Prefs.keys().where((k) => k.startsWith('journal_'))) {
        final date = key.substring('journal_'.length);
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) continue;
        final answers = Prefs.json(key);
        if (answers == null) continue;
        await _db.collection('journals').doc('${uid}_$date').set({
          'uid': uid,
          'date': date,
          'answers': answers,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // Journals stay available locally if cloud sync is unavailable.
    }
  }
}
