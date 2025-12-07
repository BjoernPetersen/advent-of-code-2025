import 'package:aoc_core/aoc_core.dart';

sealed class Field {
  final Vector position;

  const Field(this.position);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Field &&
          runtimeType == other.runtimeType &&
          position == other.position;

  @override
  int get hashCode => position.hashCode;
}

final class EmptyField extends Field {
  final bool isStart;
  bool wasVisited;

  EmptyField(super.position, {required this.isStart}) : wasVisited = isStart;

  void visit() {
    wasVisited = true;
  }

  @override
  String toString() {
    if (isStart) {
      return 'S';
    }

    if (wasVisited) {
      return '|';
    }

    return '.';
  }
}

@immutable
final class Splitter extends Field {
  Splitter(super.position);

  Iterable<EmptyField> split(Grid<Field> grid) sync* {
    for (final direction in const [Vector.west, Vector.east]) {
      final newPosition = position + direction;
      if (!grid.contains(newPosition)) {
        continue;
      }

      final neighbor = grid[newPosition];
      if (neighbor is! EmptyField) {
        throw StateError('Neighboring splitters!');
      }

      yield neighbor;
    }
  }

  @override
  String toString() {
    return '^';
  }
}

Future<Grid<Field>> parseInput(Stream<String> input) async {
  return await Grid.fromStream(
    input,
    (pos, char) => switch (char) {
      '^' => Splitter(pos),
      '.' => EmptyField(pos, isStart: false),
      'S' => EmptyField(pos, isStart: true),
      final other => throw ArgumentError.value(
        other,
        null,
        'Invalid input character',
      ),
    },
  );
}

@immutable
final class PartOne extends IntPart {
  const PartOne();

  (Set<Vector>, int) moveBeams(Grid<Field> grid, Set<Vector> beamPositions) {
    var splitCount = 0;
    final newPositions = <Vector>{};

    for (final beam in beamPositions) {
      final below = beam + Vector.south;
      if (!grid.contains(below)) {
        return const ({}, 0);
      }

      switch (grid[below]) {
        case EmptyField field:
          field.visit();
          newPositions.add(field.position);
          break;
        case Splitter splitter:
          splitCount += 1;
          for (final neighbor in splitter.split(grid)) {
            neighbor.visit();
            newPositions.add(neighbor.position);
          }
          break;
      }
    }

    return (newPositions, splitCount);
  }

  @override
  Future<int> calculate(
    Visualization visualization,
    Stream<String> input,
  ) async {
    final visualProgress = await visualization.createProgressVisualizer();
    final grid = await parseInput(input);
    final visualGrid = await visualization.createGridVisualizer(grid);
    final start = grid.squares
        .where((e) => e is EmptyField && e.isStart)
        .first
        .position;

    var progress = Progress(totalWork: grid.height - start.y);
    await visualProgress.update((progress, null));

    var beamPositions = {start};
    var splitCount = 0;

    while (beamPositions.isNotEmpty) {
      final int newSplits;
      (beamPositions, newSplits) = moveBeams(grid, beamPositions);
      splitCount += newSplits;

      await Future.wait([
        visualProgress.update((++progress, null)),
        visualGrid.update(grid),
      ]);
    }

    return splitCount;
  }
}

final class TimelineFinder {
  final Grid<Field> grid;
  final Map<Vector, int> downstreamTimelines;

  TimelineFinder(this.grid) : downstreamTimelines = {};

  int findTimelines(final Vector position) {
    final below = position + Vector.south;

    if (!grid.contains(below)) {
      downstreamTimelines[position] = 1;
      return 1;
    }

    final cached = downstreamTimelines[below];
    if (cached != null) {
      downstreamTimelines[position] = cached;
      return cached;
    }

    final neighbor = grid[below];
    if (neighbor is! Splitter) {
      final result = findTimelines(neighbor.position);
      downstreamTimelines[position] = result;
      return result;
    }

    final nextPositions = <EmptyField, int>{};
    for (final emptyField in neighbor.split(grid)) {
      nextPositions.update(emptyField, (old) => old + 1, ifAbsent: () => 1);
    }

    var timelineCount = 0;
    for (final entry in nextPositions.entries) {
      final result = findTimelines(entry.key.position);
      timelineCount += entry.value * result;
    }

    downstreamTimelines[position] = timelineCount;
    return timelineCount;
  }
}

@immutable
final class PartTwo extends IntPart {
  const PartTwo();

  @override
  Future<int> calculate(
    Visualization visualization,
    Stream<String> input,
  ) async {
    final visualProgress = await visualization.createProgressVisualizer();
    final grid = await parseInput(input);
    final start = grid.squares
        .where((e) => e is EmptyField && e.isStart)
        .first
        .position;

    final timelineCount = TimelineFinder(grid).findTimelines(start);

    await visualProgress.update((Progress.indeterminateDone(), null));
    return timelineCount;
  }
}
