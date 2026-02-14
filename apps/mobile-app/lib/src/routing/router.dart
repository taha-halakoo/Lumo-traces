import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:traces_mobile/src/core/services/haptic_service.dart';
import 'package:traces_mobile/src/core/ui/glass.dart';
import 'package:traces_mobile/src/core/theme/design_tokens.dart';

import '../features/splash/presentation/splash_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/map/presentation/map_screen.dart';
import '../features/create_trace/presentation/create_trace_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/public_profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/trace_details/presentation/trace_details_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/social/presentation/friends_screen.dart';
import '../features/collections/presentation/collections_screen.dart';
import '../features/explorer/presentation/explorer_screen.dart';
import '../features/auth/presentation/complete_profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/leaderboard/presentation/leaderboard_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      // MAIN APP SHELL (Stateful)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            extendBody: true,
            bottomNavigationBar: _MainBottomNav(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explorer',
                builder: (context, state) => const ExplorerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/leaderboard',
                builder: (context, state) => const LeaderboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/trace/:id',
        builder: (context, state) => TraceDetailsScreen(traceId: state.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/profile/:userId',
        builder: (context, state) => PublicProfileScreen(userId: state.pathParameters['userId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/create-trace',
        builder: (context, state) => const CreateTraceScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/friends',
        builder: (context, state) => const FriendsScreen(),
      ),
    ],
  );
});

class _MainBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _MainBottomNav({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: GlassPanel.pill(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavItem(icon: Icons.map, label: "Map", isSelected: navigationShell.currentIndex == 0, onTap: () => navigationShell.goBranch(0)),
            _NavItem(icon: Icons.explore, label: "Explore", isSelected: navigationShell.currentIndex == 1, onTap: () => navigationShell.goBranch(1)),
            _NavItem(icon: Icons.add_circle_outline, label: "Drop", onTap: () => context.push('/create-trace')),
            _NavItem(icon: Icons.leaderboard, label: "Rank", isSelected: navigationShell.currentIndex == 2, onTap: () => navigationShell.goBranch(2)),
            _NavItem(icon: Icons.person, label: "Profile", isSelected: navigationShell.currentIndex == 3, onTap: () => navigationShell.goBranch(3)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, this.label, this.isSelected = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.white : Colors.white30, size: 24).animate(target: isSelected ? 1 : 0).scale(end: const Offset(1.2, 1.2)),
          if (label != null) Text(label!, style: TextStyle(color: isSelected ? Colors.white : Colors.white30, fontSize: 10)),
        ],
      ),
    );
  }
}
