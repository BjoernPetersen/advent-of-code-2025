import 'dart:async';
import 'dart:io';

typedef Pair<T> = (T, T);

extension CharIterable on String {
  Iterable<String> get chars sync* {
    for (var i = 0; i < length; i += 1) {
      yield this[i];
    }
  }
}

extension StreamUtils<T> on Stream<T> {
  Future<int> get count => fold(0, (previous, _) => previous + 1);

    Stream<(T, T)> zipWithNext() async* {
    final iterator = StreamIterator(this);
    if (!await iterator.moveNext()) {
      return;
    }
    var last = iterator.current;

    while (await iterator.moveNext()) {
      yield (last, iterator.current);
      last = iterator.current;
    }
  }
}

extension IntStreamUtils on Stream<int> {
  Future<int> get sum => fold(0, (previous, element) => previous + element);
  Future<int> get product => reduce((previous, element) => previous * element);
}

extension IterableUtils<T> on Iterable<T> {
  int get count => fold(0, (previous, _) => previous + 1);

  Iterable<R> combined<U, R>(
    Iterable<U> other,
    R Function(T, U) combine,
  ) sync* {
    final otherIterator = other.iterator;
    for (final element in this) {
      if (!otherIterator.moveNext()) {
        throw ArgumentError('other iterable was shorter');
      }

      yield combine(element, otherIterator.current);
    }

    if (otherIterator.moveNext()) {
      throw ArgumentError('other iterable was longer');
    }
  }

  Iterable<(T, T)> zipWithNext() sync* {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return;
    }
    var last = iterator.current;

    while (iterator.moveNext()) {
      yield (last, iterator.current);
      last = iterator.current;
    }
  }
}

extension IntIterableUtils on Iterable<int> {
  int get product => reduce((l, r) => l * r);
}

const bool kIsWeb = bool.fromEnvironment('dart.library.js_util');

int get availableProcessors {
  if (kIsWeb) {
    throw StateError("Can't multithread on web");
  }
  return Platform.numberOfProcessors;
}
