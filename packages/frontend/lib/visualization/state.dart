import 'dart:async';

import 'package:aoc_core/aoc_core.dart' hide immutable;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

@immutable
class GridState<T> {
  final Grid<T> grid;
  final Progress? progress;
  final String? stepInfo;
  final String Function(T)? itemToString;

  const GridState(
    this.grid,
    this.itemToString, {
    required this.progress,
    required this.stepInfo,
  });
}

@immutable
class VisualizationState {
  final Duration frameDuration;
  final List<GridState<Object?>> gridStates;

  const VisualizationState({
    required this.frameDuration,
    required this.gridStates,
  });

  VisualizationState addState(GridState<Object?> state) {
    return VisualizationState(
      frameDuration: frameDuration,
      gridStates: List.unmodifiable([...gridStates, state]),
    );
  }

  VisualizationState updateGridState({
    required int index,
    required GridState state,
  }) {
    final gridStates = this.gridStates.toList(growable: false);
    gridStates[index] = state;
    return VisualizationState(
      frameDuration: frameDuration,
      gridStates: List.unmodifiable(gridStates),
    );
  }

  VisualizationState updateFrameDuration(Duration frameDuration) {
    return VisualizationState(
      frameDuration: frameDuration,
      gridStates: gridStates,
    );
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

@immutable
final class SetFrameDuration extends VisualizationEvent {
  final Duration duration;

  const SetFrameDuration(this.duration);
}

final class _GridVisualizer<I> implements Visualizer<Grid<I>> {
  late final StreamSubscription<GridState<I>> _sub;
  final String Function(I)? _itemToString;
  final Duration Function() _getFrameDuration;
  final StreamController<GridState<I>> _controller;

  _GridVisualizer(
    GridState<I> gridState, {
    required Duration Function() getFrameDuration,
  }) : _itemToString = gridState.itemToString,
       _getFrameDuration = getFrameDuration,
       _controller = StreamController() {
    _controller.add(gridState);
  }

  void initialize(void Function(GridState<I>) update) {
    _sub = _controller.stream.listen(update);
  }

  Future<void> dispose() {
    return _sub.cancel();
  }

  @override
  Future<void> update(
    Grid<I> state, {
    String? stepInfo,
    Progress? progress,
  }) async {
    _controller.add(
      GridState(state, _itemToString, stepInfo: stepInfo, progress: progress),
    );
    await Future.delayed(_getFrameDuration());
  }
}

final class VisualizationBloc
    extends Bloc<VisualizationEvent, VisualizationState>
    implements Visualization {
  final List<_GridVisualizer<Object?>> _visualizers;

  VisualizationBloc()
    : _visualizers = [],
      super(
        const VisualizationState(
          frameDuration: Duration(milliseconds: 50),
          gridStates: [],
        ),
      ) {
    on<_RegisterGridVisualizer>(_registerGridVisualizer);
    on<_UpdateGridState>(_updateGridState);
    on<ResetVisualization>(_reset);
    on<SetFrameDuration>(_setFrameDuration);
  }

  @override
  Future<void> close() async {
    for (final visualizer in _visualizers) {
      await visualizer.dispose();
    }
    _visualizers.clear();
    await super.close();
  }

  Future<void> _reset(
    ResetVisualization event,
    Emitter<VisualizationState> emit,
  ) async {
    emit(
      VisualizationState(
        frameDuration: state.frameDuration,
        gridStates: const [],
      ),
    );
    for (final visualizer in _visualizers) {
      await visualizer.dispose();
    }
    _visualizers.clear();
  }

  Future<void> _setFrameDuration(
    SetFrameDuration event,
    Emitter<VisualizationState> emit,
  ) async {
    emit(state.updateFrameDuration(event.duration));
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
    _visualizers.add(event.visualizer);
  }

  @override
  Future<Visualizer<Grid<I>>> createGridVisualizer<I>(
    Grid<I> grid, [
    String Function(I)? itemToString,
  ]) async {
    final gridState = GridState(
      grid,
      itemToString,
      progress: null,
      stepInfo: null,
    );
    final visualizer = _GridVisualizer(
      gridState,
      getFrameDuration: () => state.frameDuration,
    );
    add(_RegisterGridVisualizer(visualizer, gridState));
    return visualizer;
  }
}
