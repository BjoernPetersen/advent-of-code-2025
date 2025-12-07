import 'package:aoc_core/src/visualization.dart';
import 'package:meta/meta.dart';

@immutable
sealed class Part<T> {
  const Part();

  Future<T> calculate(Visualization visualization, Stream<String> input);
}

@immutable
abstract base class IntPart extends Part<int> {
  const IntPart();
}

@immutable
abstract base class StringPart extends Part<String> {
  const StringPart();
}

@immutable
final class Day<A extends Part, B extends Part> {
  final A partOne;
  final B? partTwo;

  const Day(this.partOne, [this.partTwo]);
}

extension StringResult on Part {
  Future<String> calculateString(
    Visualization visualization,
    Stream<String> input,
  ) async {
    return switch (this) {
      StringPart part => await part.calculate(visualization, input),
      IntPart part => (await part.calculate(visualization, input)).toString(),
    };
  }
}
