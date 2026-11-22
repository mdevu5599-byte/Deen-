import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/prefs.dart';
import 'features/authentication/presentation/auth_controller.dart';
import 'features/hadith/data/hadith_repository.dart';
import 'features/ibadah_tracker/data/ibadah_repository.dart';
import 'features/notifications/data/notification_service.dart';
import 'features/prayer_times/presentation/prayer_controller.dart';
import 'features/reminders/data/content_repository.dart';
import 'features/settings/presentation/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.init();
  await Fb.init();
  await NotificationService.init();

  final settings = SettingsController();
  final hadith = HadithRepository();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsController>.value(value: settings),
      ChangeNotifierProvider<AuthController>(
        create: (_) => AuthController(settings: settings),
      ),
      ChangeNotifierProvider<PrayerController>(create: (_) => PrayerController(settings)),
      ChangeNotifierProvider<IbadahRepository>(create: (_) => IbadahRepository()),
      Provider<HadithRepository>.value(value: hadith),
      Provider<ContentRepository>.value(value: ContentRepository(hadith)),
    ],
    child: const DeenApp(),
  ));
}
