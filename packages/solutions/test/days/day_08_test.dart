import 'package:aoc/day.dart';
import 'package:test/test.dart';
import 'package:aoc/src/days/day_08.dart' as day8;

import '../input_helper.dart';

void main() {
  const visualization = StubVisualization();
  final dayNum = 08;
  final day = getDay(dayNum);

  group('day $dayNum', () {
    group('part 1', () {
      final part = day.partOne as day8.PartOne;

      for (final (example, expectedResult) in [('instructions-1', 40)]) {
        test('example $example passes', () {
          final reader = getExampleReader(dayNum, example);
          expect(
            part.calculate(
              visualization,
              reader.readLines(),
              connectionCount: 10,
            ),
            completion(expectedResult),
          );
        });
      }

      test('input passes', () {
        final reader = getInputReader(dayNum);
        expect(
          part.calculate(visualization, reader.readLines()),
          completion(175440),
        );
      });
    });
    group('part 2', () {
      late final IntPart part;

      setUpAll(() {
        part = day.partTwo as IntPart;
      });

      for (final (example, expectedResult) in [('instructions-1', 25272)]) {
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
          completion(3200955921),
        );
      });
    }, skip: day.partTwo == null);
  });
}
