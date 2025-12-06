import 'package:aoc_core/aoc_core.dart';

@immutable
abstract interface class Operator {
  int call(int a, int b);

  int get identity;
}

@immutable
final class Multiply implements Operator {
  const Multiply();

  @override
  final int identity = 1;

  @override
  int call(int a, int b) => a * b;
}

@immutable
final class Add implements Operator {
  const Add();

  @override
  final int identity = 0;

  @override
  int call(int a, int b) => a + b;
}

Operator parseOperator(String operator) {
  return switch (operator) {
    '*' => const Multiply(),
    '+' => const Add(),
    final other => throw ArgumentError.value(
      other,
      'operator',
      'unknown operation',
    ),
  };
}

Iterable<String> splitByWhitespace(String line) {
  return line.split(RegExp(r'\s+')).whereNot((it) => it.isEmpty);
}

@immutable
final class PartOne extends IntPart {
  const PartOne();

  Future<(List<List<int>>, List<Operator>)> parseInput(
    Stream<String> input,
  ) async {
    final operands = <List<int>>[];
    List<Operator> operators = [];

    await for (final line in input) {
      if ('*+'.contains(line.chars.first)) {
        operators = splitByWhitespace(
          line,
        ).map(parseOperator).toList(growable: false);
        continue;
      }

      operands.add(
        splitByWhitespace(line).map(int.parse).toList(growable: false),
      );
    }

    return (operands, operators);
  }

  List<int> solve(List<Operator> operators, List<int> a, List<int> b) {
    return List.generate(
      a.length,
      (index) => operators[index](a[index], b[index]),
      growable: false,
    );
  }

  @override
  Future<int> calculate(
    Visualization visualization,
    Stream<String> input,
  ) async {
    final visualProgress = await visualization.createProgressVisualizer();

    final (operands, operators) = await parseInput(input);

    final sum = operands.reduce((a, b) => solve(operators, a, b)).sum;

    await visualProgress.update((Progress.indeterminateDone(), null));
    return sum;
  }
}

@immutable
final class PartTwo extends IntPart {
  const PartTwo();

  Iterable<int?> parseColumns(List<String> lines) sync* {
    List<List<String>> charLines = lines
        .map((l) => l.chars.toList(growable: false))
        .toList(growable: false);

    for (var index = 0; ; index += 1) {
      final chars = [];

      for (final line in charLines) {
        if (index < line.length) {
          chars.add(line[index]);
        }
      }

      if (chars.isEmpty) {
        yield null;
        return;
      }

      final stringNumber = chars.join().trim();
      if (stringNumber.isEmpty) {
        yield null;
        continue;
      }

      yield int.parse(stringNumber);
    }
  }

  Future<int> solve(Stream<String> input) async {
    final lines = await input.toList();
    List<Operator> operators = splitByWhitespace(
      lines.last,
    ).map(parseOperator).toList(growable: false);

    var operatorIndex = 0;
    var current = operators.first.identity;
    var total = 0;

    for (final number in parseColumns(lines.sublist(0, lines.length - 1))) {
      if (number == null) {
        total += current;
        operatorIndex += 1;
        if (operatorIndex < operators.length) {
          current = operators[operatorIndex].identity;
        }
        continue;
      }

      current = operators[operatorIndex](current, number);
    }

    return total;
  }

  @override
  Future<int> calculate(
    Visualization visualization,
    Stream<String> input,
  ) async {
    final visualProgress = await visualization.createProgressVisualizer();

    final sum = await solve(input);

    await visualProgress.update((Progress.indeterminateDone(), null));
    return sum;
  }
}
