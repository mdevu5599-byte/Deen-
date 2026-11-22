import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_bootstrap.dart';
import 'prefs.dart';

/// Local-first cross-device sync for the signed-in user's private DEEN data.
/// Journals remain owner-only; this service never grants admin access to them.
class CloudSyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int _version(dynamic value) {
    if (value is num) return value.toInt();
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    return 0;
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

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

  Future<void> pushReadingPreferences() async {
    final uid = Fb.uid;
    if (uid == null) return;
    try {
      await _db.collection('user_settings').doc(uid).set({
        'uid': uid,
        'quranLast': Prefs.json('quran_last') ?? {},
        'quranBookmarks': Prefs.json('quran_bookmarks') ?? {},
        'hadithFavourites': Prefs.json('fav_hadith') ?? {},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
        if (user['fontScale'] is num) {
          await Prefs.setD('fontScale', (user['fontScale'] as num).toDouble());
        }
        for (final entry in const {
          'quranLast': 'quran_last',
          'quranBookmarks': 'quran_bookmarks',
          'hadithFavourites': 'fav_hadith',
        }.entries) {
          final value = user[entry.key];
          if (value is Map) {
            await Prefs.setJson(entry.value, Map<String, dynamic>.from(value));
          }
        }
      }
      final prayer = refs[1].data();
      if (prayer != null) {
        if (prayer['method'] is String) await Prefs.setS('method', prayer['method'] as String);
        if (prayer['madhab'] is String) await Prefs.setS('madhab', prayer['madhab'] as String);
        if (prayer['hijriOffset'] is num) {
          await Prefs.setI('hijriOffset', (prayer['hijriOffset'] as num).toInt());
        }
        if (prayer['lat'] is num) await Prefs.setD('lat', (prayer['lat'] as num).toDouble());
        if (prayer['lng'] is num) await Prefs.setD('lng', (prayer['lng'] as num).toDouble());
        if (prayer['placeName'] is String) {
          await Prefs.setS('placeName', prayer['placeName'] as String);
        }
        if (prayer['autoLocation'] is bool) {
          await Prefs.setB('autoLocation', prayer['autoLocation'] as bool);
        }
        final adjust = prayer['adjust'];
        if (adjust is Map) {
          for (final entry in adjust.entries) {
            if (entry.value is num) {
              await Prefs.setI('adj_${entry.key}', (entry.value as num).toInt());
            }
          }
        }
      }
      final notificationPrefs = refs[2].data()?['prefs'];
      if (notificationPrefs is Map) {
        await Prefs.setJson('notif', Map<String, dynamic>.from(notificationPrefs));
      }
      await _writeSettings(uid);
    } catch (_) {
      // Keep local preferences usable while offline or when a cloud read is denied.
    }
  }

  Future<void> _writeSettings(String uid) async {
    final user = {
      'uid': uid,
      'language': Prefs.s('lang') ?? 'bn',
      'fontScale': Prefs.d('fontScale') ?? 1.0,
      'quranLast': Prefs.json('quran_last') ?? {},
      'quranBookmarks': Prefs.json('quran_bookmarks') ?? {},
      'hadithFavourites': Prefs.json('fav_hadith') ?? {},
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

  Future<void> _writeIbadah(String uid, String date, Map<String, dynamic> items, int version) async {
    final id = '${uid}_$date';
    await Future.wait([
      _db.collection('ibadah_records').doc(id).set({
        'uid': uid,
        'date': date,
        'items': items,
        'clientUpdatedAt': version,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
      _db.collection('prayer_records').doc(id).set({
        'uid': uid,
        'date': date,
        'prayers': {
          for (final prayer in const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'])
            prayer: items[prayer] == true,
        },
        'clientUpdatedAt': version,
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
        final remoteItems = data['items'];
        if (date.isEmpty || remoteItems is! Map) continue;
        cloudDates.add(date);

        final remote = Map<String, dynamic>.from(remoteItems);
        final local = Prefs.json('ibadah_$date');
        final localVersion = Prefs.i('ibadah_updated_$date') ?? 0;
        final remoteVersion = _version(data['clientUpdatedAt']);
        if (local != null && localVersion > remoteVersion) {
          await _writeIbadah(uid, date, local, localVersion);
        } else if (local != null && localVersion == 0 && remoteVersion == 0) {
          // One-time merge of legacy local and cloud tracker values.
          final merged = <String, dynamic>{
            for (final key in {...remote.keys, ...local.keys})
              key: local.containsKey(key) ? local[key] : remote[key],
          };
          final version = DateTime.now().millisecondsSinceEpoch;
          await Prefs.setJson('ibadah_$date', merged);
          await Prefs.setI('ibadah_updated_$date', version);
          await _writeIbadah(uid, date, merged, version);
        } else {
          await Prefs.setJson('ibadah_$date', remote);
          await Prefs.setI('ibadah_updated_$date', remoteVersion);
        }
      }

      for (final key in Prefs.keys().where((value) => value.startsWith('ibadah_'))) {
        final date = key.substring('ibadah_'.length);
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) || cloudDates.contains(date)) continue;
        final items = Prefs.json(key);
        if (items == null) continue;
        final version = Prefs.i('ibadah_updated_$date') ?? DateTime.now().millisecondsSinceEpoch;
        await Prefs.setI('ibadah_updated_$date', version);
        await _writeIbadah(uid, date, items, version);
      }
    } catch (_) {}
  }

  Future<void> pushTasbihDay(DateTime day) async {
    final uid = Fb.uid;
    if (uid == null) return;
    try {
      final date = _dateKey(day);
      final counts = Prefs.json('tasbih_$date');
      if (counts == null) return;
      final targets = <String, int>{};
      for (final key in Prefs.keys().where((value) => value.startsWith('tasbih_target_'))) {
        final value = Prefs.i(key);
        if (value != null) targets[key.substring('tasbih_target_'.length)] = value;
      }
      final version = Prefs.i('tasbih_updated_$date') ?? DateTime.now().millisecondsSinceEpoch;
      await _db.collection('tasbih_records').doc('${uid}_$date').set({
        'uid': uid,
        'date': date,
        'counts': counts,
        'targets': targets,
        'customDhikr': Prefs.s('tasbih_custom') ?? '',
        'clientUpdatedAt': version,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _syncTasbih(String uid) async {
    try {
      final snap = await _db.collection('tasbih_records')
          .where('uid', isEqualTo: uid)
          .limit(500)
          .get();
      final cloudDates = <String>{};
      for (final document in snap.docs) {
        final data = document.data();
        final date = (data['date'] ?? '').toString();
        final remoteCounts = data['counts'];
        if (date.isEmpty || remoteCounts is! Map) continue;
        cloudDates.add(date);
        final local = Prefs.json('tasbih_$date');
        final localVersion = Prefs.i('tasbih_updated_$date') ?? 0;
        final remoteVersion = _version(data['clientUpdatedAt']);

        if (local != null && localVersion > remoteVersion) {
          await pushTasbihDay(DateTime.parse(date));
        } else if (local != null && localVersion == 0 && remoteVersion == 0) {
          // Preserve legacy counters from both the phone and an older cloud document.
          final remote = Map<String, dynamic>.from(remoteCounts);
          final merged = <String, dynamic>{
            for (final key in {...remote.keys, ...local.keys})
              key: ((remote[key] is num ? remote[key] as num : 0).toInt() >
                      (local[key] is num ? local[key] as num : 0).toInt())
                  ? (remote[key] as num).toInt()
                  : (local[key] as num? ?? 0).toInt(),
          };
          final version = DateTime.now().millisecondsSinceEpoch;
          await Prefs.setJson('tasbih_$date', merged);
          await Prefs.setI('tasbih_updated_$date', version);
          await pushTasbihDay(DateTime.parse(date));
        } else {
          await Prefs.setJson('tasbih_$date', Map<String, dynamic>.from(remoteCounts));
          await Prefs.setI('tasbih_updated_$date', remoteVersion);
          final targets = data['targets'];
          if (targets is Map) {
            for (final entry in targets.entries) {
              if (entry.value is num) {
                await Prefs.setI('tasbih_target_${entry.key}', (entry.value as num).toInt());
              }
            }
          }
          final custom = data['customDhikr'];
          if (custom is String && custom.isNotEmpty) await Prefs.setS('tasbih_custom', custom);
        }
      }

      for (final key in Prefs.keys().where((value) =>
          value.startsWith('tasbih_') &&
          !value.startsWith('tasbih_target_') &&
          !value.startsWith('tasbih_updated_'))) {
        final date = key.substring('tasbih_'.length);
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) || cloudDates.contains(date)) continue;
        await pushTasbihDay(DateTime.parse(date));
      }
    } catch (_) {}
  }

  Future<void> _writeJournal(
    String uid,
    String date,
    Map<String, dynamic> answers,
    int version,
  ) async {
    await _db.collection('journals').doc('${uid}_$date').set({
      'uid': uid,
      'date': date,
      'answers': answers,
      'clientUpdatedAt': version,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _syncJournals(String uid) async {
    try {
      final snap = await _db.collection('journals')
          .where('uid', isEqualTo: uid)
          .limit(500)
          .get();
      final cloudDates = <String>{};
      for (final document in snap.docs) {
        final data = document.data();
        final date = (data['date'] ?? '').toString();
        final answers = data['answers'];
        if (date.isEmpty || answers is! Map) continue;
        cloudDates.add(date);

        final remote = Map<String, dynamic>.from(answers);
        final local = Prefs.json('journal_$date');
        final localVersion = Prefs.i('journal_updated_$date') ?? 0;
        final remoteVersion = _version(data['clientUpdatedAt']);
        if (local != null && localVersion > remoteVersion) {
          await _writeJournal(uid, date, local, localVersion);
        } else if (local != null && localVersion == 0 && remoteVersion == 0) {
          final merged = {...remote, ...local};
          final version = DateTime.now().millisecondsSinceEpoch;
          await Prefs.setJson('journal_$date', merged);
          await Prefs.setI('journal_updated_$date', version);
          await _writeJournal(uid, date, merged, version);
        } else {
          await Prefs.setJson('journal_$date', remote);
          await Prefs.setI('journal_updated_$date', remoteVersion);
        }
      }

      for (final key in Prefs.keys().where((value) => value.startsWith('journal_'))) {
        final date = key.substring('journal_'.length);
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) || cloudDates.contains(date)) continue;
        final answers = Prefs.json(key);
        if (answers == null) continue;
        final version = Prefs.i('journal_updated_$date') ?? DateTime.now().millisecondsSinceEpoch;
        await Prefs.setI('journal_updated_$date', version);
        await _writeJournal(uid, date, answers, version);
      }
    } catch (_) {
      // Journals stay available locally if cloud sync is unavailable.
    }
  }
}
