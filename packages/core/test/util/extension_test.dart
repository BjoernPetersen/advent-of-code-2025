import 'package:aoc_core/aoc_core.dart';
import 'package:test/test.dart';

void main() {
  group('CharIterable', () {
    group('chars', () {
      test('emptyString', () {
        expect(''.chars, isEmpty);
      });

      test('example', () {
        final result = 'abc 123'.chars.toList(growable: false);
        expect(result, ['a', 'b', 'c', ' ', '1', '2', '3']);
      });
    });
  });

  group('StreamUtils', () {
    group('count', () {
      test('empty', () {
        expect(Stream.empty().count, completion(0));
      });

      test('example', () {
        expect(Stream.fromIterable([1, 2, 3]).count, completion(3));
      });
    });
  });

  group('IterableUtils', () {
    group('count', () {
      test('empty', () {
        expect([].count, 0);
      });

      test('example', () {
        expect([1, 2, 3].count, 3);
      });
    });

    group('combined', () {
      test('shorter a', () {
        expect(
          () => [
            'a',
          ].combined(['a', 'b'], (a, b) => a + b).toList(growable: false),
          throwsArgumentError,
        );
      });

      test('shorter b', () {
        expect(
          () => [
            'a',
            'b',
          ].combined(['a'], (a, b) => a + b).toList(growable: false),
          throwsArgumentError,
        );
      });

      test('happy path', () {
        expect([2, 4, 6, 8].combined([1, 3, 5, 7], (a, b) => a + b), [
          3,
          7,
          11,
          15,
        ]);
      });
    });

    group('zipWithNext', () {
      test('empty', () {
        expect([].zipWithNext(), isEmpty);
      });

      test('single', () {
        expect([1].zipWithNext(), isEmpty);
      });

      test('odd', () {
        expect([1, 2, 3].zipWithNext(), [(1, 2), (2, 3)]);
      });

      test('even', () {
        expect([1, 2, 3, 4].zipWithNext(), [(1, 2), (2, 3), (3, 4)]);
      });
    });
  });

  group('IntIterableUtils', () {
    group('product', () {
      test('empty', () {
        expect(() => <int>[].product, throwsStateError);
      });

      test('single', () {
        expect([2].product, 2);
      });

      test('example', () {
        expect([2, 3, 4].product, 24);
      });
    });
  });

  group('IntStreamUtils', () {
    group('product', () {
      test('empty', () {
        expect(Stream<int>.empty().product, throwsStateError);
      });

      test('single', () {
        expect(Stream.fromIterable([2]).product, completion(2));
      });

      test('example', () {
        expect(Stream.fromIterable([2, 3, 4]).product, completion(24));
      });
    });
    group('sum', () {
      test('empty', () {
        expect(Stream<int>.empty().sum, completion(0));
      });

      test('single', () {
        expect(Stream.fromIterable([2]).sum, completion(2));
      });

      test('example', () {
        expect(Stream.fromIterable([2, 3, 4]).sum, completion(9));
      });
    });
  });
}
