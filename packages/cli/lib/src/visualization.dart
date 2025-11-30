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

  String _printProgress(Progress progress) {
    final buffer = StringBuffer('Progress: ');
    final filledCount = (progress.percentage * 50.0).floor();
    for (final i in Iterable.generate(50)) {
      if (i < filledCount) {
        buffer.write('#');
      } else {
        buffer.write('.');
      }
    }
    buffer.write(' (');
    buffer.write(progress.workDone);
    buffer.write('/');
    buffer.write(progress.totalWork);
    buffer.write(')');

    return buffer.toString();
  }

  @override
  Future<void> update(
    String state, {
    String? stepInfo,
    Progress? progress,
  }) async {
    console.clearScreen();
    console.resetCursorPosition();

    console.writeLine('--------');

    if (progress != null) {
      console.writeLine(_printProgress(progress));
    }
    console.writeLine(stepInfo ?? '');

    console.writeLine('---');

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
