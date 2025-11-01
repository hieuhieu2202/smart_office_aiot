import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../viewmodels/resistor_dashboard_view_state.dart';

class ResistorFailDistributionChart extends StatefulWidget {
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
  State<ResistorFailDistributionChart> createState() =>
      _ResistorFailDistributionChartState();
}

class _ResistorFailDistributionChartState
    extends State<ResistorFailDistributionChart> {
  OverlayEntry? _tooltipEntry;

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ResistorFailDistributionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slices != widget.slices || oldWidget.total != widget.total) {
      _hideTooltip();
    }
  }

  void _hideTooltip() {
    _tooltipEntry?.remove();
    _tooltipEntry = null;
  }

  void _showDetails(
    ResistorPieSlice slice,
    Offset globalPosition,
  ) {
    final overlay = Overlay.of(context);
    if (overlay == null) {
      return;
    }

    final overlayRenderBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayRenderBox == null) {
      return;
    }

    _hideTooltip();

    final overlaySize = overlayRenderBox.size;
    final localPosition = overlayRenderBox.globalToLocal(globalPosition);
    final tooltipWidth = 200.0;
    const tooltipHeight = 108.0;
    const margin = 12.0;

    final left = (localPosition.dx - tooltipWidth / 2)
        .clamp(margin, overlaySize.width - tooltipWidth - margin);
    final top = (localPosition.dy - tooltipHeight - margin)
        .clamp(margin, overlaySize.height - tooltipHeight - margin);

    final formatter = NumberFormat.decimalPattern();
    final total = widget.total;
    final percentage = total == 0
        ? 0.0
        : (slice.value / total * 100).clamp(0.0, 100.0);

    final entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideTooltip,
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: _FailTooltipCard(
                slice: slice,
                formatter: formatter,
                percentage: percentage,
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(entry);
    _tooltipEntry = entry;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern();
    final data = widget.slices.isEmpty
        ? const [ResistorPieSlice(label: 'N/A', value: 0, color: 0xFF00FFE7)]
        : widget.slices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
            ),
            const Spacer(),
            Text(
              'Total: ${formatter.format(widget.total)}',
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

              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification ||
                      notification is ScrollStartNotification ||
                      notification is OverscrollNotification) {
                    _hideTooltip();
                  }
                  return false;
                },
                child: ListView.separated(
                  itemCount: data.length,
                  physics: const BouncingScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final slice = data[index];
                    final fraction =
                        maxValue == 0 ? 0.0 : slice.value / maxValue;

                    return _FailDistributionBar(
                      label: slice.label,
                      value: formatter.format(slice.value),
                      color: Color(slice.color),
                      width: constraints.maxWidth,
                      fraction: fraction.clamp(0.0, 1.0),
                      onTap: (offset) => _showDetails(slice, offset),
                    );
                  },
                ),
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
  final void Function(Offset offset) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => onTap(details.globalPosition),
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

class _FailTooltipCard extends StatelessWidget {
  const _FailTooltipCard({
    required this.slice,
    required this.formatter,
    required this.percentage,
  });

  final ResistorPieSlice slice;
  final NumberFormat formatter;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF102033),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slice.label,
              style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            _TooltipRow(
              indicatorColor: Color(slice.color),
              label: 'Pass',
              value: formatter.format(slice.pass),
            ),
            const SizedBox(height: 8),
            _TooltipRow(
              indicatorColor: const Color(0xFFFF6388),
              label: 'Fail %',
              value: '${percentage.toStringAsFixed(2)}%',
            ),
          ],
        ),
      ),
    );
  }
}

class _TooltipRow extends StatelessWidget {
  const _TooltipRow({
    required this.indicatorColor,
    required this.label,
    required this.value,
  });

  final Color indicatorColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
