import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/date_utils.dart';
import '../../notifications/presentation/notification_settings_screen.dart';
import '../../settings/presentation/prayer_settings_screen.dart';
import '../../settings/presentation/settings_controller.dart';
import 'prayer_widgets.dart';

class PrayerScreen extends StatelessWidget {
  const PrayerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final st = context.watch<SettingsController>();
    return Scaffold(
      appBar: AppBar(title: Text(s.t('prayer')), actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerSettingsScreen())),
        ),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('${gregorian(s, DateTime.now())}\n${hijri(s, DateTime.now(), st.hijriOffset)}',
            style: const TextStyle(height: 1.6)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.place_outlined, size: 16),
          const SizedBox(width: 4),
          Text(st.placeName),
        ]),
        const SizedBox(height: 12),
        const NextPrayerCard(),
        const PrayerList(),
      ]),
    );
  }
}
