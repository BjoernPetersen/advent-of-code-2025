import 'package:aoc_input/input.dart';
import 'package:aoc_input_s3/src/input/remote.dart' as remote;
import 'package:dotenv/dotenv.dart';

InputReader createRemoteReaderForDay(
  int day, {
  String suffix = '',
  required DotEnv env,
}) {
  return remote.createReader(env, day, suffix: suffix);
}
