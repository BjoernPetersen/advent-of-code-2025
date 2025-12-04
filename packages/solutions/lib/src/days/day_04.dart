import 'package:aoc_core/aoc_core.dart';

final class Field {
  final Vector position;
  bool hasPaper;
  bool isAccessible;
  bool wasRemoved;

  Field._({
    required this.position,
    required this.hasPaper,
    required this.isAccessible,
    required this.wasRemoved,
  });

  factory Field.fromString(Vector position, String s) {
    return Field._(
      position: position,
      hasPaper: s == '@',
      isAccessible: false,
      wasRemoved: false,
    );
  }

  void markAccessible() {
    if (!hasPaper) {
      throw StateError('Non-paper cannot be accessed');
    }
    isAccessible = true;
  }

  void remove() {
    if (!hasPaper) {
      throw StateError('Non-paper cannot be removed');
    }
    if (!isAccessible) {
      throw StateError('Non-accessible paper cannot be removed');
    }
    hasPaper = false;
    isAccessible = false;
    wasRemoved = true;
  }

  void clearRemovalStatus() {
    wasRemoved = false;
  }

  @override
  String toString() {
    if (wasRemoved || isAccessible) {
      return 'x';
    }

    if (hasPaper) {
      return '@';
    }

    return '';
  }
}

bool isAccessible(Grid<Field> grid, Field field) {
  if (!field.hasPaper) {
    return false;
  }

  var neighborCount = 0;
  for (final direction in Vector.starDirections) {
    final adjacent = field.position + direction;
    if (!grid.contains(adjacent)) {
      continue;
    }

    if (grid[adjacent].hasPaper) {
      neighborCount += 1;
    }
  }

  return neighborCount < 4;
}

@immutable
final class PartOne extends IntPart {
  const PartOne();

  @override
  Future<int> calculate(
    Visualization visualization,
    Stream<String> input,
  ) async {
    final visualProgress = await visualization.createProgressVisualizer();

    final grid = await Grid.fromStream(input, Field.fromString);
    final visualGrid = await visualization.createGridVisualizer(grid);

    var progress = Progress(totalWork: grid.height * grid.width);
    await visualProgress.update((progress, null));

    for (final field in grid.squares) {
      if (isAccessible(grid, field)) {
        field.markAccessible();
      }

      await visualGrid.update(grid);
      await visualProgress.update((++progress, null));
    }

    return grid.squares.where((it) => it.isAccessible).count;
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

    final grid = await Grid.fromStream(input, Field.fromString);
    final visualGrid = await visualization.createGridVisualizer(grid);

    var totalRemovalCount = 0;
    while (true) {
      var removalCount = 0;
      for (final field in grid.squares) {
        if (field.wasRemoved) {
          field.clearRemovalStatus();
          continue;
        }

        if (isAccessible(grid, field)) {
          field.markAccessible();
          field.remove();
          removalCount += 1;
        }
      }

      if (removalCount == 0) {
        break;
      } else {
        totalRemovalCount += removalCount;
        removalCount = 0;
      }

      await visualGrid.update(grid);
    }

    await visualProgress.update((Progress.indeterminateDone(), null));
    return totalRemovalCount;
  }
}
