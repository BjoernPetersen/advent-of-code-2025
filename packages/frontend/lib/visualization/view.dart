import 'dart:math';

import 'package:aoc_core/aoc_core.dart';
import 'package:aoc_frontend/visualization/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class VisualizationView extends StatelessWidget {
  const VisualizationView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VisualizationBloc, VisualizationState>(
      builder: (context, state) {
        return Row(
          spacing: 10,
          mainAxisSize: .min,
          children: [
            for (final gridState in state.gridStates) GridStateView(gridState),
          ],
        );
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
  final GridState<T> gridState;

  const GridStateView(this.gridState, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        ProgressView(gridState.progress),
        StepInfoView(gridState.stepInfo),
        Divider(),
        AocGridView(gridState.grid, gridState.itemToString),
      ],
    );
  }
}

@immutable
final class AocGridView<T> extends StatelessWidget {
  final Grid<T> grid;
  final String Function(T)? itemToString;

  const AocGridView(this.grid, this.itemToString, {super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black),
          left: BorderSide(color: Colors.black),
        ),
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          for (final row in grid.rows)
            GridStateRow(
              row: row,
              itemToString: itemToString ?? (it) => it?.toString() ?? '',
            ),
        ],
      ),
    );
  }
}

final class GridStateRow<T> extends StatelessWidget {
  final List<T> row;
  final String Function(T) itemToString;

  const GridStateRow({
    super.key,
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
            width: 20.0,
            height: 20.0,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.black),
                bottom: BorderSide(color: Colors.black),
              ),
            ),
            alignment: .center,
            child: Text(itemToString(item), style: TextStyle(fontSize: 15)),
          ),
      ],
    );
  }
}
