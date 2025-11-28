import 'package:aoc_input/input.dart';
import 'package:aoc_input_s3/src/input/remote_client.dart';
import 'package:dotenv/dotenv.dart';

final class _RemoteReader implements InputReader {
  final RemoteClient _client;
  final int day;
  final String suffix;

  _RemoteReader(DotEnv env, this.day, {required this.suffix})
    : _client = RemoteClient.fromEnv(env);

  @override
  Stream<String> readLines() async* {
    final encoded = _client.readBytes('${padDay(day)}$suffix.txt');
    final bytesReader = createRawBytesReader(encoded);
    yield* bytesReader.readLines();
  }
}

InputReader createReader(DotEnv env, int day, {required String suffix}) =>
    _RemoteReader(env, day, suffix: suffix);
