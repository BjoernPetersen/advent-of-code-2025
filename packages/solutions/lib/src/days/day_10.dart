import 'package:aoc_core/aoc_core.dart';


@immutable
final class MachineManual {
  static final _regexIndicator =  RegExp(r'\[([.#]+)]');
  static final _regexButtons = RegExp(r'\((\d+(?:,\d+)*)\)');
  static final _regexJoltage = RegExp(r'\{(\d+(?:,\d+)*)\}');

  final List<bool> indicators;
  final List<List<int>> buttons;
  final List<int> joltages;

 const MachineManual._({required this.indicators, required this.buttons, required this.joltages});

 factory MachineManual.fromString(String line) {
   final indicatorMatch = _regexIndicator.firstMatch(line);
   final buttonMatches = _regexButtons.allMatches(line);
   final joltageMatch = _regexJoltage.firstMatch(line);

   if(indicatorMatch == null || joltageMatch == null) {
     throw ArgumentError('Invalid formatting');
   }

   final indicators = List<bool>.unmodifiable(indicatorMatch.group(1)!.chars.map((c) => c == '#'))   ;
   final joltages = List<int>.unmodifiable(joltageMatch.group(1)!.split(',').map(int.parse));

   final buttons = List<List<int>>.unmodifiable(buttonMatches.map((buttonMatch) => List<int>.unmodifiable(buttonMatch.group(1)!.split(',').map(int.parse))));

   if(buttons.isEmpty) {
     throw ArgumentError('No button wirings found');
   }

   return MachineManual._(indicators: indicators, buttons:buttons, joltages: joltages);
  }

  @override
  String toString() {
   final buffer = StringBuffer();

   buffer.write('[');
   indicators.map((b) => b ? '#' : '.').forEach(buffer.write);
   buffer.write('] ');

   buttons.map((b) => b.join(',')).forEach((b) {
     buffer.write('(');
     buffer.write(b);
     buffer.write(') ');
   });

   buffer.write('{');
   buffer.write(joltages.join(','));
   buffer.write('}');

   return buffer.toString();
  }
}

@immutable
final class PartOne extends IntPart {
  const PartOne();

  int findSolution(MachineManual manual) {
    // TODO: span a graph and dijkstra it?
    return 1;
  }

  @override
  Future<int> calculate(
    Visualization visualization,
    Stream<String> input,
  ) async {
    final visualProgress = await visualization.createProgressVisualizer();

    final manuals = input.map(MachineManual.fromString);
    final solutions = await manuals.map(findSolution).toList();

    await visualProgress.update((Progress.indeterminateDone(), null));
    return solutions.sum;
  }
}
