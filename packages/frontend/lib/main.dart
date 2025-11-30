import 'package:aoc/day.dart';
import 'package:aoc_frontend/state.dart';
import 'package:aoc_frontend/visualization/state.dart';
import 'package:aoc_frontend/visualization/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:timer_builder/timer_builder.dart';

const kDefaultFrameDuration = '50';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AoC Solutions',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

final class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AocBloc()),
        BlocProvider(create: (_) => VisualizationBloc()),
      ],
      child: Scaffold(
        body: const Padding(
          padding: EdgeInsets.all(5.0),
          child: SelectionGuide(),
        ),
      ),
    );
  }
}

@immutable
final class FrameDurationTextField extends StatelessWidget {
  const FrameDurationTextField({super.key});

  String? _validate(String? value) {
    if (value == null) {
      return null;
    }
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return null;
    }

    final number = int.tryParse(value);
    if (number == null) {
      return 'must be a valid integer';
    } else if (number <= 0) {
      return 'must be a positive integer';
    } else {
      return null;
    }
  }

  void _onChange(BuildContext context, String? value) {
    final controller = Provider.of<TextEditingController>(
      context,
      listen: false,
    );
    final bloc = BlocProvider.of<VisualizationBloc>(context, listen: false);
    final error = _validate(controller.text);
    if (error != null) {
      controller.text = kDefaultFrameDuration;
    }
    final millis = int.parse(controller.text.trim());
    bloc.add(SetFrameDuration(Duration(milliseconds: millis)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TextEditingController>(context);
    return TextFormField(
      controller: controller,
      keyboardType: .number,
      enableSuggestions: false,
      validator: _validate,
      onFieldSubmitted: (value) {
        _onChange(context, value);
      },
      onTapOutside: (_) {
        _onChange(context, controller.text);
      },
    );
  }
}

@immutable
final class FrameDurationConfig extends StatelessWidget {
  const FrameDurationConfig({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 5,
      children: [
        Text('Step duration (ms)'),
        InheritedProvider(
          create: (_) => TextEditingController(text: kDefaultFrameDuration),
          dispose: (context, controller) => controller.dispose(),
          child: const SizedBox(width: 100, child: FrameDurationTextField()),
        ),
      ],
    );
  }
}

final class SelectionGuide extends StatelessWidget {
  const SelectionGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AocBloc, AocState>(
      builder: (context, state) {
        final children = <Widget>[
          const FrameDurationConfig(),
          const DaySelection(),
          const Divider(),
        ];

        if (state.day != null) {
          if (state.isMultipart) {
            children.add(const PartSelection());
            children.add(const Divider());
          }

          if (state.isReady) {
            children.add(const Expanded(child: ActionArea()));
          } else if (state.runStates.isNotEmpty) {
            children.add(const Expanded(child: RunningState()));
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: children,
        );
      },
    );
  }
}

final class DaySelection extends StatelessWidget {
  const DaySelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5.0,
      runSpacing: 3.0,
      children: [for (final day in availableDays) DayCard(day)],
    );
  }
}

final class DayCard extends StatelessWidget {
  final int day;

  const DayCard(this.day, {super.key});

  @override
  Widget build(BuildContext context) {
    final AocBloc bloc = BlocProvider.of(context);
    return BlocBuilder(
      bloc: bloc,
      builder: (context, AocState state) => ChoiceChip(
        label: Text('Day $day'),
        selected: state.day == day,
        onSelected: (newValue) {
          if (newValue) {
            bloc.add(DaySelected(day));
          }
        },
      ),
    );
  }
}

final class PartSelection extends StatelessWidget {
  const PartSelection({super.key});

  @override
  Widget build(BuildContext context) {
    final AocBloc bloc = BlocProvider.of(context);
    return BlocBuilder(
      bloc: bloc,
      builder: (context, AocState state) {
        return Row(
          spacing: 5,
          children: [
            ChoiceChip(
              label: const Text('Part 1'),
              selected: state.enablePartOne,
              onSelected: (isSelected) => bloc.add(PartOneToggled(isSelected)),
            ),
            ChoiceChip(
              label: const Text('Part 2'),
              selected: state.enablePartTwo,
              onSelected: (isSelected) => bloc.add(PartTwoToggled(isSelected)),
            ),
          ],
        );
      },
    );
  }
}

final class ActionArea extends StatelessWidget {
  const ActionArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          final bloc = BlocProvider.of<AocBloc>(context);
          bloc.add(OpenFilePicker(BlocProvider.of<VisualizationBloc>(context)));
        },
        child: const Text('Select input file'),
      ),
    );
  }
}

final class RunningState extends StatelessWidget {
  const RunningState({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<AocBloc>(context);
    return DefaultTextStyle.merge(
      style: const TextStyle(fontSize: 30),
      child: Center(
        child: BlocBuilder(
          bloc: bloc,
          builder: (context, AocState state) => Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              for (final runState in state.runStates) RunStateView(runState),
              const VisualizationView(),
              if (!state.isRunning)
                IconButton(
                  onPressed: () {
                    BlocProvider.of<VisualizationBloc>(
                      context,
                    ).add(ResetVisualization());
                    bloc.add(const ClearResult());
                  },
                  icon: const Icon(Icons.undo),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class RunStateView extends StatelessWidget {
  final RunState state;

  const RunStateView(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        TimerBuilder.periodic(
          const Duration(milliseconds: 100),
          builder: (context) => Text(
            (state.endTime ?? DateTime.now())
                .difference(state.startTime)
                .toString(),
          ),
        ),
        ResultIndicator(state),
        SelectionArea(child: ResultText(state)),
      ],
    );
  }
}

final class ResultIndicator extends StatelessWidget {
  final RunState state;

  const ResultIndicator(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    if (state.isDone) {
      if (state.isSuccessful) {
        return const Icon(Icons.check_box, color: Colors.greenAccent);
      } else {
        return const Icon(Icons.error, color: Colors.red);
      }
    } else {
      return const CircularProgressIndicator();
    }
  }
}

final class ResultText extends StatelessWidget {
  final RunState state;

  const ResultText(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    if (state.isDone) {
      if (state.isSuccessful) {
        return Text(state.result!);
      } else {
        return Text('Error: ${state.error}');
      }
    } else {
      return const Offstage();
    }
  }
}
