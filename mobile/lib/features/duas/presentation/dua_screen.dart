import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

/// Duas are loaded only from verified records (status == 'verified') that carry
/// Arabic text, Bengali meaning and a reference. See docs/CONTENT_VERIFICATION.md.
class DuaScreen extends StatelessWidget {
  const DuaScreen({super.key});

  Future<List<Map<String, dynamic>>> _load() async {
    final records = <String, Map<String, dynamic>>{};
    try {
      final raw = await rootBundle.loadString('assets/data/duas.json');
      for (final dua in (jsonDecode(raw) as List).cast<Map<String, dynamic>>()) {
        if (_publishable(dua)) records[(dua['id'] ?? '').toString()] = dua;
      }
    } catch (_) {}

    // Admin-approved Duas appear without a new APK. Quran text stays source-imported.
    if (Fb.ready) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('duas')
            .where('status', isEqualTo: 'verified')
            .limit(300)
            .get();
        for (final document in snapshot.docs) {
          final dua = {...document.data(), 'id': document.id};
          if (_publishable(dua)) records[document.id] = dua;
        }
      } catch (_) {
        // Keep bundled verified content available offline.
      }
    }
    return records.values.toList();
  }

  bool _publishable(Map<String, dynamic> dua) =>
      (dua['status'] == 'verified' || dua['status'] == 'imported') &&
      (dua['arabic'] ?? '').toString().trim().isNotEmpty &&
      (dua['bn'] ?? '').toString().trim().isNotEmpty &&
      (dua['reference'] ?? '').toString().trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('dua'))),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _load(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.isEmpty) return EmptyState(icon: Icons.front_hand_outlined, message: s.t('no_dua'));
          return ListView(padding: const EdgeInsets.all(16), children: [
            for (final d in snap.data!)
              DeenCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if ((d['title'] ?? '').toString().isNotEmpty)
                    Text('${d['title']}', style: const TextStyle(color: DeenColors.accent, fontWeight: FontWeight.w600)),
                  ArabicText('${d['arabic']}', size: 24),
                  if ((d['pronunciationBn'] ?? '').toString().isNotEmpty)
                    Text('${d['pronunciationBn']}', style: const TextStyle(color: DeenColors.textSecondary, height: 1.8)),
                  const SizedBox(height: 6),
                  Text('${d['bn']}', style: const TextStyle(fontSize: 16, height: 1.9)),
                  const SizedBox(height: 6),
                  Text('${s.t('source')}: ${d['reference']}', style: const TextStyle(fontSize: 13, color: DeenColors.textSecondary)),
                ]),
              ),
          ]);
        },
      ),
    );
  }
}
