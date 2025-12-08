import 'dart:math';

import 'package:aoc_core/aoc_core.dart';

Future<List<Vector3>> parseInput(Stream<String> input) async {
  final result = <Vector3>[];

  await for (final line in input) {
    final coordinates = line.split(',').map(int.parse).toList(growable: false);
    final vector = Vector3(
      x: coordinates[0],
      y: coordinates[1],
      z: coordinates[2],
    );
    result.add(vector);
  }

  return result;
}

Iterable<Pair<T>> generatePairs<T>(List<T> list) sync* {
  for (final (index, left) in list.indexed) {
    for (final right in list.sublist(index + 1)) {
      yield (left, right);
    }
  }
}

final class Circuit {
  final Set<Vector3> junctions;
  final Set<Pair<Vector3>> connections;

  int get size => junctions.length;

  Circuit._(this.junctions, this.connections);

  factory Circuit.initial(Pair<Vector3> first) {
    final (left, right) = first;
    return Circuit._({left, right}, {first});
  }

  void add(Pair<Vector3> pair) {
    if (!connections.add(pair)) {
      return;
    }
    final (left, right) = pair;
    junctions.add(left);
    junctions.add(right);
  }

  void merge(Circuit other, Pair<Vector3> newPair) {
    if (other.size > size) {
      throw ArgumentError();
    }

    other.connections.forEach(add);
    add(newPair);
  }

  bool contains(Vector3 junction) {
    return junctions.contains(junction);
  }
}

double calculateDistance(Pair<Vector3> pair) {
  final (left, right) = pair;
  return (right - left).norm(2);
}

void connectPair(List<Circuit> circuits, Pair<Vector3> pair) {
  final (left, right) = pair;
  Circuit? leftCircuit, rightCircuit;

  for (final circuit in circuits) {
    if (circuit.contains(left)) {
      leftCircuit = circuit;
    }

    if (circuit.contains(right)) {
      rightCircuit = circuit;
    }
  }

  switch ((leftCircuit, rightCircuit)) {
    case (null, null):
      circuits.add(Circuit.initial(pair));
      break;
    case (null, Circuit some) || (Circuit some, null):
      some.add(pair);
      break;
    case (Circuit a, Circuit b):
      if (a == b) {
        a.add(pair);
      } else if (a.size >= b.size) {
        circuits.remove(b);
        a.merge(b, pair);
      } else {
        circuits.remove(a);
        b.merge(a, pair);
      }
      break;
  }
}

@immutable
final class PartOne extends IntPart {
  const PartOne();

  @override
  Future<int> calculate(
    Visualization visualization,
    Stream<String> input, {
    int connectionCount = 1_000,
  }) async {
    final visualProgress = await visualization.createProgressVisualizer();

    await visualProgress.update((null, 'Parsing input'));
    final junctions = await parseInput(input);

    await visualProgress.update((null, 'Sorting pairs'));
    final pairs = generatePairs(junctions).sortedBy(calculateDistance);

    await visualProgress.update((null, 'Connecting pairs'));
    final circuits = <Circuit>[];

    for (final pair in pairs.sublist(0, min(connectionCount, pairs.length))) {
      connectPair(circuits, pair);
    }

    await visualProgress.update((Progress.indeterminateDone(), null));
    return circuits.map((c) => c.size).sortedBy((e) => -e).take(3).product;
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
    final junctions = await parseInput(input);

    await visualProgress.update((null, 'Sorting pairs'));
    final pairs = generatePairs(junctions).sortedBy(calculateDistance);

    await visualProgress.update((null, 'Connecting pairs'));
    final circuits = <Circuit>[];

    var lastPair = pairs[0];
    for (final pair in pairs) {
      connectPair(circuits, pair);
      lastPair = pair;
      if (circuits.length == 1 && circuits[0].size == junctions.length) {
        break;
      }
    }

    await visualProgress.update((Progress.indeterminateDone(), null));
    final (left, right) = lastPair;
    return left.x * right.x;
  }
}
