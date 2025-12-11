import 'package:aoc/day.dart';
import 'package:test/test.dart';

import '../input_helper.dart';

void main() {
  const visualization = StubVisualization();
  final dayNum = 11;
  final day = getDay(dayNum);

  group('day $dayNum', () {
    group('part 1', () {
      final part = day.partOne as IntPart;

      for (final (example, expectedResult) in [('instructions-1', 5)]) {
        test('example $example passes', () {
          final reader = getExampleReader(dayNum, example);
          expect(
            part.calculate(visualization, reader.readLines()),
            completion(expectedResult),
          );
        });
      }

      test('input passes', () {
        final reader = getInputReader(dayNum);
        expect(
          part.calculate(visualization, reader.readLines()),
          completion(539),
        );
      });
    });
    group('part 2', () {
      late final IntPart part;

      setUpAll(() {
        part = day.partTwo as IntPart;
      });

      for (final (example, expectedResult) in [('instructions-1', 0)]) {
        test('example $example passes', () {
          final reader = getExampleReader(dayNum, example);
          expect(
            part.calculate(visualization, reader.readLines()),
            completion(expectedResult),
          );
        });
      }

      test('input passes', () {
        final reader = getInputReader(dayNum);
        expect(
          part.calculate(visualization, reader.readLines()),
          completion(0),
        );
      });
    }, skip: day.partTwo == null);
  });
}
