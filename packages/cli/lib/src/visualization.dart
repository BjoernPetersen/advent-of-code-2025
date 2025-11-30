import 'package:aoc/day.dart';
import 'package:dart_console/dart_console.dart';

final class _TextGridVisualizer<I> implements Visualizer<Grid<I>> {
  final String Function(I)? itemToString;
  final Visualizer<String> sink;

  _TextGridVisualizer(this.sink, this.itemToString);

  @override
  Future<void> update(
    Grid<I> state, {
    String? stepInfo,
    Progress? progress,
  }) async {
    await sink.update(
      state.toString(itemToString),
      stepInfo: stepInfo,
      progress: progress,
    );
  }
}

final class _CliSink implements Visualizer<String> {
  final Console console;

  _CliSink(this.console);

  @override
  Future<void> update(
    String state, {
    String? stepInfo,
    Progress? progress,
  }) async {
    // TODO: show progress and stepInfo
    console.clearScreen();
    console.resetCursorPosition();
    console.writeLine('--------');
    for (final line in state.split('\n')) {
      console.writeLine(line);
    }
  }
}

final class CliVisualization implements Visualization {
  final Console console;
  bool isUsed = false;

  CliVisualization(this.console);

  @override
  Future<Visualizer<Grid<I>>> createGridVisualizer<I>(
    Grid<I> grid, [
    String Function(I)? itemToString,
  ]) async {
    if (isUsed) {
      throw StateError('Currently only one visualizer is supported at a time');
    }
    isUsed = true;
    return _TextGridVisualizer(_CliSink(console), itemToString);
  }
}
