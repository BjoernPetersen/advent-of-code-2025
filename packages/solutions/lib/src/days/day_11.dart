import 'package:aoc_core/aoc_core.dart';

@immutable
final class Node {
  final String name;
  final Set<String> connections;

  const Node._(this.name, this.connections);

  const Node.end() : name = 'out', connections = const {};

  factory Node.fromString(String line) {
    final [name, rest] = line.split(': ');
    final connections = rest.split(' ');
    return Node._(name, Set.unmodifiable(connections));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Node && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() {
    return name;
  }

  Iterable<Node> getDescendants(Graph graph) sync* {
    for (final connection in connections) {
      yield graph[connection];
    }
  }
}

@immutable
final class Graph {
  final Node start;
  final Node end;
  final Map<String, Node> _nodes;

  Graph({
    required this.start,
    required this.end,
    required Map<String, Node> nodes,
  }) : _nodes = nodes;

  Node operator [](String name) {
    final result = _nodes[name];
    if (result == null) {
      throw StateError('Node $name not found');
    }
    return result;
  }
}

Future<Graph> parseInput(Stream<String> input) async {
  Node? start;
  final end = Node.end();

  final nodes = <String, Node>{'out': end};

  await for (final line in input) {
    final node = Node.fromString(line);
    nodes[node.name] = node;
    if (node.name == 'you') {
      start = node;
    }
  }

  return Graph(start: start!, end: end, nodes: nodes);
}

int findPaths({
  required Node start,
  required Node end,
  required Graph graph,
  required Map<Node, int> canReach,
}) {
  if (start == end) {
    return 1;
  }

  final existing = canReach[start];
  if (existing != null) {
    return existing;
  }

  var paths = 0;
  for (final node in start.getDescendants(graph)) {
    paths += findPaths(start: node, end: end, graph: graph, canReach: canReach);
  }

  canReach[start] = paths;
  return paths;
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
    final graph = await parseInput(input);

    final result = findPaths(
      start: graph.start,
      end: graph.end,
      graph: graph,
      canReach: {},
    );

    await visualProgress.update((Progress.indeterminateDone(), null));
    return result;
  }
}
