import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/view/onboarding_page.dart';
import '../../features/capture/view/capture_page.dart';
import '../../features/history/view/history_page.dart';
import '../../features/history/view/history_detail_page.dart';
import '../../features/chart/view/chart_page.dart';
import '../../providers/profile_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final profileState = ref.watch(profileProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Wait until profile is loaded
      if (profileState.isLoading) return null;

      final hasProfile = profileState.value != null;
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';

      if (!hasProfile && !isGoingToOnboarding) {
        return '/onboarding';
      }

      if (hasProfile && isGoingToOnboarding) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: '/history/detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return HistoryDetailPage(entryId: id);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const CapturePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chart',
                builder: (context, state) => const ChartPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class MainLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.edit_note),
              activeIcon: Icon(Icons.edit_note, shadows: [
                Shadow(
                  color: Theme.of(context).primaryColor,
                  blurRadius: 12,
                )
              ]),
              label: 'Capture',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.auto_awesome),
              activeIcon: Icon(Icons.auto_awesome, shadows: [
                Shadow(
                  color: Theme.of(context).primaryColor,
                  blurRadius: 12,
                )
              ]),
              label: 'Chart',
            ),
          ],
        ),
      ),
    );
  }
}
