import 'dart:async';
import 'dart:js_interop';

import 'package:aoc/day.dart';
import 'package:web/web.dart';

final class _DayWorker {
  final int day;
  final bool isPartOne;
  final Visualization visualization;

  _DayWorker({
    required this.day,
    required this.isPartOne,
    required this.visualization,
  });

  Future<String> calculate({required Stream<String> input}) async {
    final dayImpl = getDay(day);
    final part = isPartOne ? dayImpl.partOne : dayImpl.partTwo;
    if (part == null) {
      throw ArgumentError('Day $day part 2 is not implemented');
    }

    return await part.calculateString(visualization, input);
  }
}

abstract base class _ChannelVisualizer<T> implements Visualizer<T> {
  final MessagePort port;
  final StreamIterator<void> messages;

  _ChannelVisualizer(this.port) : messages = _subscribe(port);

  static StreamIterator<void> _subscribe(MessagePort port) {
    final controller = StreamController<void>();
    port.onmessage = (MessageEvent event) {
      controller.add(null);
    }.toJS;
    return StreamIterator(controller.stream);
  }
}

final class _GridVisualizer<T> extends _ChannelVisualizer<Grid<T>> {
  final String Function(T)? _itemToString;
  _GridVisualizer(super.port, this._itemToString);

  @override
  Future<void> update(Grid<T> state) async {
    final toString = _itemToString ?? (e) => e.toString();
    final gridLines = state.rows
        .map((row) => row.map(toString).join())
        .map((e) => e.toJS)
        .toList(growable: false)
        .toJS;
    port.postMessage(gridLines);
    await messages.moveNext();
  }
}

final class _ProgressVisualizer extends _ChannelVisualizer<ProgressPair> {
  _ProgressVisualizer(super._port);

  @override
  Future<void> update(ProgressPair state) async {
    final (progress, info) = state;
    port.postMessage(
      [
        progress?.totalWork.toString().toJS,
        progress?.workDone.toString().toJS,
        info?.toJS,
      ].toJS,
    );
    await messages.moveNext();
  }
}

final class _ChanneledVisualization implements Visualization {
  final MessagePort _port;

  _ChanneledVisualization(this._port);

  @override
  Future<Visualizer<Grid<I>>> createGridVisualizer<I>(
    Grid<I> grid, [
    String Function(I)? itemToString,
  ]) async {
    final gridPort = Completer<MessagePort>();
    _port.onmessage = (MessageEvent event) {
      gridPort.complete(event.ports[0]);
    }.toJS;

    _port.postMessage('grid'.toJS);
    final port = await gridPort.future;
    _port.onmessage = null;
    final visualizer = _GridVisualizer(port, itemToString);
    await visualizer.update(grid);
    return visualizer;
  }

  @override
  Future<Visualizer<ProgressPair>> createProgressVisualizer() async {
    final progressPort = Completer<MessagePort>();
    _port.onmessage = (MessageEvent event) {
      progressPort.complete(event.ports[0]);
    }.toJS;

    _port.postMessage('progress'.toJS);
    final port = await progressPort.future;
    _port.onmessage = null;
    return _ProgressVisualizer(port);
  }
}

@JS()
external DedicatedWorkerGlobalScope get self;

final class _InputTransfer {
  final StreamController<String> _controller;

  Stream<String> get input => _controller.stream;

  _InputTransfer() : _controller = StreamController();

  void onMessage(MessageEvent event) {
    final data = event.data as JSArray<JSString>;
    data.toDart.map((e) => e.toDart).forEach(_controller.add);
    unawaited(_controller.close());
  }
}

Future<void> main() async {
  final finish = Completer<String>();

  var isInitialized = false;

  self.onmessage = (MessageEvent event) {
    if (isInitialized) {
      finish.completeError('Already initialized');
      return;
    }

    final inputTransfer = _InputTransfer();
    final inputPort = event.ports[0];
    inputPort.onmessage = inputTransfer.onMessage.toJS;
    final visualizationPort = event.ports[1];
    final visualization = _ChanneledVisualization(visualizationPort);

    final list = (event.data as JSArray<JSString>);
    final day = int.parse(list[0].toDart);
    final isPartOne = bool.parse(list[1].toDart);
    final isolate = _DayWorker(
      day: day,
      isPartOne: isPartOne,
      visualization: visualization,
    );
    isolate
        .calculate(input: inputTransfer.input)
        .then(finish.complete, onError: finish.completeError);

    isInitialized = true;
    self.postMessage('ready'.toJS);
  }.toJS;

  try {
    final result = await finish.future;
    self.postMessage(result.toJS);
  } catch (e) {
    self.reportError(e.toString().toJS);
  }
}
