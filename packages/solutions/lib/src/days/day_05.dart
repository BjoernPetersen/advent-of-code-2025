import 'dart:math' as math;

import 'package:aoc_core/aoc_core.dart';

@immutable
final class Range {
  final int min;
  final int max;

  Range({required this.min, required this.max});

  factory Range.fromString(String range) {
    final [left, right] = range
        .split('-')
        .map(int.parse)
        .toList(growable: false);
    return Range(min: left, max: right);
  }

  bool contains(int x) {
    return x >= min && x <= max;
  }

  int get size => max - min + 1;

  Range? merge(Range other) {
    if (contains(other.min) || contains(other.max)) {
      return Range(
        min: math.min(min, other.min),
        max: math.max(max, other.max),
      );
    }

    if (other.contains(min)) {
      return other;
    }

    return null;
  }

  @override
  String toString() {
    return '$min-$max';
  }
}

@immutable
final class Database {
  final List<Range> ranges;
  final List<int> ingredients;

  Database({required List<Range> ranges, required List<int> ingredients})
    : this.ranges = List.unmodifiable(ranges),
      ingredients = List.unmodifiable(ingredients);

  bool isFresh(int ingredient) {
    return ranges.any((range) => range.contains(ingredient));
  }
}

Future<Database> parseInput(Stream<String> input) async {
  final ranges = <Range>[];
  final ingredients = <int>[];
  var isRangesDone = false;

  await for (final line in input) {
    if (isRangesDone) {
      ingredients.add(int.parse(line));
    } else if (line.isEmpty) {
      isRangesDone = true;
    } else {
      ranges.add(Range.fromString(line));
    }
  }

  return Database(ranges: ranges, ingredients: ingredients);
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
    final db = await parseInput(input);

    final result = db.ingredients
        .where((ingredient) => db.isFresh(ingredient))
        .count;

    await visualProgress.update((Progress.indeterminateDone(), null));
    return result;
  }
}

List<Range> simplifyRanges(List<Range> ranges) {
  final simplified = {0};
  var result = ranges;

  while (simplified.isNotEmpty) {
    ranges = result;
    result = [];
    simplified.clear();

    for (final (index, range) in ranges.indexed) {
      if (simplified.contains(index)) {
        continue;
      }

      for (final (otherOffset, otherRange)
          in ranges.sublist(index + 1).indexed) {
        final otherIndex = index + otherOffset + 1;
        if (simplified.contains(otherIndex)) {
          continue;
        }

        final merged = range.merge(otherRange);
        if (merged != null) {
          simplified.add(index);
          simplified.add(otherIndex);
          result.add(merged);
        }
      }

      if (!simplified.contains(index)) {
        result.add(range);
      }
    }
  }

  return result;
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
    var progress = Progress(totalWork: 3);
    await visualProgress.update((progress, 'Parsing input'));
    final db = await parseInput(input);

    await visualProgress.update((++progress, 'Simplifying ranges'));
    final ranges = simplifyRanges(db.ranges);

    await visualProgress.update((++progress, 'Counting fresh ingredient IDs'));
    final result = ranges.map((e) => e.size).sum;

    await visualProgress.update((++progress, null));
    return result;
  }
}
