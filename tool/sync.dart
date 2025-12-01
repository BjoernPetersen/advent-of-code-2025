import 'dart:io';

import 'package:aoc_input_s3/sync.dart';
import 'package:dotenv/dotenv.dart';

Future<void> main(List<String> args) async {
  final env = DotEnv(includePlatformEnvironment: true, quiet: true);
  env.load();
  final inputsDir = Directory('packages/solutions/inputs');
  await sync(
    env,
    inputsDir: inputsDir,
    download: args.firstOrNull == 'download',
  );
}
