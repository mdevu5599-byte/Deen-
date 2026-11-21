import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../reminders/data/content_repository.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/notification_service.dart';
import '../domain/notification_prefs.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() => _State();
}

class _State extends State<NotificationSettingsScreen> {
  bool exact = true;

  @override
  void initState() {
    super.initState();
    NotificationService.canScheduleExact().then((v) {
      if (mounted) setState(() => exact = v);
    });
  }

  Future<void> _apply(SettingsController st) async {
    await st.saveNotif();
    if (!mounted) return;
    await NotificationService.rescheduleAll(st, context.read<ContentRepository>());
  }

  String _time(S s, ContentNotif c) {
    if (c.anchor != null) return s.t(c.anchor!);
    return '${s.n(c.hour.toString().padLeft(2, '0'))}:${s.n(c.minute.toString().padLeft(2, '0'))}';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final st = context.watch<SettingsController>();
    final n = st.notif;
    const contentLabels = {
      'hadith': 'hadith_notif',
      'akhirah': 'akhirah_notif',
      'reminder': 'reminder_notif',
      'evening_adhkar': 'evening_adhkar',
      'night': 'night_notif',
      'morning_adhkar': 'morning_adhkar',
      'quran': 'quran',
      'tawbah': 'tawbah',
    };
    String label(String k) {
      final key = contentLabels[k]!;
      const extra = {
        'evening_adhkar': {'bn': 'সন্ধ্যার আজকার', 'en': 'Evening Adhkar', 'ar': 'أذكار المساء'},
        'morning_adhkar': {'bn': 'সকালের আজকার', 'en': 'Morning Adhkar', 'ar': 'أذكار الصباح'},
        'quran': {'bn': 'কুরআন তিলাওয়াত', 'en': 'Quran reading', 'ar': 'تلاوة القرآن'},
        'tawbah': {'bn': 'তওবা ও ইস্তিগফার', 'en': 'Repentance', 'ar': 'التوبة والاستغفار'},
      };
      return extra[k]?[s.lang] ?? s.t(key);
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.t('notifications'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (!exact)
          DeenCard(
            color: DeenColors.sage,
            child: Row(children: [
              const Icon(Icons.alarm, color: DeenColors.warn),
              const SizedBox(width: 12),
              Expanded(child: Text(s.t('exact_alarm'))),
              TextButton(
                onPressed: () async {
                  await NotificationService.requestPermissions();
                  final v = await NotificationService.canScheduleExact();
                  if (mounted) setState(() => exact = v);
                },
                child: Text(s.t('enabled')),
              ),
            ]),
          ),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.notifications_active_outlined),
          label: Text(s.t('test_notification')),
          onPressed: () async {
            await NotificationService.requestPermissions();
            await NotificationService.sendTest(s.lang);
          },
        ),
        SectionTitle(s.t('prayer')),
        for (final p in prayerIds)
          DeenCard(
            child: Column(children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.t(p), style: const TextStyle(fontWeight: FontWeight.w600)),
                value: n.prayers[p]!.enabled,
                onChanged: (v) {
                  n.prayers[p]!.enabled = v;
                  _apply(st);
                },
              ),
              if (n.prayers[p]!.enabled) ...[
                Row(children: [
                  Expanded(child: Text(s.t('early'))),
                  DropdownButton<int>(
                    value: n.prayers[p]!.early,
                    items: [
                      for (final m in const [0, 5, 10, 15, 30])
                        DropdownMenuItem(value: m, child: Text(m == 0 ? s.t('off') : s.n(m))),
                    ],
                    onChanged: (v) {
                      n.prayers[p]!.early = v ?? 0;
                      _apply(st);
                    },
                  ),
                ]),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.t('vibration')),
                  value: n.prayers[p]!.vibrate,
                  onChanged: (v) {
                    n.prayers[p]!.vibrate = v;
                    _apply(st);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.t('sound')),
                  subtitle: kAdhanBundled ? null : const Text('Adhan audio file not bundled (see docs/NOTIFICATIONS.md)'),
                  value: n.prayers[p]!.adhan && kAdhanBundled,
                  onChanged: kAdhanBundled
                      ? (v) {
                          n.prayers[p]!.adhan = v;
                          _apply(st);
                        }
                      : null,
                ),
              ],
            ]),
          ),
        SectionTitle(s.t('daily_reminder')),
        for (final k in n.content.keys)
          DeenCard(
            child: Row(children: [
              Expanded(child: Text(label(k), style: const TextStyle(fontWeight: FontWeight.w500))),
              if (n.content[k]!.anchor == null)
                TextButton(
                  onPressed: () async {
                    final c = n.content[k]!;
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: c.hour, minute: c.minute));
                    if (t != null) {
                      c.hour = t.hour;
                      c.minute = t.minute;
                      _apply(st);
                    }
                  },
                  child: Text(_time(s, n.content[k]!)),
                )
              else
                Text(_time(s, n.content[k]!), style: const TextStyle(color: DeenColors.textSecondary)),
              Switch(
                value: n.content[k]!.enabled,
                onChanged: (v) {
                  n.content[k]!.enabled = v;
                  _apply(st);
                },
              ),
            ]),
          ),
        SectionTitle(s.t('quiet_hours')),
        DeenCard(
          child: Column(children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.t('quiet_hours')),
              value: n.quietEnabled,
              onChanged: (v) {
                n.quietEnabled = v;
                _apply(st);
              },
            ),
            if (n.quietEnabled)
              Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: TimeOfDay(hour: n.quietStart ~/ 60, minute: n.quietStart % 60));
                      if (t != null) {
                        n.quietStart = t.hour * 60 + t.minute;
                        _apply(st);
                      }
                    },
                    child: Text('${s.n((n.quietStart ~/ 60).toString().padLeft(2, '0'))}:${s.n((n.quietStart % 60).toString().padLeft(2, '0'))}'),
                  ),
                ),
                const Text('→'),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: TimeOfDay(hour: n.quietEnd ~/ 60, minute: n.quietEnd % 60));
                      if (t != null) {
                        n.quietEnd = t.hour * 60 + t.minute;
                        _apply(st);
                      }
                    },
                    child: Text('${s.n((n.quietEnd ~/ 60).toString().padLeft(2, '0'))}:${s.n((n.quietEnd % 60).toString().padLeft(2, '0'))}'),
                  ),
                ),
              ]),
            Row(children: [
              Expanded(child: Text(s.t('daily_limit'))),
              DropdownButton<int>(
                value: n.dailyLimit,
                items: [for (final v in const [2, 4, 6, 8, 12]) DropdownMenuItem(value: v, child: Text(s.n(v)))],
                onChanged: (v) {
                  n.dailyLimit = v ?? 8;
                  _apply(st);
                },
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
