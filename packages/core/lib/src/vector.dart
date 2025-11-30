import 'package:meta/meta.dart';

import 'dart:math';

import 'bounds.dart';

@immutable
class Vector {
  static const Vector zero = Vector();
  static const Vector north = Vector(y: -1);
  static const Vector east = Vector(x: 1);
  static const Vector south = Vector(y: 1);
  static const Vector west = Vector(x: -1);
  static const Iterable<Vector> crossDirections = [
    Vector.north,
    Vector.east,
    Vector.south,
    Vector.west,
  ];
  static const Iterable<Vector> starDirections = [
    Vector(x: 1),
    Vector(x: 1, y: 1),
    Vector(y: 1),
    Vector(x: -1, y: 1),
    Vector(x: -1),
    Vector(x: -1, y: -1),
    Vector(y: -1),
    Vector(x: 1, y: -1),
  ];

  final int x;
  final int y;

  const Vector({this.x = 0, this.y = 0});

  bool get isHorizontal {
    if (x != 0 && y != 0) {
      throw StateError('Vector is diagonal');
    }

    return x != 0;
  }

  bool get isVertical => !isHorizontal;

  Vector operator +(Vector other) {
    return Vector(x: x + other.x, y: y + other.y);
  }

  Vector operator -(Vector other) {
    return Vector(x: x - other.x, y: y - other.y);
  }

  Vector operator *(int scalar) {
    return Vector(x: x * scalar, y: y * scalar);
  }

  Vector rotate({bool clockwise = true}) {
    return clockwise ? Vector(x: -y, y: x) : Vector(x: y, y: -x);
  }

  Vector operator -() {
    return Vector(x: -x, y: -y);
  }

  Vector operator ~/(int n) {
    return Vector(x: x ~/ n, y: y ~/ n);
  }

  Vector operator %(Bounds bounds) {
    return Vector(x: x % bounds.width, y: y % bounds.height);
  }

  Vector abs() {
    return Vector(x: x.abs(), y: y.abs());
  }

  Vector get sign => Vector(x: x.sign, y: y.sign);

  int manhattanNorm() {
    final abs = this.abs();
    return abs.x + abs.y;
  }

  double norm(int p) {
    final sum = pow(x.abs(), p) + pow(y.abs(), p);

    if (p == 2) {
      // Special case for Euclidean norm in hopes that sqrt is faster than pow(n, 1/2)
      return sqrt(sum);
    }

    return pow(sum, 1 / p) as double;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vector &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() {
    return '($x, $y)';
  }
}
