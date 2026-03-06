part of 'app_router.dart';

/// Centralized route path constants.
abstract final class AppRoutes {
  static const String budget = '/';
  static const String accounts = '/accounts';
  static const String reports = '/reports';
  static const String addTransaction = '/transactions/add';
  static const String editTransaction = '/transactions/:id/edit';
  static const String goals = '/goals';
  static const String settings = '/settings';
  static const String onboarding = '/onboarding';
  static const String aiAssistant = '/ai-assistant';
  static const String auth = '/auth';
}
