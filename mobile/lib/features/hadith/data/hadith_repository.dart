import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/services/prefs.dart';
import '../domain/hadith.dart';

class HadithRepository {
  List<Hadith>? _cache;

  /// Loads bundled verified Hadith plus (when Firebase is configured) Hadith
  /// approved in Firestore. Records not marked 'verified' are dropped.
  Future<List<Hadith>> all() async {
    if (_cache != null) return _cache!;
    final out = <String, Hadith>{};
    try {
      final raw = await rootBundle.loadString('assets/data/hadith.json');
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      for (final j in list) {
        if (j['status'] != 'verified' && j['status'] != 'imported') continue;
        final h = Hadith.fromJson(j['id'].toString(), j);
        if (h.isPublishable) out[h.id] = h;
      }
    } catch (_) {}
    if (Fb.ready) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('hadith')
            .where('status', isEqualTo: 'verified')
            .limit(500)
            .get();
        for (final d in snap.docs) {
          final h = Hadith.fromJson(d.id, d.data());
          if (h.isPublishable) out[h.id] = h;
        }
      } catch (_) {}
    }
    _cache = out.values.toList();
    return _cache!;
  }

  void invalidate() => _cache = null;

  Future<List<Hadith>> byCategory(String? category) async {
    final a = await all();
    return category == null ? a : a.where((h) => h.category == category).toList();
  }

  Set<String> favourites() => (Prefs.json('fav_hadith') ?? {}).keys.toSet();

  Future<void> toggleFavourite(String id) async {
    final m = Prefs.json('fav_hadith') ?? <String, dynamic>{};
    if (m.containsKey(id)) {
      m.remove(id);
    } else {
      m[id] = true;
    }
    await Prefs.setJson('fav_hadith', m);
    await CloudSyncService().pushSettings();
  }
}
