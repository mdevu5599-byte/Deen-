import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../reminders/data/content_repository.dart';

/// "মৃত্যুকে স্মরণ করুন" - original reflections, clearly labelled as not being
/// Hadith or Quran quotations. Balances accountability with hope in Allah's mercy.
class AkhirahScreen extends StatelessWidget {
  const AkhirahScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final repo = context.read<ContentRepository>();
    return Scaffold(
      appBar: AppBar(title: Text(s.t('akhirah'))),
      body: FutureBuilder<List<Reflection>>(
        future: Future.wait([repo.reflections('akhirah'), repo.reflections('tawbah')]).then((l) => [...l[0], ...l[1]]),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) return EmptyState(icon: Icons.hourglass_empty, message: s.t('error_generic'));
          return ListView(padding: const EdgeInsets.all(16), children: [
            for (final r in list)
              DeenCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.category, style: const TextStyle(color: DeenColors.accent, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(r.bn, style: const TextStyle(fontSize: 17, height: 1.9)),
                  if (r.lessonBn.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('${s.t('lesson')}: ${r.lessonBn}', style: const TextStyle(color: DeenColors.textSecondary, height: 1.7)),
                  ],
                  const SizedBox(height: 8),
                  Text(s.t('original_reflection'), style: const TextStyle(fontSize: 12, color: DeenColors.textSecondary)),
                ]),
              ),
          ]);
        },
      ),
    );
  }
}
