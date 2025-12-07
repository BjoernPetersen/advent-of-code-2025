import 'dart:async';
import 'dart:js_interop';

import 'package:async/async.dart';
import 'package:web/web.dart';
import 'package:aoc/day.dart';

const isRunningWithWasm = bool.fromEnvironment('dart.tool.dart2wasm');

abstract base class _VisualizerBridge<T> {
  final MessagePort _port;
  final StreamController<MessageEvent> _controller;
  Stream<MessageEvent> get events => _controller.stream;

  _VisualizerBridge(MessagePort port)
    : _port = port,
      _controller = _subscribe(port);

  static StreamController<MessageEvent> _subscribe(MessagePort port) {
    final controller = StreamController<MessageEvent>();
    port.onmessage = (MessageEvent event) {
      controller.add(event);
    }.toJS;
    return controller;
  }

  void acknowledge() {
    _port.postMessage(null);
  }

  Future<void> initialize(Visualization delegator);

  Future<void> close() async {
    await _controller.close();
  }
}

final class _GridVisualizerBridge extends _VisualizerBridge<Grid<String>> {
  _GridVisualizerBridge(super.port);

  Future<Grid<String>> _decodeGrid(MessageEvent event) async {
    final data = event.data as JSArray<JSString>;
    return Grid.fromStream(
      Stream.fromIterable(data.toDart.map((e) => e.toDart)),
      (_, e) => e,
    );
  }

  @override
  Future<void> initialize(Visualization delegator) async {
    final queue = StreamQueue(events);
    final grid = await _decodeGrid(await queue.next);
    final delegate = await delegator.createGridVisualizer(grid);
    acknowledge();

    queue.rest.listen((event) async {
      final grid = await _decodeGrid(event);
      await delegate.update(grid);
      acknowledge();
    });
  }
}

final class _ProgressVisualizerBridge extends _VisualizerBridge<ProgressPair> {
  _ProgressVisualizerBridge(super.port);

  @override
  Future<void> initialize(Visualization delegator) async {
    final delegate = await delegator.createProgressVisualizer();
    events.listen((event) async {
      final data = event.data as JSArray<JSString?>;
      final [totalWorkString, workDoneString, info] = data.toDart;

      final Progress? progress;
      if (totalWorkString == null) {
        progress = null;
      } else {
        final totalWork = int.parse(totalWorkString.toDart);
        final workDone = int.parse(workDoneString!.toDart);
        progress = Progress(totalWork: totalWork, workDone: workDone);
      }

      await delegate.update((progress, info?.toDart));
      acknowledge();
    });
  }
}

final class _VisualizationManager {
  final MessagePort port;
  final Visualization visualization;
  final List<_VisualizerBridge> _bridges = [];

  _VisualizationManager._(this.port, this.visualization);

  factory _VisualizationManager.manage(
    MessagePort port,
    Visualization visualization,
  ) {
    final result = _VisualizationManager._(port, visualization);
    port.onmessage = result.onMessage.toJS;
    return result;
  }

  void onMessage(MessageEvent event) async {
    final data = event.data as JSString;
    final channel = MessageChannel();

    final _VisualizerBridge bridge = switch (data.toDart) {
      'progress' => _ProgressVisualizerBridge(channel.port1),
      'grid' => _GridVisualizerBridge(channel.port1),
      _ => throw ArgumentError(),
    };

    port.postMessage(null, [channel.port2].toJS);

    _bridges.add(bridge);
    await bridge.initialize(visualization);
  }

  Future<void> close() async {
    port.close();
    for (final bridge in _bridges) {
      await bridge.close();
    }
    _bridges.clear();
  }
}

final class AsyncDayRunner {
  final int day;
  final bool isPartOne;
  final Visualization visualization;

  AsyncDayRunner({
    required this.day,
    required this.isPartOne,
    required this.visualization,
  });

  Future<String> run(Stream<String> input) async {
    final workerFileExtension = isRunningWithWasm ? 'wasm' : 'js';
    final worker = Worker('workers/day-worker.$workerFileExtension'.toJS);
    final workerMessageController = StreamController<String>();
    final workerMessages = StreamQueue(workerMessageController.stream);

    try {
      final inputChannel = MessageChannel();
      final visualizationChannel = MessageChannel();
      final visualizationManager = _VisualizationManager.manage(
        visualizationChannel.port1,
        visualization,
      );

      worker.onmessage = (MessageEvent event) {
        final data = event.data;
        if (data.isA<JSString>()) {
          final message = (data as JSString).toDart;
          workerMessageController.add(message);
        }
      }.toJS;

      worker.postMessage(
        [day.toString().toJS, isPartOne.toString().toJS].toJS,
        [inputChannel.port2, visualizationChannel.port2].toJS,
      );

      if (await workerMessages.next != 'ready') {
        throw StateError('Unexpected message');
      }

      inputChannel.port1.postMessage(
        (await input.map((it) => it.toJS).toList()).toJS,
      );

      final result = await workerMessages.next;
      await workerMessages.cancel();
      await workerMessageController.close();
      inputChannel.port1.close();
      await visualizationManager.close();
      return result;
    } finally {
      worker.terminate();
    }
  }
}
