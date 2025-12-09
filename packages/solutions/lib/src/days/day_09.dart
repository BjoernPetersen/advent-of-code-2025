import 'dart:math';

import 'package:aoc_core/aoc_core.dart';

Stream<Vector> parseInput(Stream<String> input) {
  return input
      .map((line) => line.split(',').map(int.parse).toList(growable: false))
      .map((coordinates) => Vector(x: coordinates[0], y: coordinates[1]));
}

@immutable
final class Rectangle {
  final Vector _cornerA;
  final Vector _cornerB;

  const Rectangle(this._cornerA, this._cornerB);

  int get area {
    final p = (_cornerB - _cornerA).abs() + Vector.one;
    return p.x * p.y;
  }
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
    final redTiles = await parseInput(input).toList();

    var maxArea = 0;
    for (final (index, tileA) in redTiles.indexed) {
      for (final tileB in redTiles.sublist(index)) {
        maxArea = max(maxArea, Rectangle(tileA, tileB).area);
      }
    }

    await visualProgress.update((Progress.indeterminateDone(), null));
    return maxArea;
  }
}
