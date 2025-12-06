import 'package:aoc_core/aoc_core.dart';

typedef Operator = int Function(int, int);

int add(int a, int b) => a + b;

int multiply(int a, int b) => a * b;

Operator parseOperator(String operator) {
  return switch (operator) {
    '*' => multiply,
    '+' => add,
    final other => throw ArgumentError.value(
      other,
      'operator',
      'unknown operation',
    ),
  };
}

Iterable<String> splitElements(String line) {
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
        operators = splitElements(
          line,
        ).map(parseOperator).toList(growable: false);
        continue;
      }

      operands.add(splitElements(line).map(int.parse).toList(growable: false));
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
