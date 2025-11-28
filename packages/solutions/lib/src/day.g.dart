import 'package:aoc_core/aoc_core.dart';
import 'package:aoc/src/days/day_01.dart' as day_1;

const availableDays = <int>[1];

Day<Part, Part> getDay(int day) {
  return switch (day) {
    1 => Day(day_1.PartOne()),
    final i => throw ArgumentError.value(day, 'day', 'day $i not implemented'),
  };
}
