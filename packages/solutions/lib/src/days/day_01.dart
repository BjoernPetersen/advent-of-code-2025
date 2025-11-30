import 'package:aoc_core/aoc_core.dart';

const kSteps = [
  Vector(x: 0, y: 0),
  Vector(x: 1, y: 0),
  Vector(x: 2, y: 0),
  Vector(x: 3, y: 0),
  Vector(x: 4, y: 0),
  Vector(x: 4, y: 1),
  Vector(x: 4, y: 2),
  Vector(x: 4, y: 3),
  Vector(x: 5, y: 3),
  Vector(x: 6, y: 3),
  Vector(x: 6, y: 4),
  Vector(x: 7, y: 4),
  Vector(x: 7, y: 3),
  Vector(x: 7, y: 2),
  Vector(x: 8, y: 2),
];

@immutable
final class PartOne extends IntPart {
  const PartOne();

  @override
  Future<int> calculate(
    Visualization visualization,
    Stream<String> input,
  ) async {
    final grid = Grid.generate(width: 16, height: 16, generator: (pos) => 'x');
    final visual = await visualization.createGridVisualizer(grid);
    var progress = Progress(totalWork: kSteps.length);
    for (final vec in kSteps) {
      grid[vec] = 'o';
      await visual.update(grid, stepInfo: vec.toString(), progress: ++progress);
    }
    return 0;
  }
}
