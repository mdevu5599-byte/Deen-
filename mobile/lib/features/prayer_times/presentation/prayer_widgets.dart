import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/date_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../ibadah_tracker/data/ibadah_repository.dart';
import 'prayer_controller.dart';

class NextPrayerCard extends StatelessWidget {
  const NextPrayerCard({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final pc = context.watch<PrayerController>();
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (_, __) {
        final n = pc.next();
        final left = n.value.difference(DateTime.now());
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: DeenColors.accent, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.t('next_prayer'), style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text('${s.t(n.key)}  ·  ${clock(s, n.value)}',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(countdown(s, left),
                style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w300, letterSpacing: 1)),
            Text(s.t('remaining'), style: const TextStyle(color: Colors.white70)),
          ]),
        );
      },
    );
  }
}

class PrayerList extends StatelessWidget {
  final bool showSunrise;
  const PrayerList({super.key, this.showSunrise = true});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final pc = context.watch<PrayerController>();
    final repo = context.watch<IbadahRepository>();
    final done = repo.forDay(DateTime.now());
    final next = pc.next().key;
    Widget row(String id, DateTime t, {bool tick = true}) {
      final isNext = id == next;
      return Container(
        decoration: BoxDecoration(
            color: isNext ? DeenColors.sage : null, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [
          Expanded(
              child: Text(s.t(id),
                  style: TextStyle(fontSize: 16, fontWeight: isNext ? FontWeight.w600 : FontWeight.w400))),
          Text(clock(s, t), style: const TextStyle(fontSize: 16)),
          if (tick)
            IconButton(
              tooltip: s.t('mark_done'),
              icon: Icon(done[id] == true ? Icons.check_circle : Icons.circle_outlined,
                  color: done[id] == true ? DeenColors.accent : DeenColors.textSecondary),
              onPressed: () => repo.set(DateTime.now(), id, !(done[id] == true)),
            )
          else
            const SizedBox(width: 48),
        ]),
      );
    }

    final d = pc.today;
    return DeenCard(
      padding: const EdgeInsets.all(8),
      child: Column(children: [
        row('fajr', d.fajr),
        if (showSunrise) row('sunrise', d.sunrise, tick: false),
        row('dhuhr', d.dhuhr),
        row('asr', d.asr),
        row('maghrib', d.maghrib),
        row('isha', d.isha),
      ]),
    );
  }
}
