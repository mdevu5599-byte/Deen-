import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/widgets.dart';
import '../../notifications/data/notification_service.dart';
import '../../prayer_times/data/location_service.dart';
import '../../prayer_times/data/prayer_calculator.dart';
import '../../reminders/data/content_repository.dart';
import '../../notifications/domain/notification_prefs.dart';
import 'settings_controller.dart';

class PrayerSettingsScreen extends StatelessWidget {
  const PrayerSettingsScreen({super.key});

  Future<void> _resched(BuildContext c) async {
    final st = c.read<SettingsController>();
    await NotificationService.rescheduleAll(st, c.read<ContentRepository>());
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final st = context.watch<SettingsController>();
    return Scaffold(
      appBar: AppBar(title: Text(s.t('prayer'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SectionTitle(s.t('location')),
        DeenCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(st.placeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.my_location),
              label: Text(s.t('auto_location')),
              onPressed: () async {
                final p = await LocationService.detect();
                if (!context.mounted) return;
                if (p == null) {
                  showMsg(context, s.t('error_generic'));
                  return;
                }
                await st.setLocation(p.latitude, p.longitude,
                    '${s.n(p.latitude.toStringAsFixed(2))}, ${s.n(p.longitude.toStringAsFixed(2))}', auto: true);
                if (context.mounted) await _resched(context);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<City>(
              decoration: InputDecoration(labelText: s.t('choose_city')),
              items: [
                for (final c in cities)
                  DropdownMenuItem(value: c, child: Text(s.lang == 'en' ? c.en : c.bn)),
              ],
              onChanged: (c) async {
                if (c == null) return;
                await st.setLocation(c.lat, c.lng, s.lang == 'en' ? c.en : c.bn);
                if (context.mounted) await _resched(context);
              },
            ),
          ]),
        ),
        SectionTitle(s.t('method')),
        DeenCard(
          child: DropdownButtonFormField<String>(
            value: st.method,
            isExpanded: true,
            items: [
              for (final e in calculationMethods.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) async {
              if (v == null) return;
              await st.setMethod(v);
              if (context.mounted) await _resched(context);
            },
          ),
        ),
        SectionTitle(s.t('asr_method')),
        DeenCard(
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'hanafi', label: Text(s.t('hanafi'))),
              ButtonSegment(value: 'shafi', label: Text(s.t('shafi'), overflow: TextOverflow.ellipsis)),
            ],
            selected: {st.madhab},
            onSelectionChanged: (v) async {
              await st.setMadhab(v.first);
              if (context.mounted) await _resched(context);
            },
          ),
        ),
        SectionTitle(s.t('adjust')),
        DeenCard(
          child: Column(children: [
            for (final p in prayerIds)
              Row(children: [
                Expanded(child: Text(s.t(p))),
                IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () async {
                      await st.setAdjust(p, (st.adjust[p] ?? 0) - 1);
                      if (context.mounted) await _resched(context);
                    }),
                SizedBox(width: 36, child: Text(s.n(st.adjust[p] ?? 0), textAlign: TextAlign.center)),
                IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () async {
                      await st.setAdjust(p, (st.adjust[p] ?? 0) + 1);
                      if (context.mounted) await _resched(context);
                    }),
              ]),
          ]),
        ),
        SectionTitle(s.t('hijri_offset')),
        DeenCard(
          child: Row(children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => st.setHijriOffset(st.hijriOffset - 1)),
            Expanded(child: Text(s.n(st.hijriOffset), textAlign: TextAlign.center)),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => st.setHijriOffset(st.hijriOffset + 1)),
          ]),
        ),
      ]),
    );
  }
}
