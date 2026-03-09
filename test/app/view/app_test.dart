import 'package:envelope/app/app.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:envelope/features/budget/budget.dart';
import 'package:envelope/injection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockIBudgetRepository extends Mock implements IBudgetRepository {}

class _MockICategoryGroupsRepository extends Mock
    implements ICategoryGroupsRepository {}

class _MockICategoriesRepository extends Mock
    implements ICategoriesRepository {}

void main() {
  group('App', () {
    late _MockIBudgetRepository mockBudgetRepo;
    late _MockICategoryGroupsRepository mockGroupsRepo;
    late _MockICategoriesRepository mockCategoriesRepo;

    setUp(() {
      mockBudgetRepo = _MockIBudgetRepository();
      mockGroupsRepo = _MockICategoryGroupsRepository();
      mockCategoriesRepo = _MockICategoriesRepository();

      when(() => mockBudgetRepo.watchMonthSummary(any(), any())).thenAnswer(
        (_) => Stream.value((entries: <BudgetEntry>[], tbb: 0)),
      );
      when(
        () => mockGroupsRepo.watchAll(),
      ).thenAnswer((_) => Stream.value(<CategoryGroup>[]));
      when(
        () => mockCategoriesRepo.watchAll(),
      ).thenAnswer((_) => Stream.value(<Category>[]));

      getIt
        ..registerFactory<IBudgetRepository>(() => mockBudgetRepo)
        ..registerFactory<ICategoryGroupsRepository>(() => mockGroupsRepo)
        ..registerFactory<ICategoriesRepository>(() => mockCategoriesRepo)
        ..registerFactory<BudgetBloc>(
          () => BudgetBloc(
            getIt<IBudgetRepository>(),
            getIt<ICategoryGroupsRepository>(),
            getIt<ICategoriesRepository>(),
          ),
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
