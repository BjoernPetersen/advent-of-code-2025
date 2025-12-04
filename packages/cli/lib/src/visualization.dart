import 'package:aoc/day.dart';
import 'package:dart_console/dart_console.dart';

final class _CliSink {
  final Console _console;
  String? _grid;
  String? _progress;
  String? _stepInfo;

  _CliSink(this._console);

  Future<void> updateGrid(String grid) async {
    _grid = grid;
    await _writeOutput();
  }

  Future<void> updateProgress({
    required String progress,
    required String? stepInfo,
  }) async {
    _progress = progress;
    _stepInfo = stepInfo;
    await _writeOutput();
  }

  Future<void> _writeOutput() async {
    _console.clearScreen();
    _console.resetCursorPosition();

    _console.writeLine('--------');

    final progress = _progress;
    if (progress != null) {
      _console.writeLine(progress);
    }
    _console.writeLine(_stepInfo ?? '');

    final grid = _grid;
    if (grid != null) {
      _console.writeLine('---');
      _console.write(grid);
      _console.writeLine();
    }
  }
}

@immutable
final class _TextGridVisualizer<I> implements Visualizer<Grid<I>> {
  final String Function(I)? itemToString;
  final _CliSink sink;

  _TextGridVisualizer(this.sink, this.itemToString);

  String monospacedItemToString(I item) {
    final itemToString = this.itemToString ?? (e) => e.toString();
    final raw = itemToString(item);
    if (raw.isEmpty) {
      return ' ';
    }

    return raw;
  }

  @override
  Future<void> update(Grid<I> state) async {
    await sink.updateGrid(state.toString(monospacedItemToString));
    await Future.delayed(const Duration(milliseconds: 50));
  }
}

@immutable
final class _TextProgressVisualizer<I> implements Visualizer<ProgressPair> {
  final _CliSink sink;

  _TextProgressVisualizer(this.sink);

  String _printProgress(Progress? progress) {
    if (progress == null) {
      return '';
    }

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
  Future<void> update(ProgressPair state) async {
    final (progress, stepInfo) = state;

    await sink.updateProgress(
      progress: _printProgress(progress),
      stepInfo: stepInfo,
    );
  }
}

final class CliVisualization implements Visualization {
  final Console _console;
  final _CliSink _sink;
  bool _hasGridVisualizer = false;
  bool _hasProgressVisualizer = false;

  CliVisualization(this._console) : _sink = _CliSink(_console);

  @override
  Future<Visualizer<Grid<I>>> createGridVisualizer<I>(
    Grid<I> grid, [
    String Function(I)? itemToString,
  ]) async {
    if (_hasGridVisualizer) {
      throw StateError('Currently only one visualizer is supported at a time');
    }
    _hasGridVisualizer = true;
    return _TextGridVisualizer(_CliSink(_console), itemToString);
  }

  @override
  Future<Visualizer<ProgressPair>> createProgressVisualizer() async {
    if (_hasProgressVisualizer) {
      throw StateError('Currently only one visualizer is supported at a time');
    }
    _hasProgressVisualizer = true;
    return _TextProgressVisualizer(_sink);
  }
}
