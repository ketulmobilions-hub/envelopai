import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'routes.dart';

/// The top-level [GoRouter] for EnvelopAI.
///
/// Shell structure:
/// ```
/// /  (ShellRoute — bottom nav: Budget / Accounts / Reports)
///   /budget
///   /accounts
///   /accounts/:id
///   /reports
/// Outside shell:
///   /transactions/add
///   /transactions/:id/edit
///   /goals
///   /settings
///   /onboarding
///   /ai-assistant
///   /auth
/// ```
final appRouter = GoRouter(
  initialLocation: AppRoutes.budget,
  debugLogDiagnostics: false,
  routes: [
    ShellRoute(
      builder: (context, state, child) => _ScaffoldWithBottomNav(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.budget,
          name: 'budget',
          builder: (context, state) => const _PlaceholderScreen(title: 'Budget'),
        ),
        GoRoute(
          path: AppRoutes.accounts,
          name: 'accounts',
          builder: (context, state) => const _PlaceholderScreen(title: 'Accounts'),
          routes: [
            GoRoute(
              path: ':id',
              name: 'account-detail',
              builder: (context, state) => _PlaceholderScreen(
                title: 'Account: ${state.pathParameters['id']}',
              ),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.reports,
          name: 'reports',
          builder: (context, state) => const _PlaceholderScreen(title: 'Reports'),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.addTransaction,
      name: 'add-transaction',
      builder: (context, state) => const _PlaceholderScreen(title: 'Add Transaction'),
    ),
    GoRoute(
      path: AppRoutes.editTransaction,
      name: 'edit-transaction',
      builder: (context, state) => _PlaceholderScreen(
        title: 'Edit Transaction: ${state.pathParameters['id']}',
      ),
    ),
    GoRoute(
      path: AppRoutes.goals,
      name: 'goals',
      builder: (context, state) => const _PlaceholderScreen(title: 'Goals'),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => const _PlaceholderScreen(title: 'Settings'),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) => const _PlaceholderScreen(title: 'Onboarding'),
    ),
    GoRoute(
      path: AppRoutes.aiAssistant,
      name: 'ai-assistant',
      builder: (context, state) => const _PlaceholderScreen(title: 'AI Assistant'),
    ),
    GoRoute(
      path: AppRoutes.auth,
      name: 'auth',
      builder: (context, state) => const _PlaceholderScreen(title: 'Sign In'),
    ),
  ],
);

// ---------------------------------------------------------------------------
// Bottom nav shell
// ---------------------------------------------------------------------------

class _ScaffoldWithBottomNav extends StatelessWidget {
  const _ScaffoldWithBottomNav({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex(context),
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_outlined),
            activeIcon: Icon(Icons.credit_card),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.accounts)) return 1;
    if (location.startsWith(AppRoutes.reports)) return 2;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.budget);
      case 1:
        context.go(AppRoutes.accounts);
      case 2:
        context.go(AppRoutes.reports);
    }
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
