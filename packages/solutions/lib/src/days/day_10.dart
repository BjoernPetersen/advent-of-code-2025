import 'package:aoc_core/aoc_core.dart';
import 'package:ordered_set/ordered_set.dart';

@immutable
final class State<T> {
  final _equality = ListEquality<T>();

  final List<T> _data;

  Iterable<(int, T)> get indexedItems => _data.indexed;

  int get length => _data.length;

  T operator [](int index) {
    return _data[index];
  }

  State.unmodifiable(Iterable<T> indicators)
    : _data = List.unmodifiable(indicators);

  @override
  bool operator ==(Object other) =>
      runtimeType == other.runtimeType &&
      _equality.equals(_data, (other as State<T>)._data);

  @override
  int get hashCode => _equality.hash(_data);

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[');
    buffer.write(_data.join(','));
    buffer.write('] ');
    return buffer.toString();
  }
}

@immutable
final class Button {
  final Set<int> _wires;

  Iterable<int> get wires => _wires;

  const Button(this._wires);

  State<bool> pressIndicator(State<bool> state) {
    return State.unmodifiable(
      state._data.mapIndexed(
        (index, pre) => _wires.contains(index) ? !pre : pre,
      ),
    );
  }

  State<int> pressJoltage(State<int> state) {
    return State.unmodifiable(
      state._data.mapIndexed(
        (index, pre) => _wires.contains(index) ? pre + 1 : pre,
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

  final State<bool> targetIndicators;
  final List<Button> buttons;
  final State<int> targetJoltages;

  const MachineManual._({
    required this.targetIndicators,
    required this.buttons,
    required this.targetJoltages,
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
    final joltages = State.unmodifiable(
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
      targetIndicators: indicators,
      buttons: buttons,
      targetJoltages: joltages,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write(targetIndicators);

    buttons.forEach(buffer.write);

    buffer.write(targetJoltages);

    return buffer.toString();
  }
}

int findSolution<T>(
  final MachineManual manual, {
  required final State<T> initial,
  required final State<T> target,
  required final State<T> Function(Button, State<T>) apply,
  required bool Function(State<T>) isValidState,
}) {
  final seen = <State<T>, int>{initial: 0};

  final unvisited = OrderedSet.comparing<State<T>>(
    compare: (a, b) => seen[a]!.compareTo(seen[b]!),
  );

  var current = initial;
  while (current != target) {
    final currentCost = seen[current]!;

    for (final button in manual.buttons) {
      final neighbor = apply(button, current);
      if (seen.containsKey(neighbor)) {
        continue;
      }

      seen[neighbor] = currentCost + 1;

      if (!isValidState(neighbor)) {
        continue;
      }

      unvisited.add(neighbor);

      if (neighbor == target) {
        return currentCost + 1;
      }
    }

    current = unvisited.first;
    unvisited.remove(current);
  }

  return seen[current]!;
}

int getPathLength<T>({
  required final State<T> initial,
  required final State<T> target,
  required Map<State<T>, State<T>> cameFrom,
}) {
  var count = 0;
  State<T>? current = cameFrom[target];
  while (current != null) {
    current = cameFrom[current];
    count += 1;
  }

  return count;
}

int findStarSolution<T>(
  final MachineManual manual, {
  required final State<T> initial,
  required final State<T> target,
  required final State<T> Function(Button, State<T>) apply,
  required bool Function(State<T>) isValidState,
  required int Function(State<T>, State<T>) difference,
}) {
  final fScore = <State<T>, int>{initial: difference(target, initial)};
  final gScore = <State<T>, int>{initial: 0};
  final cameFrom = <State<T>, State<T>>{};

  final unvisited = OrderedSet.comparing<State<T>>(
    compare: (a, b) => fScore[a]!.compareTo(fScore[b]!),
  );
  unvisited.add(initial);

  while (unvisited.isNotEmpty) {
    final current = unvisited.first;
    unvisited.remove(current);

    if (current == target) {
      return getPathLength(
        initial: initial,
        target: target,
        cameFrom: cameFrom,
      );
    }

    for (final button in manual.buttons) {
      final neighbor = apply(button, current);

      if (!isValidState(neighbor)) {
        continue;
      }

      final neighborCost = gScore[current]! + 1;
      final previousCost = gScore[neighbor];
      if (previousCost == null || neighborCost < previousCost) {
        if (previousCost != null) {
          unvisited.remove(neighbor);
        }

        cameFrom[neighbor] = current;
        gScore[neighbor] = neighborCost;
        fScore[neighbor] = neighborCost + difference(target, neighbor);

        unvisited.add(neighbor);
      }
    }
  }

  throw StateError('no path found');
}

@immutable
final class PartOne extends IntPart {
  const PartOne();

  @override
  Future<int> calculate(
    Visualization visualization,
    Stream<String> input,
  ) async {
    final visualProgress = await visualization.createProgressVisualizer();

    final manuals = input.map(MachineManual.fromString);

    final solutions = await manuals.map((m) {
      final initial = State.unmodifiable(
        Iterable.generate(m.targetIndicators.length, (_) => false),
      );
      return findSolution(
        m,
        initial: initial,
        target: m.targetIndicators,
        apply: (b, s) => b.pressIndicator(s),
        isValidState: (_) => true,
      );
    }).toList();

    await visualProgress.update((Progress.indeterminateDone(), null));
    return solutions.sum;
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
    final visualProgress = await visualization.createProgressVisualizer();
    await visualProgress.update((null, 'Parsing input'));

    final manuals = await input.map(MachineManual.fromString).toList();

    var progress = Progress(totalWork: manuals.length);
    await visualProgress.update((progress, 'Calculating solutions'));

    var sum = 0;
    for (final manual in manuals) {
      final initial = State.unmodifiable(
        Iterable.generate(manual.targetJoltages.length, (_) => 0),
      );
      sum += findStarSolution(
        manual,
        initial: initial,
        target: manual.targetJoltages,
        apply: (b, s) => b.pressJoltage(s),
        isValidState: (s) => s.indexedItems.every((indexed) {
          final (index, item) = indexed;
          return item <= manual.targetJoltages[index];
        }),
        difference: (a, b) {
          var sum = 0;
          for (final (index, item) in a.indexedItems) {
            sum += (item - b[index]).abs();
          }
          return sum;
        },
      );

      await visualProgress.update((++progress, 'Calculating solutions'));
    }

    return sum;
  }
}
