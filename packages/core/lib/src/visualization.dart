import 'package:aoc_core/aoc_core.dart';

@immutable
final class Progress {
  final int workDone;
  final int totalWork;

  double get percentage => workDone / totalWork;

  Progress({this.workDone = 0, required this.totalWork}) {
    if (workDone > totalWork) {
      throw ArgumentError.value(
        workDone,
        'workDone',
        "can't be greater than totalWork ($totalWork)",
      );
    }
  }

  Progress.indeterminateDone() : workDone = 1, totalWork = 1;

  Progress operator +(int delta) {
    if (delta < 0) {
      throw ArgumentError.value(delta, 'delta', 'must be a positive number');
    }

    return Progress(totalWork: totalWork, workDone: workDone + delta);
  }

  Progress update(int workDone) =>
      Progress(totalWork: totalWork, workDone: workDone);

  Progress done() {
    return Progress(totalWork: totalWork, workDone: totalWork);
  }
}

typedef ProgressPair = (Progress?, String? stepInfo);

abstract interface class Visualizer<T> {
  Future<void> update(T state);
}

abstract interface class Visualization {
  Future<Visualizer<Grid<I>>> createGridVisualizer<I>(
    Grid<I> grid, [
    String Function(I)? itemToString,
  ]);

  Future<Visualizer<ProgressPair>> createProgressVisualizer();
}

@immutable
final class StubVisualizer<T> implements Visualizer<T> {
  const StubVisualizer();

  @override
  Future<void> update(T state) {
    return Future.value();
  }
}

@immutable
final class StubVisualization implements Visualization {
  const StubVisualization();

  @override
  Future<Visualizer<Grid<I>>> createGridVisualizer<I>(
    Grid<I> grid, [
    String Function(I)? itemToString,
  ]) {
    return Future.value(StubVisualizer());
  }

  @override
  Future<Visualizer<ProgressPair>> createProgressVisualizer() {
    return Future.value(StubVisualizer());
  }
}
