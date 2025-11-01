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

              void showDetails(ResistorPieSlice slice) {
                final percentage = total == 0
                    ? 0.0
                    : (slice.value / total * 100).clamp(0.0, 100.0);

                showDialog<void>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      backgroundColor: const Color(0xFF0F1C2E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        slice.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailRow(
                            label: 'Pass',
                            value: formatter.format(slice.pass),
                          ),
                          const SizedBox(height: 8),
                          _DetailRow(
                            label: 'Fail %',
                            value: '${percentage.toStringAsFixed(2)}%',
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              }

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
                    onTap: () => showDetails(slice),
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
    required this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final double width;
  final double fraction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x3300FFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x2200FFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 16,
              width: width,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            value,
                            style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
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
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
