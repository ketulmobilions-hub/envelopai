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
  BudgetBloc(this._budgetRepository) : super(const BudgetInitial()) {
    on<BudgetMonthChanged>(
      _onMonthChanged,
      transformer: restartable(),
    );
  }

  final IBudgetRepository _budgetRepository;

  Future<void> _onMonthChanged(
    BudgetMonthChanged event,
    Emitter<BudgetState> emit,
  ) async {
    emit(const BudgetLoading());
    await emit.forEach<({List<BudgetEntry> entries, int tbb})>(
      _budgetRepository.watchMonthSummary(event.month, event.year),
      onData: (data) => BudgetLoaded(
        entries: data.entries,
        tbb: data.tbb,
        month: event.month,
        year: event.year,
      ),
      onError: (error, _) => BudgetError(message: error.toString()),
    );
  }
}
