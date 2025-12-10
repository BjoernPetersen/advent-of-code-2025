import 'package:aoc_core/aoc_core.dart';
import 'package:ordered_set/ordered_set.dart';

@immutable
final class State {
  static const _equality = ListEquality<bool>();

  final List<bool> indicators;

  int get length => indicators.length;

  State.unmodifiable(Iterable<bool> indicators)
    : indicators = List.unmodifiable(indicators);

  @override
  bool operator ==(Object other) =>
      runtimeType == other.runtimeType &&
      _equality.equals(indicators, (other as State).indicators);

  @override
  int get hashCode => _equality.hash(indicators);

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[');
    indicators.map((b) => b ? '#' : '.').forEach(buffer.write);
    buffer.write('] ');
    return buffer.toString();
  }
}

@immutable
final class Button {
  final Set<int> _wires;

  Iterable<int> get wires => _wires;

  const Button(this._wires);

  State press(State state) {
    return State.unmodifiable(
      state.indicators.mapIndexed(
        (index, pre) => _wires.contains(index) ? !pre : pre,
      ),
    );
  }

  @override
  String toString() {
    return '(${wires.join(",")})';
  }
}

@immutable
final class MachineManual {
  static final _regexIndicator = RegExp(r'\[([.#]+)]');
  static final _regexButtons = RegExp(r'\((\d+(?:,\d+)*)\)');
  static final _regexJoltage = RegExp(r'\{(\d+(?:,\d+)*)\}');

  final State target;
  final List<Button> buttons;
  final List<int> joltages;

  int get indicatorCount => target.length;

  const MachineManual._({
    required this.target,
    required this.buttons,
    required this.joltages,
  });

  factory MachineManual.fromString(String line) {
    final indicatorMatch = _regexIndicator.firstMatch(line);
    final buttonMatches = _regexButtons.allMatches(line);
    final joltageMatch = _regexJoltage.firstMatch(line);

    if (indicatorMatch == null || joltageMatch == null) {
      throw ArgumentError('Invalid formatting');
    }

    final indicators = State.unmodifiable(
      indicatorMatch.group(1)!.chars.map((c) => c == '#'),
    );
    final joltages = List<int>.unmodifiable(
      joltageMatch.group(1)!.split(',').map(int.parse),
    );

    final buttons = List<Button>.unmodifiable(
      buttonMatches
          .map((buttonMatch) => buttonMatch.group(1)!.split(',').map(int.parse))
          .map(Set.unmodifiable)
          .map(Button.new),
    );

    if (buttons.isEmpty) {
      throw ArgumentError('No button wirings found');
    }

    return MachineManual._(
      target: indicators,
      buttons: buttons,
      joltages: joltages,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write(target.toString());

    buttons.forEach(buffer.write);

    buffer.write('{');
    buffer.write(joltages.join(','));
    buffer.write('}');

    return buffer.toString();
  }
}

@immutable
final class PartOne extends IntPart {
  const PartOne();

  bool findPath({
    required MachineManual manual,
    required State current,
    required Map<State, int> seen,
  }) {
    if (seen.containsKey(manual.target)) {
      return true;
    }

    final currentCost = seen[current]!;

    for (final button in manual.buttons) {
      final target = button.press(current);
      final previousCost = seen[target];
      if (previousCost != null && previousCost <= currentCost + 1) {
        continue;
      }

      seen[target] = currentCost + 1;
      final found = findPath(manual: manual, current: current, seen: seen);
      if (found) {
        return true;
      }
    }

    return false;
  }

  int findSolution(MachineManual manual) {
    final initial = State.unmodifiable(
      Iterable.generate(manual.indicatorCount, (_) => false),
    );
    final seen = <State, int>{initial: 0};

    final unvisited = OrderedSet.comparing<State>(
      compare: (a, b) => seen[a]!.compareTo(seen[b]!),
    );

    var current = initial;
    while (current != manual.target) {
      final currentCost = seen[current]!;

      for (final button in manual.buttons) {
        final neighbor = button.press(current);
        if (seen.containsKey(neighbor)) {
          continue;
        }

        seen[neighbor] = currentCost + 1;
        unvisited.add(neighbor);
      }

      current = unvisited.first;
      unvisited.remove(current);
    }

    return seen[current]!;
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
