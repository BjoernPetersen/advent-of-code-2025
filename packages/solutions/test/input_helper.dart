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
  env.load();

  if (env['USE_LOCAL_STORAGE'] == 'false') {
    print('Using remote storage due to override');
    return createRemoteReaderForDay(dayNum, env: env);
  }

  return createReaderForDay(dayNum, suffix: suffix);
}
