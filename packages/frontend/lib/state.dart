import 'package:aoc/day.dart';
import 'package:aoc_input/input.dart';
import 'package:aoc_frontend/input.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'async/runner.dart';

@immutable
sealed class AocEvent {
  const AocEvent();
}

@immutable
final class DaySelected extends AocEvent {
  final int day;

  const DaySelected(this.day);
}

@immutable
final class PartOneToggled extends AocEvent {
  final bool isEnabled;

  const PartOneToggled(this.isEnabled);
}

@immutable
final class PartTwoToggled extends AocEvent {
  final bool isEnabled;

  const PartTwoToggled(this.isEnabled);
}

@immutable
final class OpenFilePicker extends AocEvent {
  final Visualization Function({required bool isPartOne}) getVisualization;

  const OpenFilePicker(this.getVisualization);
}

@immutable
final class ClearResult extends AocEvent {
  const ClearResult();
}

@immutable
final class RunState {
  final bool isPartOne;
  final DateTime startTime;
  final DateTime? endTime;
  final String? result;
  final String? error;

  bool get isDone => endTime != null;

  bool get isSuccessful => isDone && result != null;

  const RunState._({
    required this.isPartOne,
    required this.startTime,
    required DateTime this.endTime,
    required this.result,
    required this.error,
  });

  RunState.started({required this.isPartOne})
    : startTime = DateTime.now(),
      endTime = null,
      result = null,
      error = null;

  RunState failed(String error) {
    if (isDone) {
      throw StateError('Already done');
    }
    return RunState._(
      isPartOne: isPartOne,
      startTime: startTime,
      endTime: DateTime.now(),
      result: result,
      error: error,
    );
  }

  RunState success(String result) {
    if (isDone) {
      throw StateError('Already done');
    }
    return RunState._(
      isPartOne: isPartOne,
      startTime: startTime,
      endTime: DateTime.now(),
      result: result,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunState &&
          runtimeType == other.runtimeType &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          result == other.result &&
          error == other.error;

  @override
  int get hashCode =>
      startTime.hashCode ^ endTime.hashCode ^ result.hashCode ^ error.hashCode;
}

@immutable
final class AocState {
  final int? day;
  final bool enablePartOne;
  final bool enablePartTwo;
  final List<RunState> runStates;

  bool get isRunning => runStates.any((e) => !e.isDone);

  bool get isReady =>
      day != null && (enablePartOne || enablePartTwo) && runStates.isEmpty;

  bool get isMultipart {
    final day = this.day;
    if (day == null) {
      throw StateError('No day selected');
    }
    return getDay(day).partTwo != null;
  }

  const AocState.initial()
    : day = null,
      enablePartOne = true,
      enablePartTwo = false,
      runStates = const [];

  const AocState._({
    required this.day,
    required this.enablePartOne,
    required this.enablePartTwo,
    required this.runStates,
  });

  AocState withDay(int day) {
    if (isRunning) {
      return this;
    }
    return AocState._(
      day: day,
      enablePartOne: true,
      enablePartTwo: getDay(day).partTwo != null,
      runStates: const [],
    );
  }

  AocState setPartOneEnabled(bool isEnabled) {
    if (day == null || isRunning) {
      return this;
    }

    return AocState._(
      day: day,
      enablePartOne: isEnabled,
      enablePartTwo: enablePartTwo,
      runStates: const [],
    );
  }

  AocState setPartTwoEnabled(bool isEnabled) {
    if (day == null || isRunning) {
      return this;
    }

    return AocState._(
      day: day,
      enablePartOne: enablePartOne,
      enablePartTwo: isEnabled,
      runStates: const [],
    );
  }

  AocState updateRunState(List<RunState> states) {
    return AocState._(
      day: day,
      enablePartOne: enablePartOne,
      enablePartTwo: enablePartTwo,
      runStates: List.unmodifiable(states),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AocState &&
          runtimeType == other.runtimeType &&
          day == other.day &&
          enablePartOne == other.enablePartOne &&
          enablePartTwo == other.enablePartTwo &&
          runStates == other.runStates;

  @override
  int get hashCode =>
      day.hashCode ^
      enablePartOne.hashCode ^
      enablePartTwo.hashCode ^
      runStates.hashCode;
}

final class AocBloc extends Bloc<AocEvent, AocState> {
  AocBloc() : super(const AocState.initial()) {
    on<DaySelected>((event, emit) => emit(state.withDay(event.day)));
    on<PartOneToggled>(
      (event, emit) => emit(state.setPartOneEnabled(event.isEnabled)),
    );
    on<PartTwoToggled>(
      (event, emit) => emit(state.setPartTwoEnabled(event.isEnabled)),
    );
    on<OpenFilePicker>(_pickFile, transformer: droppable());
    on<ClearResult>((event, emit) => emit(state.updateRunState([])));
  }

  Future<void> _pickFile(OpenFilePicker event, Emitter<AocState> emit) async {
    if (!state.isReady) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      lockParentWindow: true,
      withData: false,
      withReadStream: true,
    );
    if (result == null) {
      return;
    }

    final file = result.files.single;
    final inputReader = CachedInputReader(
      createRawBytesReader(file.readStream!),
    );

    final parts = <bool>{
      if (state.enablePartOne) true,
      if (state.enablePartTwo) false,
    };
    emit(
      state.updateRunState(
        parts
            .map((isPartOne) => RunState.started(isPartOne: isPartOne))
            .toList(growable: false),
      ),
    );

    final tasks = parts.map((isPartOne) {
      final runner = AsyncDayRunner(
        day: state.day!,
        isPartOne: isPartOne,
        visualization: event.getVisualization(isPartOne: isPartOne),
      );
      return runner.run(inputReader.readLines());
    });
    await Future.wait(tasks.mapIndexed((i, e) => _watch(emit, i, e)));
  }

  Future<void> _watch(
    Emitter<AocState> emit,
    int runIndex,
    Future<String> task,
  ) async {
    try {
      final result = await task;

      final runStates = state.runStates.toList(growable: false);
      runStates[runIndex] = runStates[runIndex].success(result);
      emit(state.updateRunState(runStates));
    } catch (e) {
      final runStates = state.runStates.toList(growable: false);
      runStates[runIndex] = runStates[runIndex].failed(e.toString());
      emit(state.updateRunState(runStates));
    }
  }
}
