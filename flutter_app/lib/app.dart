import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/missions/missions_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/programs/programs_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/rank/rank_screen.dart';
import 'features/shop/shop_screen.dart';
import 'features/social/social_screen.dart';
import 'features/workouts/workout_screen.dart';
import 'services/health_connection_service.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const ShellScreen()),
    GoRoute(path: '/workout', builder: (_, __) => const WorkoutScreen()),
    GoRoute(path: '/program', builder: (_, __) => const ProgramsScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/social', builder: (_, __) => const SocialScreen()),
    GoRoute(path: '/shop', builder: (_, __) => const ShopScreen()),
  ],
);

class ConsistiFitApp extends StatelessWidget {
  const ConsistiFitApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'ConsistiFit',
        theme: AppTheme.dark,
        routerConfig: _router,
      );
}

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> with WidgetsBindingObserver {
  int index = 0;
  final HealthConnectionService health = HealthConnectionService();
  final pages = const [
    HomeScreen(),
    MissionsScreen(),
    RankScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_syncHealth());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_syncHealth());
  }

  Future<void> _syncHealth() async {
    try {
      await health.syncIfConnected();
    } catch (_) {
      // Keep the app usable if Health is unavailable or temporarily fails.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: pages[index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) {
            setState(() => index = value);
            if (value == 1) unawaited(_syncHealth());
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.checklist), label: 'Missions'),
            NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Rank'),
            NavigationDestination(icon: Icon(Icons.insights), label: 'Progress'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      );
}
