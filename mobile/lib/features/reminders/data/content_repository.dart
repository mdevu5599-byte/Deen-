import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/constants.dart';
import '../../hadith/data/hadith_repository.dart';
import '../../hadith/domain/hadith.dart';

/// An original, unattributed reflection written for DEEN. It is NOT a Hadith or
/// Quran quotation and is labelled as such in the UI.
class Reflection {
  final String id;
  final String group; // akhirah | reminder | tawbah | night
  final String category;
  final String bn;
  final String lessonBn;
  const Reflection(this.id, this.group, this.category, this.bn, this.lessonBn);
}

class ContentRepository {
  final HadithRepository hadith;
  ContentRepository(this.hadith);
  List<Reflection>? _refl;

  Future<List<Reflection>> reflections([String? group]) async {
    if (_refl == null) {
      try {
        final raw = await rootBundle.loadString('assets/data/reminders.json');
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        _refl = list
            .where((j) => j['kind'] == 'original')
            .map((j) => Reflection(
                  j['id'].toString(),
                  j['group'].toString(),
                  (j['category'] ?? '').toString(),
                  j['bn'].toString(),
                  (j['lessonBn'] ?? '').toString(),
                ))
            .toList();
      } catch (_) {
        _refl = [];
      }

      // Show only admin-approved original reflections in the user app.
      if (Fb.ready) {
        try {
          final snap = await FirebaseFirestore.instance
              .collection('reminders')
              .where('status', isEqualTo: 'verified')
              .limit(500)
              .get();
          final merged = <String, Reflection>{for (final item in _refl!) item.id: item};
          for (final document in snap.docs) {
            final data = document.data();
            if ((data['kind'] ?? 'original') != 'original') continue;
            final text = (data['bn'] ?? '').toString().trim();
            if (text.isEmpty) continue;
            merged[document.id] = Reflection(
              document.id,
              (data['group'] ?? 'reminder').toString(),
              (data['category'] ?? '').toString(),
              text,
              (data['lessonBn'] ?? '').toString(),
            );
          }
          _refl = merged.values.toList();
        } catch (_) {
          // Bundled reflections remain available if the device is offline.
        }
      }
    }
    return group == null ? _refl! : _refl!.where((r) => r.group == group).toList();
  }

  /// Deterministic, non-repeating rotation: item index advances by one per day,
  /// so the same item is not shown again until the whole list has been cycled.
  static int rotate(DateTime date, int salt, int length) {
    if (length == 0) return 0;
    final days = DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/ 86400000;
    return (days + salt) % length;
  }

  Future<Reflection?> reflectionFor(String group, DateTime date) async {
    final l = await reflections(group);
    if (l.isEmpty) return null;
    return l[rotate(date, group.hashCode.abs() % 97, l.length)];
  }

  /// Round-robin over death/akhirah/mercy categories so consecutive notifications
  /// alternate themes and a hadith is not repeated until the whole set was shown.
  Future<Hadith?> deathHadithAt(int seq) async {
    final lists = <List<Hadith>>[];
    for (final c in kDeathHadithCategories) {
      var l = await hadith.byCategory(c);
      if (!kNotifyImportedHadith) l = l.where((h) => h.isVerified).toList();
      if (l.isNotEmpty) lists.add(l);
    }
    if (lists.isEmpty) return null;
    final mixed = <Hadith>[];
    final longest = lists.map((l) => l.length).reduce((a, b) => a > b ? a : b);
    for (int i = 0; i < longest; i++) {
      for (final l in lists) {
        if (i < l.length) mixed.add(l[i]);
      }
    }
    return mixed[seq % mixed.length];
  }

  Future<Hadith?> hadithFor(DateTime date, {String? category, bool forNotification = false}) async {
    var l = await hadith.byCategory(category);
    if (forNotification && !kNotifyImportedHadith) l = l.where((h) => h.isVerified).toList();
    if (l.isEmpty) return null;
    return l[rotate(date, (category ?? 'all').hashCode.abs() % 89, l.length)];
  }
}
