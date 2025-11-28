import 'package:aoc_core/aoc_core.dart';

abstract interface class Visualizer<T> {
  Future<void> update(T state);
}

abstract interface class Visualization {
  Future<Visualizer<Grid<I>>> createGridVisualizer<I>();
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
  Future<Visualizer<Grid<I>>> createGridVisualizer<I>() {
    return Future.value(const StubVisualizer());
  }
}
