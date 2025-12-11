import 'dart:math';

import 'package:aoc_core/aoc_core.dart';

Stream<Vector> parseInput(Stream<String> input) {
  return input
      .map((line) => line.split(',').map(int.parse).toList(growable: false))
      .map((coordinates) => Vector(x: coordinates[0], y: coordinates[1]));
}

@immutable
final class Line {
  final Vector base;
  final Vector direction;

  Vector get end => base + direction;

  const Line({required this.base, required this.direction});

  static bool _isOneDimensional(Vector v) {
    return v.x == 0 || v.y == 0;
  }

  static Vector _unit(Vector v) {
    if (!_isOneDimensional(v)) {
      throw ArgumentError.value(v.toString(), 'v', 'is not one-dimensional');
    }
    return Vector(x: max(-1, min(1, v.x)), y: max(-1, min(1, v.y)));
  }

  factory Line.fromPoints(Vector a, Vector b) {
    final direction = b - a;
    return Line(base: a, direction: direction);
  }

  bool contains(Vector point) {
    // using the assumption that all edges are vertical or horizontal
    final distance = point - base;

    if (distance == Vector.zero) {
      return true;
    }

    if (!_isOneDimensional(distance)) {
      return false;
    }

    if (_unit(distance) != _unit(direction)) {
      return false;
    }

    if (distance.manhattanNorm() > direction.manhattanNorm()) {
      return false;
    }

    return true;
  }

  bool intersects(Line otherEdge) {
    final containsBase = contains(otherEdge.base);
    final containsEnd = contains(otherEdge.end);
    if (containsBase && containsEnd) {
      return false;
    }

    if (containsBase || containsEnd) {
      // this is definitely ignoring edge cases
      return false;
    }

    // check if any point of the other line is on our line
    final rect = Rectangle.fromOppositeCorners(base, otherEdge.base);
    for (final corner in rect.corners) {
      if (corner == base || corner == otherEdge.base) {
        continue;
      }

      if (contains(corner) && otherEdge.contains(corner)) {
        return true;
      }
    }

    return false;
  }
}

@immutable
final class Rectangle {
  final Line _line;

  const Rectangle._(this._line);

  factory Rectangle.fromOppositeCorners(Vector cornerA, Vector cornerB) {
    return Rectangle._(Line.fromPoints(cornerA, cornerB));
  }

  int get area {
    final p = _line.direction.abs() + Vector.one;
    return p.x * p.y;
  }

  Iterable<Line> get edges sync* {
    final base = _line.base;
    final direction = _line.direction;

    var line = Line(
      base: base,
      direction: Vector(x: direction.x),
    );
    yield line;
    yield Line.fromPoints(line.end, _line.end);

    line = Line(
      base: base,
      direction: Vector(y: direction.y),
    );
    yield line;
    yield Line.fromPoints(line.end, _line.end);
  }

  Iterable<Vector> get corners sync* {
    yield _line.base;
    yield _line.end;

    final direction = _line.direction;

    if (direction.x == 0 || direction.y == 0) {
      return;
    }

    yield _line.base + Vector(x: direction.x);
    yield _line.base + Vector(y: direction.y);
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
      for (final tileB in redTiles.sublist(index + 1)) {
        maxArea = max(
          maxArea,
          Rectangle.fromOppositeCorners(tileA, tileB).area,
        );
      }
    }

    await visualProgress.update((Progress.indeterminateDone(), null));
    return maxArea;
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
    final redTiles = <Vector>[];
    final edges = <Line>[];

    await for (final (a, b) in parseInput(input).zipWithNext()) {
      redTiles.add(a);
      edges.add(Line.fromPoints(a, b));
    }

    redTiles.add(edges.last.end);
    edges.add(Line.fromPoints(redTiles.last, redTiles.first));

    var maxArea = 0;
    for (final (index, tileA) in redTiles.indexed) {
      for (final tileB in redTiles.sublist(index + 1)) {
        final rect = Rectangle.fromOppositeCorners(tileA, tileB);
        if (rect.area < maxArea) {
          continue;
        }

        if (isValid(rect, edges)) {
          maxArea = rect.area;
        }
      }
    }

    await visualProgress.update((Progress.indeterminateDone(), null));
    return maxArea;
  }

  bool isValid(Rectangle rect, List<Line> edges) {
    for (final rectEdge in rect.edges) {
      if (edges.any((otherEdge) => otherEdge.intersects(rectEdge))) {
        return false;
      }
    }

    return true;
  }
}
