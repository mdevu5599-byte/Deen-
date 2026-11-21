import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/presentation/auth_controller.dart';
import 'features/authentication/presentation/auth_screens.dart';
import 'features/home/presentation/home_shell.dart';
import 'features/notifications/data/notification_service.dart';
import 'features/reminders/data/content_repository.dart';
import 'features/settings/presentation/settings_controller.dart';

class DeenApp extends StatefulWidget {
  const DeenApp({super.key});
  @override
  State<DeenApp> createState() => _DeenAppState();
}

class _DeenAppState extends State<DeenApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reschedule());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Rebuilds the local notification schedule on launch and every resume. This
  /// covers date, timezone and location changes and a restarted device.
  Future<void> _reschedule() async {
    if (!mounted) return;
    final st = context.read<SettingsController>();
    final content = context.read<ContentRepository>();
    try {
      await NotificationService.requestPermissions();
      await NotificationService.rescheduleAll(st, content);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reschedule();
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<SettingsController>();
    final auth = context.watch<AuthController>();
    final loggedIn = auth.user != null || st.guestMode;
    return MaterialApp(
      title: 'DEEN',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(st.lang),
      locale: Locale(st.lang),
      supportedLocales: const [Locale('bn'), Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(st.fontScale)),
        child: child!,
      ),
      home: loggedIn ? const HomeShell() : const AuthScreen(),
    );
  }
}
