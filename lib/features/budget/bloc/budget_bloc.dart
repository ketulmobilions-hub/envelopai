import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'budget_event.dart';
part 'budget_state.dart';

@injectable
class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  BudgetBloc(
    this._budgetRepository,
    this._categoryGroupsRepository,
    this._categoriesRepository,
  ) : super(const BudgetInitial()) {
    on<BudgetMonthChanged>(
      _onMonthChanged,
      transformer: restartable(),
    );
    on<BudgetEntryAllocated>(
      _onEntryAllocated,
      transformer: sequential(),
    );
  }

  final IBudgetRepository _budgetRepository;
  final ICategoryGroupsRepository _categoryGroupsRepository;
  final ICategoriesRepository _categoriesRepository;

  Future<void> _onMonthChanged(
    BudgetMonthChanged event,
    Emitter<BudgetState> emit,
  ) async {
    emit(const BudgetLoading());
    await emit.forEach<
        ({
          ({List<BudgetEntry> entries, int tbb}) summary,
          List<CategoryGroup> groups,
          List<Category> categories,
        })>(
      _combineLatest3(
        _budgetRepository.watchMonthSummary(event.month, event.year),
        _categoryGroupsRepository.watchAll(),
        _categoriesRepository.watchAll(),
      ),
      onData: (data) => BudgetLoaded(
        entries: data.summary.entries,
        tbb: data.summary.tbb,
        groups: data.groups,
        categories: data.categories,
        month: event.month,
        year: event.year,
      ),
      onError: (error, _) => BudgetError(message: error.toString()),
    );
  }

  Future<void> _onEntryAllocated(
    BudgetEntryAllocated event,
    Emitter<BudgetState> emit,
  ) async {
    // Guard against stale events that arrive after the user navigated to a
    // different month (e.g. rapid month switching + slow network).
    final current = state;
    if (current is BudgetLoaded &&
        (current.month != event.month || current.year != event.year)) {
      return;
    }
    await _budgetRepository.allocate(
      event.categoryId,
      event.month,
      event.year,
      event.budgeted,
    );
    // No emit needed — the active watchMonthSummary stream re-emits
    // automatically whenever the budget_entries table changes.
  }
}

/// Combines three streams, emitting a new record whenever any one updates,
/// using the latest value from each. Waits until all three have emitted at
/// least once before producing the first output.
///
/// Pause/resume signals from the returned stream are intentionally not
/// forwarded to the inner subscriptions. This is safe here because
/// [Emitter.forEach] in flutter_bloc never pauses the stream it listens to —
/// it only cancels on restartable event replacement or bloc close.
Stream<
    ({
      A summary,
      B groups,
      C categories,
    })>
    _combineLatest3<A, B, C>(
  Stream<A> streamA,
  Stream<B> streamB,
  Stream<C> streamC,
) {
  late StreamController<({A summary, B groups, C categories})> controller;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;
  StreamSubscription<C>? subC;

  var hasA = false;
  var hasB = false;
  var hasC = false;
  late A latestA;
  late B latestB;
  late C latestC;

  void tryEmit() {
    if (hasA && hasB && hasC) {
      controller.add((summary: latestA, groups: latestB, categories: latestC));
    }
  }

  controller = StreamController(
    onListen: () {
      subA = streamA.listen(
        (v) {
          latestA = v;
          hasA = true;
          tryEmit();
        },
        onError: controller.addError,
      );
      subB = streamB.listen(
        (v) {
          latestB = v;
          hasB = true;
          tryEmit();
        },
        onError: controller.addError,
      );
      subC = streamC.listen(
        (v) {
          latestC = v;
          hasC = true;
          tryEmit();
        },
        onError: controller.addError,
      );
    },
    onCancel: () {
      unawaited(subA?.cancel());
      unawaited(subB?.cancel());
      unawaited(subC?.cancel());
    },
  );

  return controller.stream;
}
