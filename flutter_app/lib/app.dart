import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';
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

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const AuthGate()),
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

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Env.hasSupabase) return const ShellScreen();
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) =>
          Supabase.instance.client.auth.currentSession == null
              ? const AuthScreen()
              : const ShellScreen(),
    );
  }
}

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int index = 0;
  final pages = const [
    HomeScreen(),
    MissionsScreen(),
    RankScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: pages[index],
        floatingActionButton: index == 0
            ? FloatingActionButton.extended(
                onPressed: () => context.push('/workout'),
                label: const Text('Start workout'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(icon: Icon(Icons.checklist), label: 'Missions'),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              label: 'Rank',
            ),
            NavigationDestination(icon: Icon(Icons.insights), label: 'Progress'),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      );
}
