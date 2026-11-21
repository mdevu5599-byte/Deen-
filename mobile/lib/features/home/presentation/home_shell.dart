import 'package:flutter/material.dart';
import '../../../core/l10n/app_strings.dart';
import '../../hadith/presentation/hadith_screen.dart';
import '../../prayer_times/presentation/prayer_screen.dart';
import '../../quran/presentation/quran_screen.dart';
import 'dashboard_screen.dart';
import 'more_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  static const _pages = [DashboardScreen(), PrayerScreen(), HadithScreen(), QuranScreen(), MoreScreen()];

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: s.t('home')),
          NavigationDestination(icon: const Icon(Icons.schedule_outlined), selectedIcon: const Icon(Icons.schedule), label: s.t('prayer')),
          NavigationDestination(icon: const Icon(Icons.auto_stories_outlined), selectedIcon: const Icon(Icons.auto_stories), label: s.t('hadith')),
          NavigationDestination(icon: const Icon(Icons.menu_book_outlined), selectedIcon: const Icon(Icons.menu_book), label: s.t('quran')),
          NavigationDestination(icon: const Icon(Icons.grid_view_outlined), selectedIcon: const Icon(Icons.grid_view), label: s.t('more')),
        ],
      ),
    );
  }
}
