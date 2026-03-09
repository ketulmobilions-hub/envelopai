import 'package:envelope/features/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'routes.dart';

// ---------------------------------------------------------------------------
// Navigator keys
// ---------------------------------------------------------------------------

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _budgetNavKey = GlobalKey<NavigatorState>(debugLabel: 'budget');
final _accountsNavKey = GlobalKey<NavigatorState>(debugLabel: 'accounts');
final _reportsNavKey = GlobalKey<NavigatorState>(debugLabel: 'reports');

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: _Paths.budget,

  routes: [
    // ---- Stateful shell: bottom nav tabs with independent nav stacks ----
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _ScaffoldWithBottomNav(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _budgetNavKey,
          routes: [
            GoRoute(
              path: _Paths.budget,
              name: AppRoutes.budget,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: BudgetPage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _accountsNavKey,
          routes: [
            GoRoute(
              path: _Paths.accounts,
              name: AppRoutes.accounts,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: _PlaceholderScreen(title: 'Accounts'),
              ),
              routes: [
                GoRoute(
                  path: _Paths.accountDetail,
                  name: AppRoutes.accountDetail,
                  builder: (context, state) => _PlaceholderScreen(
                    title:
                        'Account: ${state.pathParameters[AppRouteParams.id]}',
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _reportsNavKey,
          routes: [
            GoRoute(
              path: _Paths.reports,
              name: AppRoutes.reports,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: _PlaceholderScreen(title: 'Reports'),
              ),
            ),
          ],
        ),
      ],
    ),

    // ---- Full-screen routes (presented over the shell) ----
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: _Paths.addTransaction,
      name: AppRoutes.addTransaction,
      builder: (context, state) =>
          const _PlaceholderScreen(title: 'Add Transaction'),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: _Paths.editTransaction,
      name: AppRoutes.editTransaction,
      builder: (context, state) => _PlaceholderScreen(
        title: 'Edit Transaction: ${state.pathParameters[AppRouteParams.id]}',
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: _Paths.goals,
      name: AppRoutes.goals,
      builder: (context, state) => const _PlaceholderScreen(title: 'Goals'),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: _Paths.settings,
      name: AppRoutes.settings,
      builder: (context, state) =>
          const _PlaceholderScreen(title: 'Settings'),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: _Paths.onboarding,
      name: AppRoutes.onboarding,
      builder: (context, state) =>
          const _PlaceholderScreen(title: 'Onboarding'),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: _Paths.aiAssistant,
      name: AppRoutes.aiAssistant,
      builder: (context, state) =>
          const _PlaceholderScreen(title: 'AI Assistant'),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: _Paths.auth,
      name: AppRoutes.auth,
      builder: (context, state) => const _PlaceholderScreen(title: 'Sign In'),
    ),
  ],
);

// ---------------------------------------------------------------------------
// Bottom nav shell scaffold
// ---------------------------------------------------------------------------

/// Tab definition — single source of truth for label, icons, and route name.
/// Adding/reordering a tab only requires changing this list.
typedef _Tab = ({
  String name,
  IconData icon,
  IconData activeIcon,
  String label,
});

const _tabs = <_Tab>[
  (
    name: AppRoutes.budget,
    icon: Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet,
    label: 'Budget',
  ),
  (
    name: AppRoutes.accounts,
    icon: Icons.credit_card_outlined,
    activeIcon: Icons.credit_card,
    label: 'Accounts',
  ),
  (
    name: AppRoutes.reports,
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart,
    label: 'Reports',
  ),
];

class _ScaffoldWithBottomNav extends StatelessWidget {
  const _ScaffoldWithBottomNav({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Switches to [index] tab.
  /// When tapping the already-active tab, pops to the tab root (pop-to-root).
  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _goBranch,
        items: _tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                activeIcon: Icon(tab.activeIcon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder screen (replaced per feature issue)
// ---------------------------------------------------------------------------

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
