import 'package:aoc/day.dart';

final class _TextGridVisualizer<I> implements Visualizer<Grid<I>> {
  final String Function(I)? itemToString;
  final Visualizer<String> sink;

  _TextGridVisualizer(this.sink, this.itemToString);

  @override
  Future<void> update(Grid<I> state) async {
    await sink.update(state.toString(itemToString));
  }
}

final class _CliSink implements Visualizer<String> {
  @override
  Future<void> update(String state) {
    // TODO: implement update
    throw UnimplementedError();
  }
}

final class CliVisualization implements Visualization {
  @override
  Future<Visualizer<Grid<I>>> createGridVisualizer<I>([
    String Function(I)? itemToString,
  ]) async {
    return _TextGridVisualizer(_CliSink(), itemToString);
  }
}
