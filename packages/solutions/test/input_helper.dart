import 'dart:io';

import 'package:aoc_input/input.dart';
import 'package:aoc_input_s3/input_s3.dart';
import 'package:dotenv/dotenv.dart';

InputReader getExampleReader(int dayNum, String name) {
  final file = File('examples/${dayNum.toString().padLeft(2, '0')}/$name.txt');
  return createReaderForFile(file);
}

InputReader getInputReader(int dayNum, {String suffix = ''}) {
  final env = DotEnv(includePlatformEnvironment: true, quiet: true);
  if (env['USE_LOCAL_STORAGE'] == 'true') {
    print('Using local storage due to override');
    return createReaderForDay(dayNum, suffix: suffix);
  }

  return createRemoteReaderForDay(dayNum, env: env);
}
