import 'dart:async';

import 'package:aoc_core/aoc_core.dart' hide immutable;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

const kDefaultFrameDuration = Duration(milliseconds: 50);

@immutable
sealed class VisualizedState<T, E extends VisualizedState<T, E>> {
  T get state;

  E updateState(T state);
}

@immutable
final class ProgressState extends Equatable
    implements VisualizedState<ProgressPair, ProgressState> {
  @override
  final ProgressPair state;
  Progress? get progress => state.$1;
  String? get stepInfo => state.$2;

  const ProgressState({required Progress? progress, required String? stepInfo})
    : state = (progress, stepInfo);
  const ProgressState._fromState(this.state);

  @override
  List<Object?> get props => [progress, stepInfo];

  @override
  ProgressState updateState(ProgressPair state) {
    return ProgressState._fromState(state);
  }
}

@immutable
final class GridState<T> implements VisualizedState<Grid<T>, GridState<T>> {
  @override
  final Grid<T> state;
  final String Function(T)? itemToString;

  const GridState(this.state, this.itemToString);

  @override
  GridState<T> updateState(Grid<T> state) {
    return GridState(state, itemToString);
  }
}

typedef Pair<T> = (T?, T?);

abstract interface class VisualizationStateView {
  Duration get frameDuration;
  GridState<Object?>? get gridState;
  ProgressState? get progressState;
}

@immutable
final class _VisualizationStateViewImpl extends Equatable
    implements VisualizationStateView {
  final VisualizationState state;
  final bool isPartOne;

  @override
  List<Object?> get props => [gridState, progressState];

  const _VisualizationStateViewImpl(this.state, {required this.isPartOne});

  @override
  Duration get frameDuration => state.frameDuration;

  @override
  GridState<Object?>? get gridState {
    if (isPartOne) {
      return state.gridStates.$1;
    } else {
      return state.gridStates.$2;
    }
  }

  @override
  ProgressState? get progressState {
    if (isPartOne) {
      return state.progressStates.$1;
    } else {
      return state.progressStates.$2;
    }
  }
}

@immutable
final class VisualizationState extends Equatable {
  final Duration frameDuration;
  final Pair<GridState<Object?>> gridStates;
  final Pair<ProgressState> progressStates;

  const VisualizationState._({
    required this.frameDuration,
    required this.gridStates,
    required this.progressStates,
  });

  @override
  List<Object?> get props => [
    frameDuration,
    getPartView(isPartOne: true),
    getPartView(isPartOne: false),
  ];

  const VisualizationState.initial()
    : this._(
        frameDuration: kDefaultFrameDuration,
        gridStates: (null, null),
        progressStates: (null, null),
      );

  VisualizationState clear() {
    return _copyWith(gridStates: (null, null), progressStates: (null, null));
  }

  VisualizationStateView getPartView({required bool isPartOne}) {
    return _VisualizationStateViewImpl(this, isPartOne: isPartOne);
  }

  VisualizationState _copyWith({
    Duration? frameDuration,
    (GridState<Object?>?, GridState<Object?>?)? gridStates,
    (ProgressState?, ProgressState?)? progressStates,
  }) {
    return VisualizationState._(
      frameDuration: frameDuration ?? this.frameDuration,
      gridStates: gridStates ?? this.gridStates,
      progressStates: progressStates ?? this.progressStates,
    );
  }

  Pair<T> _updatedPair<T>(Pair<T> pair, T state, {required bool isPartOne}) {
    if (isPartOne) {
      return (state, pair.$2);
    } else {
      return (pair.$1, state);
    }
  }

  VisualizationState addGridState(
    GridState<Object?> state, {
    required bool isPartOne,
  }) {
    if (getPartView(isPartOne: isPartOne).gridState != null) {
      throw StateError("Can't register multiple grid visualizers per part");
    }

    return _copyWith(
      gridStates: _updatedPair(gridStates, state, isPartOne: isPartOne),
    );
  }

  VisualizationState updateGridState(
    GridState state, {
    required bool isPartOne,
  }) {
    return _copyWith(
      gridStates: _updatedPair(gridStates, state, isPartOne: isPartOne),
    );
  }

  VisualizationState addProgressState(
    ProgressState state, {
    required bool isPartOne,
  }) {
    if (getPartView(isPartOne: isPartOne).progressState != null) {
      throw StateError("Can't register multiple progress visualizers per part");
    }

    return _copyWith(
      progressStates: _updatedPair(progressStates, state, isPartOne: isPartOne),
    );
  }

  VisualizationState updateProgressState(
    ProgressState state, {
    required bool isPartOne,
  }) {
    return _copyWith(
      progressStates: _updatedPair(progressStates, state, isPartOne: isPartOne),
    );
  }

  VisualizationState updateFrameDuration(Duration frameDuration) {
    return _copyWith(frameDuration: frameDuration);
  }
}

@immutable
sealed class VisualizationEvent {
  const VisualizationEvent();
}

@immutable
final class _RegisterGridVisualizer<T> extends VisualizationEvent {
  final bool isPartOne;
  final _Visualizer<Grid<T>, GridState<T>> visualizer;
  final GridState<T> state;

  const _RegisterGridVisualizer(
    this.visualizer,
    this.state, {
    required this.isPartOne,
  });
}

@immutable
final class _UpdateGridState<T> extends VisualizationEvent {
  final bool isPartOne;
  final GridState<T> state;

  const _UpdateGridState(this.state, {required this.isPartOne});
}

@immutable
final class _RegisterProgressVisualizer extends VisualizationEvent {
  final bool isPartOne;
  final _Visualizer<ProgressPair, ProgressState> visualizer;
  final ProgressState state;

  const _RegisterProgressVisualizer(
    this.visualizer,
    this.state, {
    required this.isPartOne,
  });
}

@immutable
final class _UpdateProgressState extends VisualizationEvent {
  final bool isPartOne;
  final ProgressState state;

  const _UpdateProgressState(this.state, {required this.isPartOne});
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

final class _Visualizer<I, V extends VisualizedState<I, V>>
    implements Visualizer<I> {
  late final StreamSubscription<V> _sub;
  final Duration Function()? _getFrameDuration;
  final StreamController<V> _controller;
  V _lastState;

  _Visualizer(V state, {required Duration Function()? getFrameDuration})
    : _getFrameDuration = getFrameDuration,
      _lastState = state,
      _controller = StreamController() {
    _controller.add(state);
  }

  void initialize(void Function(V) update) {
    _sub = _controller.stream.listen(update);
  }

  Future<void> dispose() {
    return _sub.cancel();
  }

  @override
  Future<void> update(I state) async {
    _lastState = _lastState.updateState(state);
    _controller.add(_lastState);
    final getFrameDuration = _getFrameDuration;
    if (getFrameDuration != null) {
      await Future.delayed(getFrameDuration());
    }
  }
}

final class VisualizationBloc
    extends Bloc<VisualizationEvent, VisualizationState> {
  final List<_Visualizer> _visualizers;

  VisualizationBloc()
    : _visualizers = [],
      super(const VisualizationState.initial()) {
    on<_RegisterGridVisualizer>(_registerGridVisualizer);
    on<_UpdateGridState>(_updateGridState);

    on<_RegisterProgressVisualizer>(_registerProgressVisualizer);
    on<_UpdateProgressState>(_updateProgressState);

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
    emit(state.clear());
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
    emit(state.updateGridState(event.state, isPartOne: event.isPartOne));
  }

  Future<void> _registerGridVisualizer<I>(
    _RegisterGridVisualizer<I> event,
    Emitter<VisualizationState> emit,
  ) async {
    final newState = state.addGridState(
      event.state,
      isPartOne: event.isPartOne,
    );
    emit(newState);
    event.visualizer.initialize(
      (s) => add(_UpdateGridState(s, isPartOne: event.isPartOne)),
    );
    _visualizers.add(event.visualizer);
  }

  Future<void> _updateProgressState(
    _UpdateProgressState event,
    Emitter<VisualizationState> emit,
  ) async {
    emit(state.updateProgressState(event.state, isPartOne: event.isPartOne));
  }

  Future<void> _registerProgressVisualizer(
    _RegisterProgressVisualizer event,
    Emitter<VisualizationState> emit,
  ) async {
    final newState = state.addProgressState(
      event.state,
      isPartOne: event.isPartOne,
    );
    emit(newState);
    event.visualizer.initialize(
      (s) => add(_UpdateProgressState(s, isPartOne: event.isPartOne)),
    );
    _visualizers.add(event.visualizer);
  }

  Visualization getVisualization({required bool isPartOne}) {
    return _PartVisualization(this, isPartOne: isPartOne);
  }
}

final class _PartVisualization implements Visualization {
  final bool isPartOne;
  final VisualizationBloc bloc;

  _PartVisualization(this.bloc, {required this.isPartOne});

  @override
  Future<Visualizer<Grid<I>>> createGridVisualizer<I>(
    Grid<I> grid, [
    String Function(I)? itemToString,
  ]) async {
    final gridState = GridState(grid, itemToString);
    final visualizer = _Visualizer<Grid<I>, GridState<I>>(
      gridState,
      getFrameDuration: () => bloc.state.frameDuration,
    );
    bloc.add(
      _RegisterGridVisualizer(visualizer, gridState, isPartOne: isPartOne),
    );
    return visualizer;
  }

  @override
  Future<Visualizer<ProgressPair>> createProgressVisualizer() async {
    final state = ProgressState(progress: null, stepInfo: null);
    final visualizer = _Visualizer<ProgressPair, ProgressState>(
      state,
      getFrameDuration: null,
    );
    bloc.add(
      _RegisterProgressVisualizer(visualizer, state, isPartOne: isPartOne),
    );
    return visualizer;
  }
}
