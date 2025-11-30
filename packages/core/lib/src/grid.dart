import 'bounds.dart';
import 'vector.dart';
import 'util.dart';

final class Grid<T> {
  final List<List<T>> _grid;
  final Bounds bounds;

  int get width => bounds.width;

  int get height => bounds.height;

  Grid(this._grid)
    : bounds = Bounds(width: _grid[0].length, height: _grid.length);

  Grid.generate({
    required int width,
    required int height,
    required T Function(Vector position) generator,
  }) : bounds = Bounds(width: width, height: height),
       _grid = List.generate(
         height,
         (y) => List.generate(
           width,
           (x) => generator(Vector(x: x, y: y)),
           growable: false,
         ),
         growable: false,
       );

  static Future<Grid<T>> fromStream<T>(
    Stream<String> lines,
    T Function(Vector, String) parseField,
  ) async {
    final rows = <List<T>>[];

    await for (final line in lines) {
      final row = <T>[];
      for (final char in line.chars) {
        final position = Vector(x: row.length, y: rows.length);
        row.add(parseField(position, char));
      }
      rows.add(row);
    }

    return Grid(rows);
  }

  Grid<T> clone() {
    return Grid(
      rows.map((e) => e.toList(growable: false)).toList(growable: false),
    );
  }

  T operator [](Vector pos) => _grid[pos.y][pos.x];

  void operator []=(Vector pos, T value) => _grid[pos.y][pos.x] = value;

  T update(Vector pos, T Function(T) compute) {
    final value = compute(this[pos]);
    this[pos] = value;
    return value;
  }

  bool contains(Vector pos) => bounds.contains(pos);

  Iterable<List<T>> get rows sync* {
    for (final row in _grid) {
      yield row;
    }
  }

  Iterable<Iterable<T>> get columns sync* {
    for (var x = 0; x < width; x += 1) {
      yield Iterable.generate(height, (y) => _grid[y][x]);
    }
  }

  Iterable<Vector> get positions sync* {
    for (var y = 0; y < height; ++y) {
      for (var x = 0; x < width; ++x) {
        yield Vector(x: x, y: y);
      }
    }
  }

  Iterable<T> get squares sync* {
    for (final position in positions) {
      yield this[position];
    }
  }

  @override
  String toString([String Function(T)? toString]) {
    return rows
        .map((row) => row.map(toString ?? (e) => e.toString()).join())
        .join('\n');
  }
}
