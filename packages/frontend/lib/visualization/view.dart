import 'dart:math';

import 'package:aoc_core/aoc_core.dart';
import 'package:aoc_frontend/visualization/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@immutable
final class VisualizationView extends StatelessWidget {
  final bool isPartOne;

  const VisualizationView({super.key, required this.isPartOne});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VisualizationBloc, VisualizationState>(
      buildWhen: (oldState, newState) =>
          oldState.getPartView(isPartOne: isPartOne) !=
          newState.getPartView(isPartOne: isPartOne),
      builder: (context, fullState) {
        final state = fullState.getPartView(isPartOne: isPartOne);

        final children = <Widget>[];
        final progressState = state.progressState;
        if (progressState != null) {
          children.add(ProgressView(progressState.progress));
          children.add(StepInfoView(progressState.stepInfo));
        }

        final gridState = state.gridState;
        if (gridState != null) {
          children.add(
            GridStateView(
              gridState.state,
              gridState.itemToString,
              showGridLines: false,
            ),
          );
        }

        return Column(mainAxisSize: .min, children: children);
      },
    );
  }
}

@immutable
final class StepInfoView extends StatelessWidget {
  final String? stepInfo;

  const StepInfoView(this.stepInfo, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(stepInfo ?? '', textScaler: TextScaler.linear(0.8));
  }
}

final class ProgressView extends StatelessWidget {
  final Progress? progress;

  const ProgressView(this.progress, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: min(MediaQuery.of(context).size.width, 200),
      child: LinearProgressIndicator(value: progress?.percentage),
    );
  }
}

@immutable
final class GridStateView<T> extends StatelessWidget {
  final bool showGridLines;
  final Grid<T> grid;
  final String Function(T)? itemToString;

  const GridStateView(
    this.grid,
    this.itemToString, {
    super.key,
    required this.showGridLines,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showGridLines
            ? Border(
                top: BorderSide(color: Colors.black),
                left: BorderSide(color: Colors.black),
              )
            : null,
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          for (final row in grid.rows)
            GridStateRow(
              row: row,
              showGridLines: showGridLines,
              itemToString: itemToString ?? (it) => it?.toString() ?? '',
            ),
        ],
      ),
    );
  }
}

final class GridStateRow<T> extends StatelessWidget {
  final bool showGridLines;
  final List<T> row;
  final String Function(T) itemToString;

  const GridStateRow({
    super.key,
    required this.showGridLines,
    required this.row,
    required this.itemToString,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        for (final item in row)
          Container(
            width: 6.0,
            height: 6.0,
            decoration: BoxDecoration(
              border: showGridLines
                  ? Border(
                      right: BorderSide(color: Colors.black),
                      bottom: BorderSide(color: Colors.black),
                    )
                  : null,
            ),
            alignment: .center,
            child: Text(itemToString(item), style: TextStyle(fontSize: 5)),
          ),
      ],
    );
  }
}
