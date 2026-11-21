import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

/// Duas are loaded only from verified records (status == 'verified') that carry
/// Arabic text, Bengali meaning and a reference. See docs/CONTENT_VERIFICATION.md.
class DuaScreen extends StatelessWidget {
  const DuaScreen({super.key});

  Future<List<Map<String, dynamic>>> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/duas.json');
      return (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .where((d) => d['status'] == 'verified' && (d['arabic'] ?? '').toString().isNotEmpty && (d['bn'] ?? '').toString().isNotEmpty && (d['reference'] ?? '').toString().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

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
