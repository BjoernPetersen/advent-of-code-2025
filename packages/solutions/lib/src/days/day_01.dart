import 'package:aoc_core/aoc_core.dart';

@immutable
final class Instruction {
  final int direction;
  final int distance;

  Instruction.left(this.distance) : direction = -1;

  Instruction.right(this.distance) : direction = 1;

  int apply(int position) {
    final distance = this.distance % 100;
    final raw = position + (direction * distance);
    return (raw + 100) % 100;
  }

  factory Instruction.fromString(String instruction) {
    final first = instruction[0];
    final distance = int.parse(instruction.substring(1));
    return switch (first) {
      'L' => Instruction.left(distance),
      'R' => Instruction.right(distance),
      _ => throw ArgumentError.value(
        instruction,
        'instruction',
        'invalid direction',
      ),
    };
  }

  @override
  String toString() => (direction * distance).toString();
}

@immutable
final class PartOne extends IntPart {
  const PartOne();

  @override
  Future<int> calculate(
    Visualization visualization,
    Stream<String> input,
  ) async {
    var position = 50;
    var zeroCount = 0;

    await for (final instruction in input.map(Instruction.fromString)) {
      position = instruction.apply(position);
      if (position == 0) {
        zeroCount += 1;
      }
    }

    return zeroCount;
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
    var position = 50;
    var zeroCount = 0;

    await for (final instruction in input.map(Instruction.fromString)) {
      final hundreds = instruction.distance ~/ 100;
      final distance = instruction.distance % 100;
      zeroCount += hundreds;

      final oldPosition = position;
      position += distance * instruction.direction;

      if (position < 0 || position >= 100) {
        if (oldPosition != 0) {
          zeroCount += 1;
        }
        position = (position + 100) % 100;
      } else if (position == 0) {
        zeroCount += 1;
      }
    }

    return zeroCount;
  }
}
