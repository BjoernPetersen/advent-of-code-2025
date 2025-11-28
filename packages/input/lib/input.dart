import 'dart:io';

import 'package:aoc_input/src/input/input_reader.dart';
import 'package:aoc_input/src/input/local.dart' as local;
import 'package:aoc_input/src/input/bytes.dart' as bytes_reader;
import 'package:aoc_input/src/input/strings.dart' as strings;
import 'package:aoc_input/src/input/util.dart';
export 'package:aoc_input/src/input/util.dart';

export 'package:aoc_input/src/input/input_reader.dart';

InputReader createReaderForFile(File path) => local.createReader(path);

InputReader createReaderForDay(int day, {String suffix = ''}) {
  return createReaderForFile(getDefaultPathForDay(day, suffix: suffix));
}

InputReader createRawBytesReader(Stream<List<int>> bytes) {
  return bytes_reader.createReader(bytes);
}

File getDefaultPathForDay(int day, {String suffix = ''}) {
  final filename = '${padDay(day)}$suffix.txt';
  return File('inputs/$filename');
}

InputReader createStringsReader(List<String> lines) =>
    strings.createReader(lines);
