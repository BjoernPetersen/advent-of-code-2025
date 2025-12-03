import 'dart:math';

import 'package:aoc_core/aoc_core.dart';

List<int> parseBank(String s) {
  return List.unmodifiable(s.chars.map(int.parse));
}

int findMaximumJoltage(List<int> bank, {int digits = 2}) {
  for (var digit = 9; digit >= 0; digit -= 1) {
    final index = bank.indexOf(digit);
    if (index == -1) {
      continue;
    }

    if (digits == 1) {
      return digit;
    }

    final nextDigit = findMaximumJoltage(
      bank.sublist(index + 1),
      digits: digits - 1,
    );
    if (nextDigit == -1) {
      continue;
    }

    return digit * pow(10, digits - 1).toInt() + nextDigit;
  }

  return -1;
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

    final result = await input.map(parseBank).map(findMaximumJoltage).sum;

    await visualProgress.update((Progress.indeterminateDone(), null));
    return result;
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

    final result = await input
        .map(parseBank)
        .map((e) => findMaximumJoltage(e, digits: 12))
        .sum;

    await visualProgress.update((Progress.indeterminateDone(), null));
    return result;
  }
}
