import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/date_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../akhirah/presentation/akhirah_screen.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../duas/presentation/dua_screen.dart';
import '../../hadith/domain/hadith.dart';
import '../../hadith/presentation/hadith_screen.dart';
import '../../ibadah_tracker/data/ibadah_repository.dart';
import '../../notifications/presentation/notification_settings_screen.dart';
import '../../prayer_times/presentation/prayer_widgets.dart';
import '../../quran/presentation/quran_screen.dart';
import '../../reminders/data/content_repository.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../tasbih/presentation/tasbih_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final st = context.watch<SettingsController>();
    final user = context.watch<AuthController>().user;
    final content = context.read<ContentRepository>();
    final repo = context.watch<IbadahRepository>();
    final now = DateTime.now();
    final prog = repo.progress(now);

    Widget quick(IconData icon, String label, Widget page) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: DeenColors.sage, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Icon(icon, color: DeenColors.accent),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 13)),
              ]),
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('app_name'), style: const TextStyle(color: DeenColors.accent, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: s.t('notifications'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('${s.t('salam')}${user?.name != null && user!.name!.isNotEmpty ? ', ${user.name}' : ''}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(s.t('greeting_line'), style: const TextStyle(color: DeenColors.textSecondary, height: 1.7)),
        const SizedBox(height: 14),
        Text(gregorian(s, now), style: const TextStyle(height: 1.5)),
        Text(hijri(s, now, st.hijriOffset), style: const TextStyle(color: DeenColors.accent, height: 1.5)),
        Row(children: [
          const Icon(Icons.place_outlined, size: 16, color: DeenColors.textSecondary),
          const SizedBox(width: 4),
          Text(st.placeName, style: const TextStyle(color: DeenColors.textSecondary)),
        ]),
        const SizedBox(height: 14),
        const NextPrayerCard(),
        const PrayerList(showSunrise: false),
        SectionTitle(s.t('daily_hadith')),
        FutureBuilder<Hadith?>(
          future: content.hadithFor(now),
          builder: (_, snap) {
            final h = snap.data;
            if (h == null) {
              return DeenCard(color: DeenColors.sage, child: Text(s.t('no_verified'), style: const TextStyle(height: 1.7)));
            }
            return HadithCard(h: h, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HadithDetailScreen(h: h))));
          },
        ),
        SectionTitle(s.t('daily_reminder')),
        FutureBuilder<Reflection?>(
          future: content.reflectionFor('reminder', now),
          builder: (_, snap) {
            final r = snap.data;
            if (r == null) return const SizedBox.shrink();
            return DeenCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.bn, style: const TextStyle(fontSize: 16, height: 1.9)),
                const SizedBox(height: 8),
                Text(s.t('original_reflection'), style: const TextStyle(fontSize: 12, color: DeenColors.textSecondary)),
              ]),
            );
          },
        ),
        SectionTitle(s.t('remember_akhirah')),
        FutureBuilder<Reflection?>(
          future: content.reflectionFor('akhirah', now),
          builder: (_, snap) {
            final r = snap.data;
            return DeenCard(
              color: DeenColors.sage,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AkhirahScreen())),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r?.bn ?? s.t('akhirah'), style: const TextStyle(fontSize: 16, height: 1.9)),
                const SizedBox(height: 8),
                Text(s.t('akhirah'), style: const TextStyle(color: DeenColors.accent, fontWeight: FontWeight.w600)),
              ]),
            );
          },
        ),
        SectionTitle(s.t('ibadah_progress')),
        DeenCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: prog, minHeight: 10, backgroundColor: DeenColors.sage, color: DeenColors.accent),
            ),
            const SizedBox(height: 8),
            Text('${s.n(repo.doneCount(now))} / ${s.n(ibadahItems.length)}'),
          ]),
        ),
        const SizedBox(height: 4),
        Row(children: [
          quick(Icons.menu_book_outlined, s.t('quran'), const QuranScreen()),
          const SizedBox(width: 10),
          quick(Icons.touch_app_outlined, s.t('tasbih'), const TasbihScreen()),
          const SizedBox(width: 10),
          quick(Icons.front_hand_outlined, s.t('dua'), const DuaScreen()),
        ]),
        const SizedBox(height: 24),
      ]),
    );
  }
}
