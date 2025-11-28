import 'dart:io';

import 'package:aoc_input/input.dart';
import 'package:test/test.dart';

void main() {
  final inputReader = createReaderForFile(File('testdata/example.txt'));

  test('Reads all lines', () async {
    final allLines = inputReader.readLines().toList();
    expect(allLines, completion(hasLength(3)));
  });

  test('Lines are trimmed', () {
    expect(inputReader.readLines().first, completion(isNot(contains('\n'))));
  });
}
