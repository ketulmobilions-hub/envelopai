part of 'app_router.dart';

/// Route name constants — the single source of truth for navigation.
///
/// Always navigate with `context.goNamed` / `context.pushNamed` using these
/// names. Path strings are private and live only in [GoRoute] definitions.
///
/// For parameterised routes use [AppRouteParams] for the key names:
/// ```dart
/// context.goNamed(
///   AppRoutes.accountDetail,
///   pathParameters: {AppRouteParams.id: account.id},
/// );
/// ```
abstract final class AppRoutes {
  // ---- Shell tabs ----
  static const String budget = 'budget';
  static const String accounts = 'accounts';
  static const String reports = 'reports';

  // ---- Account detail (nested under accounts) ----
  static const String accountDetail = 'account-detail';

  // ---- Reconcile (nested under account detail) ----
  static const String reconcile = 'reconcile';

  // ---- Transactions ----
  static const String addTransaction = 'add-transaction';
  static const String editTransaction = 'edit-transaction';

  // ---- Other screens ----
  static const String goals = 'goals';
  static const String settings = 'settings';
  static const String onboarding = 'onboarding';
  static const String aiAssistant = 'ai-assistant';
  static const String auth = 'auth';
}

/// Path parameter key constants — used with [AppRoutes] named navigation.
abstract final class AppRouteParams {
  static const String id = 'id';
}

// ---------------------------------------------------------------------------
// Private path strings — ONLY referenced inside GoRoute(path: ...) below.
// Nothing outside this file should use these.
// ---------------------------------------------------------------------------
abstract final class _Paths {
  static const String budget = '/';
  static const String accounts = '/accounts';
  static const String accountDetail = ':id'; // relative, nested under accounts
  // relative, nested under accountDetail
  static const String reconcile = 'reconcile';
  static const String reports = '/reports';
  static const String addTransaction = '/transactions/add';
  static const String editTransaction = '/transactions/:id/edit';
  static const String goals = '/goals';
  static const String settings = '/settings';
  static const String onboarding = '/onboarding';
  static const String aiAssistant = '/ai-assistant';
  static const String auth = '/auth';
}
