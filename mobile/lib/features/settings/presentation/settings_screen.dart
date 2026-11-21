import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../notifications/presentation/notification_settings_screen.dart';
import 'prayer_settings_screen.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final st = context.watch<SettingsController>();
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(title: Text(s.t('settings'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SectionTitle(s.t('profile')),
        DeenCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(auth.user?.name?.isNotEmpty == true ? auth.user!.name! : s.t('guest'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            if (auth.user?.email != null) Text(auth.user!.email!, style: const TextStyle(color: DeenColors.textSecondary)),
            if (auth.role != 'user') Text('Role: ${auth.role}', style: const TextStyle(color: DeenColors.accent)),
            if (auth.user != null) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                OutlinedButton(
                  onPressed: () async {
                    final c = TextEditingController(text: auth.user?.name ?? '');
                    final v = await showDialog<String>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(s.t('name')),
                        content: TextField(controller: c),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.t('cancel'))),
                          TextButton(onPressed: () => Navigator.pop(context, c.text), child: Text(s.t('save'))),
                        ],
                      ),
                    );
                    if (v != null && v.trim().isNotEmpty) await auth.updateName(v);
                  },
                  child: Text(s.t('name')),
                ),
                OutlinedButton(onPressed: () => auth.signOut(), child: Text(s.t('logout'))),
              ]),
            ] else if (auth.available)
              TextButton(onPressed: () => st.setGuest(false), child: Text(s.t('login'))),
          ]),
        ),
        SectionTitle(s.t('language')),
        DeenCard(
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'bn', label: Text('বাংলা')),
              ButtonSegment(value: 'en', label: Text('English')),
              ButtonSegment(value: 'ar', label: Text('العربية')),
            ],
            selected: {st.lang},
            onSelectionChanged: (v) => st.setLang(v.first),
          ),
        ),
        SectionTitle(s.t('font_size')),
        DeenCard(
          child: Slider(
            value: st.fontScale,
            min: 0.85,
            max: 1.4,
            divisions: 11,
            activeColor: DeenColors.accent,
            onChanged: (v) => st.setFontScale(v),
          ),
        ),
        DeenCard(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerSettingsScreen())),
          child: Row(children: [const Icon(Icons.schedule), const SizedBox(width: 12), Expanded(child: Text(s.t('prayer'))), const Icon(Icons.chevron_right)]),
        ),
        DeenCard(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
          child: Row(children: [const Icon(Icons.notifications_none), const SizedBox(width: 12), Expanded(child: Text(s.t('notifications'))), const Icon(Icons.chevron_right)]),
        ),
        if (auth.user != null) ...[
          const SizedBox(height: 24),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(s.t('delete_account')),
                  content: Text(s.t('delete_confirm')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.t('cancel'))),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: Text(s.t('delete'))),
                  ],
                ),
              );
              if (ok == true) {
                final done = await auth.deleteAccount();
                if (!done && context.mounted) showMsg(context, auth.error ?? s.t('error_generic'));
              }
            },
            child: Text(s.t('delete_account')),
          ),
        ],
      ]),
    );
  }
}
