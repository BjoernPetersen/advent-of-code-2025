import 'package:meta/meta.dart';

import 'vector.dart';

@immutable
final class Bounds {
  final int width;
  final int height;

  const Bounds._({required this.width, required this.height});

  factory Bounds({required int width, required int height}) {
    if (width <= 0) {
      throw ArgumentError.value(width, 'width');
    }

    if (height <= 0) {
      throw ArgumentError.value(height, 'height');
    }

    return Bounds._(width: width, height: height);
  }

  bool contains(Vector pos) {
    return pos.x >= 0 && pos.y >= 0 && pos.x < width && pos.y < height;
  }

  Vector get topLeft => Vector.zero;

  Vector get topRight => Vector(x: width - 1);

  Vector get bottomLeft => Vector(y: height - 1);

  Vector get bottomRight => Vector(x: width - 1, y: height - 1);

  Vector get middle {
    if (width % 2 == 0 || height % 2 == 0) {
      throw StateError("Even width or height, so there's no middle");
    }

    return Vector(x: width ~/ 2, y: height ~/ 2);
  }

  Iterable<Vector> get corners => [topLeft, topRight, bottomLeft, bottomRight];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bounds &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => width.hashCode ^ height.hashCode;

  @override
  String toString() {
    return 'Bounds(${width}x$height)';
  }
}
