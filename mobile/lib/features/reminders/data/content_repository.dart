import 'dart:convert';
import 'package:flutter/services.dart';
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
            .map((j) => Reflection(j['id'], j['group'], j['category'] ?? '', j['bn'], j['lessonBn'] ?? ''))
            .toList();
      } catch (_) {
        _refl = [];
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

  Future<Hadith?> hadithFor(DateTime date, {String? category}) async {
    final l = await hadith.byCategory(category);
    if (l.isEmpty) return null;
    return l[rotate(date, (category ?? 'all').hashCode.abs() % 89, l.length)];
  }
}
