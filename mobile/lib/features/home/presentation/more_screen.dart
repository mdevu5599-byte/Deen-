import 'package:flutter/material.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../akhirah/presentation/akhirah_screen.dart';
import '../../duas/presentation/dua_screen.dart';
import '../../ibadah_tracker/presentation/tracker_screen.dart';
import '../../journal/presentation/journal_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../tasbih/presentation/tasbih_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    Widget tile(IconData i, String t, Widget p) => DeenCard(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => p)),
          child: Row(children: [
            Icon(i, color: DeenColors.accent),
            const SizedBox(width: 14),
            Expanded(child: Text(t, style: const TextStyle(fontSize: 16))),
            const Icon(Icons.chevron_right, color: DeenColors.textSecondary),
          ]),
        );
    return Scaffold(
      appBar: AppBar(title: Text(s.t('more'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        tile(Icons.hourglass_bottom, s.t('akhirah'), const AkhirahScreen()),
        tile(Icons.checklist, s.t('tracker'), const TrackerScreen()),
        tile(Icons.touch_app_outlined, s.t('tasbih'), const TasbihScreen()),
        tile(Icons.front_hand_outlined, s.t('dua'), const DuaScreen()),
        tile(Icons.edit_note, s.t('self_review'), const JournalScreen()),
        tile(Icons.lock_outline, s.t('journal'), const JournalScreen()),
        tile(Icons.settings_outlined, s.t('settings'), const SettingsScreen()),
      ]),
    );
  }
}
