import 'dart:async';

import 'package:aoc_core/aoc_core.dart' hide immutable;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

@immutable
class GridState<T> {
  final Grid<T> grid;
  final String Function(T)? itemToString;

  const GridState(this.grid, this.itemToString);
}

@immutable
class VisualizationState {
  final List<GridState<Object?>> gridStates;

  const VisualizationState({required this.gridStates});

  VisualizationState addState(GridState<Object?> state) {
    return VisualizationState(
      gridStates: List.unmodifiable([...gridStates, state]),
    );
  }

  VisualizationState updateGridState({
    required int index,
    required GridState state,
  }) {
    final gridStates = this.gridStates.toList(growable: false);
    gridStates[index] = state;
    return VisualizationState(gridStates: List.unmodifiable(gridStates));
  }
}

@immutable
sealed class VisualizationEvent {
  const VisualizationEvent();
}

@immutable
final class _RegisterGridVisualizer<T> extends VisualizationEvent {
  final _GridVisualizer<T> visualizer;
  final GridState<T> gridState;

  const _RegisterGridVisualizer(this.visualizer, this.gridState);
}

@immutable
final class _UpdateGridState<T> extends VisualizationEvent {
  final int index;
  final GridState<T> gridState;

  const _UpdateGridState({required this.index, required this.gridState});
}

@immutable
final class ResetVisualization extends VisualizationEvent {
  const ResetVisualization();
}

final class _GridVisualizer<I> implements Visualizer<Grid<I>> {
  final String Function(I)? _itemToString;
  final StreamController<GridState<I>> _controller;

  _GridVisualizer(GridState<I> gridState)
    : _itemToString = gridState.itemToString,
      _controller = StreamController() {
    _controller.add(gridState);
  }

  void initialize(void Function(GridState<I>) update) {
    _controller.stream.listen(update);
  }

  @override
  Future<void> update(Grid<I> state) async {
    _controller.add(GridState(state, _itemToString));
  }
}

final class VisualizationBloc
    extends Bloc<VisualizationEvent, VisualizationState>
    implements Visualization {
  VisualizationBloc() : super(const VisualizationState(gridStates: [])) {
    on<_RegisterGridVisualizer>(_registerGridVisualizer);
    on<_UpdateGridState>(_updateGridState);
    on<ResetVisualization>(_reset);
  }

  Future<void> _reset(
    ResetVisualization event,
    Emitter<VisualizationState> emit,
  ) async {
    emit(VisualizationState(gridStates: const []));
  }

  Future<void> _updateGridState<I>(
    _UpdateGridState<I> event,
    Emitter<VisualizationState> emit,
  ) async {
    emit(state.updateGridState(index: event.index, state: event.gridState));
  }

  Future<void> _registerGridVisualizer<I>(
    _RegisterGridVisualizer<I> event,
    Emitter<VisualizationState> emit,
  ) async {
    final newState = state.addState(event.gridState);
    emit(newState);
    final index = newState.gridStates.length - 1;
    event.visualizer.initialize(
      (s) => add(_UpdateGridState(index: index, gridState: s)),
    );
  }

  @override
  Future<Visualizer<Grid<I>>> createGridVisualizer<I>(
    Grid<I> grid, [
    String Function(I)? itemToString,
  ]) async {
    final gridState = GridState(grid, itemToString);
    final visualizer = _GridVisualizer(gridState);
    add(_RegisterGridVisualizer(visualizer, gridState));
    return visualizer;
  }
}
