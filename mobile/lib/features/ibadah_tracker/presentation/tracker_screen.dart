import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/ibadah_repository.dart';

const _labels = {
  'quran': {'bn': 'কুরআন তিলাওয়াত', 'en': 'Quran reading', 'ar': 'تلاوة القرآن'},
  'morning_adhkar': {'bn': 'সকালের আজকার', 'en': 'Morning Adhkar', 'ar': 'أذكار الصباح'},
  'evening_adhkar': {'bn': 'সন্ধ্যার আজকার', 'en': 'Evening Adhkar', 'ar': 'أذكار المساء'},
  'istighfar': {'bn': 'ইস্তিগফার', 'en': 'Istighfar', 'ar': 'الاستغفار'},
  'good_deeds': {'bn': 'ভালো কাজ', 'en': 'Good deeds', 'ar': 'أعمال صالحة'},
  'charity': {'bn': 'দান-সদকা', 'en': 'Charity', 'ar': 'الصدقة'},
};

class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final repo = context.watch<IbadahRepository>();
    final now = DateTime.now();
    final today = repo.forDay(now);
    String name(String k) => _labels[k]?[s.lang] ?? s.t(k);
    final week = repo.totals(7);
    final month = repo.totals(30);

    Widget report(String title, Map<String, int> t, int days) => DeenCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final k in ibadahItems)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  SizedBox(width: 110, child: Text(name(k), style: const TextStyle(fontSize: 13))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: t[k]! / days, minHeight: 8, backgroundColor: DeenColors.sage, color: DeenColors.accent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${s.n(t[k]!)}/${s.n(days)}', style: const TextStyle(fontSize: 12, color: DeenColors.textSecondary)),
                ]),
              ),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: Text(s.t('tracker'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SectionTitle(s.t('today')),
        DeenCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(children: [
            for (final k in ibadahItems)
              CheckboxListTile(
                activeColor: DeenColors.accent,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(name(k)),
                value: today[k] == true,
                onChanged: (v) => repo.set(now, k, v ?? false),
              ),
          ]),
        ),
        DeenCard(
          color: DeenColors.sage,
          child: Text('${s.n(repo.prayerConsistency(7))} / ${s.n(7)}  ${s.t('prayer')}', style: const TextStyle(fontSize: 16)),
        ),
        SectionTitle(s.t('week')),
        report(s.t('week'), week, 7),
        SectionTitle(s.t('month')),
        report(s.t('month'), month, 30),
      ]),
    );
  }
}
