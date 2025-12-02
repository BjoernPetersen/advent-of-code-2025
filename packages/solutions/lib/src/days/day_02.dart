import 'dart:math';

import 'package:aoc_core/aoc_core.dart';

(int, int) _parseRange(String range) {
  final [left, right] = range.split('-');
  return (int.parse(left), int.parse(right));
}

@immutable
final class PartOne extends IntPart {
  const PartOne();

  int getMagnitude(int n) {
    return (log(n) * log10e).toInt();
  }

  Iterable<int> bruteForceSillySums(int left, int right) sync* {
    for (var n = left; n <right; n += 1) {
      final s = n.toString();
      if (s.length.isOdd) {
        continue;
      }
      final half = s.substring(0, s.length ~/ 2);
      if('$half$half' == s) {
        yield n ;
      }
    }
  }

  Iterable<int> findSillySums(int left, int right) sync* {
    var magnitude = getMagnitude(left);

    final int first;
    if (magnitude.isEven) {
      magnitude += 1;
      first =  pow(10, magnitude).toInt();
    } else {
      first = left;
    }

    var multiplicator = 10 * pow(10, magnitude ~/ 2).toInt();
    final firstHalf = first ~/ multiplicator;

    var current = firstHalf;
    while (true) {
      final value = current * multiplicator + current;
      if (value > right || value <left) {
        return;
      }

      yield value;
      current += 1;
      final newMagnitude = getMagnitude(current) * 2;
      if (newMagnitude != magnitude) {
        multiplicator = 10 * pow(10, newMagnitude ~/ 2).toInt();
        magnitude = newMagnitude;
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
