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
}

/// Combines three streams, emitting a new record whenever any one updates,
/// using the latest value from each. Waits until all three have emitted at
/// least once before producing the first output.
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
