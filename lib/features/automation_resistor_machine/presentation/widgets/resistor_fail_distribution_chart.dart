import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../viewmodels/resistor_dashboard_view_state.dart';

class ResistorFailDistributionChart extends StatelessWidget {
  const ResistorFailDistributionChart({
    super.key,
    required this.slices,
    required this.total,
    this.title = 'FAIL DISTRIBUTION',
  });

  final List<ResistorPieSlice> slices;
  final int total;
  final String title;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern();
    final data = slices.isEmpty
        ? const [ResistorPieSlice(label: 'N/A', value: 0, color: 0xFF00FFE7)]
        : slices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
            ),
            const Spacer(),
            Text(
              'Total: ${formatter.format(total)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxValue = data.fold<int>(
                0,
                (previousValue, element) =>
                    element.value > previousValue ? element.value : previousValue,
              );

              return ListView.separated(
                itemCount: data.length,
                physics: const BouncingScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final slice = data[index];
                  final fraction = maxValue == 0 ? 0.0 : slice.value / maxValue;

                  return _FailDistributionBar(
                    label: slice.label,
                    value: formatter.format(slice.value),
                    color: Color(slice.color),
                    width: constraints.maxWidth,
                    fraction: fraction.clamp(0.0, 1.0),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FailDistributionBar extends StatelessWidget {
  const _FailDistributionBar({
    required this.label,
    required this.value,
    required this.color,
    required this.width,
    required this.fraction,
  });

  final String label;
  final String value;
  final Color color;
  final double width;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x3300FFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x2200FFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 12,
            width: width,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: const Color(0x3300FFFF)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.15),
                            color,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
