import 'dart:math';

import 'package:aoc_core/aoc_core.dart';

(int, int) _parseRange(String range) {
  final [left, right] = range.split('-');
  return (int.parse(left), int.parse(right));
}

@immutable
final class PartOne extends IntPart {
  const PartOne();

  Iterable<int> bruteForceSillySums(int left, int right) sync* {
    for (var n = left; n <= right; n += 1) {
      final s = n.toString();
      if (s.length.isOdd) {
        n = pow(10, s.length).toInt() - 1;
        continue;
      }
      final half = s.substring(0, s.length ~/ 2);
      if ('$half$half' == s) {
        yield n;
      }
    }
  }

  @override
  Future<int> calculate(
    Visualization visualization,
    Stream<String> input,
  ) async {
    final visualProgress = await visualization.createProgressVisualizer();
    final ranges = (await input.single).split(',').map(_parseRange);

    var sillySum = 0;
    for (final (left, right) in ranges) {
      sillySum += bruteForceSillySums(left, right).sum;
    }

    await visualProgress.update((Progress.indeterminateDone(), null));
    return sillySum;
  }
}

@immutable
final class PartTwo extends IntPart {
  const PartTwo();

  bool isSilly(String s) {
    final isEven = s.length.isEven;
    for (var divisor = isEven ? 2 : 3; divisor <= s.length; divisor += 1) {
      if (s.length % divisor != 0) {
        continue;
      }
      final prefixLength = s.length ~/ divisor;
      final prefix = s.substring(0, prefixLength);
      if (prefix * divisor == s) {
        return true;
      }
    }
    return false;
  }

  Iterable<int> bruteForceSillySums(int left, int right) sync* {
    for (var n = left; n <= right; n += 1) {
      final s = n.toString();
      if (isSilly(s)) {
        yield n;
      }
    }
  }

  @override
  Future<int> calculate(
    Visualization visualization,
    Stream<String> input,
  ) async {
    final visualProgress = await visualization.createProgressVisualizer();
    final ranges = (await input.single).split(',').map(_parseRange);

    var sillySum = 0;
    for (final (left, right) in ranges) {
      sillySum += bruteForceSillySums(left, right).sum;
    }

    await visualProgress.update((Progress.indeterminateDone(), null));
    return sillySum;
  }
}
