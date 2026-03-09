import 'package:envelope/app/app.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:envelope/features/accounts/accounts.dart';
import 'package:envelope/features/budget/budget.dart';
import 'package:envelope/injection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockIBudgetRepository extends Mock implements IBudgetRepository {}

class _MockICategoryGroupsRepository extends Mock
    implements ICategoryGroupsRepository {}

class _MockICategoriesRepository extends Mock
    implements ICategoriesRepository {}

class _MockIAccountsRepository extends Mock implements IAccountsRepository {}

class _MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('App', () {
    late _MockIBudgetRepository mockBudgetRepo;
    late _MockICategoryGroupsRepository mockGroupsRepo;
    late _MockICategoriesRepository mockCategoriesRepo;
    late _MockIAccountsRepository mockAccountsRepo;

    setUp(() {
      mockBudgetRepo = _MockIBudgetRepository();
      mockGroupsRepo = _MockICategoryGroupsRepository();
      mockCategoriesRepo = _MockICategoriesRepository();
      mockAccountsRepo = _MockIAccountsRepository();
      final mockPrefs = _MockSharedPreferences();

      when(() => mockBudgetRepo.watchMonthSummary(any(), any())).thenAnswer(
        (_) => Stream.value((entries: <BudgetEntry>[], tbb: 0)),
      );
      when(() => mockBudgetRepo.rolloverMonth(any(), any()))
          .thenAnswer((_) async {});
      when(
        () => mockGroupsRepo.watchAll(),
      ).thenAnswer((_) => Stream.value(<CategoryGroup>[]));
      when(
        () => mockCategoriesRepo.watchAll(),
      ).thenAnswer((_) => Stream.value(<Category>[]));
      when(
        () => mockAccountsRepo.watchAll(),
      ).thenAnswer((_) => Stream.value(<Account>[]));
      when(() => mockPrefs.getBool(any())).thenReturn(false);
      when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

      getIt
        ..registerFactory<IBudgetRepository>(() => mockBudgetRepo)
        ..registerFactory<ICategoryGroupsRepository>(() => mockGroupsRepo)
        ..registerFactory<ICategoriesRepository>(() => mockCategoriesRepo)
        ..registerFactory<IAccountsRepository>(() => mockAccountsRepo)
        ..registerSingleton<SharedPreferences>(mockPrefs)
        ..registerFactory<BudgetBloc>(
          () => BudgetBloc(
            getIt<IBudgetRepository>(),
            getIt<ICategoryGroupsRepository>(),
            getIt<ICategoriesRepository>(),
            getIt<SharedPreferences>(),
          ),
        )
        ..registerFactory<AccountsBloc>(
          () => AccountsBloc(getIt<IAccountsRepository>()),
        );
    });

    tearDown(getIt.reset);

    testWidgets('renders budget screen on launch', (tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
      // 'Budget' appears in the bottom navigation bar label.
      expect(find.text('Budget'), findsWidgets);
    });
  });
}
