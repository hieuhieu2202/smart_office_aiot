import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cells.dart';
import '../viewmodels/output_tracking_view_state.dart';
import '../viewmodels/series_utils.dart';

const Color _cardColor = Color(0xFF0F233F);
const Color _borderColor = Color(0xFF1E3F66);
const Color _headerBackground = Color(0xFF17375E);
const Color _rowBackground = Color(0xFF10253F);
const Color _altRowBackground = Color(0xFF132C4C);
const Color _activeRowBackground = Color(0xFF1B3D63);
const Color _activeRowBorder = Color(0xFF3D6BAA);

class OtMobileRowCard extends StatelessWidget {
  const OtMobileRowCard({
    super.key,
    required this.row,
    required this.hours,
    this.activeHourIndex,
    this.onStationTap,
    this.onSectionTap,
  });

  final OtRowView row;
  final List<String> hours;
  final int? activeHourIndex;
  final VoidCallback? onStationTap;
  final void Function(String section)? onSectionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final padding = EdgeInsets.symmetric(
          horizontal: isCompact ? 14 : 18,
          vertical: isCompact ? 14 : 18,
        );
        final radius = BorderRadius.circular(isCompact ? 16 : 20);

        final stationStyle = theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontSize: isCompact ? 16 : 17,
        );
        final modelStyle = theme.textTheme.bodySmall?.copyWith(
          color: Colors.white70,
          height: 1.3,
        );

        return Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: radius,
            border: Border.all(color: _borderColor.withOpacity(.7)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MobileCardHeader(
                station: row.station,
                model: row.model,
                stationStyle: stationStyle,
                modelStyle: modelStyle,
                isCompact: isCompact,
                onTap: onStationTap,
              ),
              const SizedBox(height: 12),
              _MobileSummaryChips(
                row: row,
                isCompact: isCompact,
                onStationTap: onStationTap,
              ),
              const SizedBox(height: 16),
              _MobileMetricsTable(
                constraints: constraints,
                hours: hours,
                metrics: row.metrics,
                isCompact: isCompact,
                activeHourIndex: activeHourIndex,
                onSectionTap: onSectionTap,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileCardHeader extends StatelessWidget {
  const _MobileCardHeader({
    required this.station,
    required this.model,
    required this.stationStyle,
    required this.modelStyle,
    required this.isCompact,
    this.onTap,
  });

  final String station;
  final String model;
  final TextStyle? stationStyle;
  final TextStyle? modelStyle;
  final bool isCompact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget stationLabel = Text(
      station,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: stationStyle,
    );

    if (onTap != null) {
      stationLabel = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: stationLabel,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        stationLabel,
        const SizedBox(height: 4),
        Text(
          model.isEmpty ? '-' : model,
          maxLines: isCompact ? 3 : 5,
          overflow: TextOverflow.ellipsis,
          style: modelStyle,
          softWrap: true,
        ),
      ],
    );
  }
}

class _MobileSummaryChips extends StatelessWidget {
  const _MobileSummaryChips({
    required this.row,
    required this.isCompact,
    this.onStationTap,
  });

  final OtRowView row;
  final bool isCompact;
  final VoidCallback? onStationTap;

  @override
  Widget build(BuildContext context) {
    final spacing = isCompact ? 8.0 : 12.0;
    final minWidth = isCompact ? 86.0 : 96.0;
    final valueFont = isCompact ? 16.5 : 18.0;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        _SummaryChip(
          label: 'WIP',
          value: row.wip,
          color: const Color(0xFF42A0FF),
          minWidth: minWidth,
          valueFont: valueFont,
        ),
        _SummaryChip(
          label: 'PASS',
          value: row.totalPass,
          color: kOtPassAccent,
          minWidth: minWidth,
          valueFont: valueFont,
          onTap: onStationTap,
        ),
        _SummaryChip(
          label: 'FAIL',
          value: row.totalFail,
          color: const Color(0xFFFF6B6B),
          minWidth: minWidth,
          valueFont: valueFont,
          onTap: onStationTap,
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    required this.minWidth,
    required this.valueFont,
    this.onTap,
  });

  final String label;
  final int value;
  final Color color;
  final double minWidth;
  final double valueFont;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      constraints: BoxConstraints(minWidth: minWidth),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.45)),
        color: color.withOpacity(.16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: .25,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: valueFont,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}

class _MobileMetricsTable extends StatelessWidget {
  const _MobileMetricsTable({
    required this.constraints,
    required this.hours,
    required this.metrics,
    required this.isCompact,
    this.activeHourIndex,
    this.onSectionTap,
  });

  final BoxConstraints constraints;
  final List<String> hours;
  final List<OtCellMetrics> metrics;
  final bool isCompact;
  final int? activeHourIndex;
  final void Function(String section)? onSectionTap;

  @override
  Widget build(BuildContext context) {
    if (hours.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor.withOpacity(.6)),
          color: _rowBackground,
        ),
        child: const Text(
          'Không có dữ liệu theo giờ cho trạm này.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white70,
          fontSize: isCompact ? 12.0 : 12.5,
        ) ??
        TextStyle(
          color: Colors.white70,
          fontSize: isCompact ? 12.0 : 12.5,
        );

    final headerStyle = baseStyle.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      letterSpacing: .2,
      fontSize: isCompact ? 12.5 : 13.5,
    );

    final minWidth = math.max(constraints.maxWidth, 360.0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.4),
              1: FlexColumnWidth(1.4),
              2: FlexColumnWidth(1.4),
              3: FlexColumnWidth(1.4),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder.all(
              color: _borderColor.withOpacity(.6),
              width: 0.8,
            ),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: _headerBackground),
                children: [
                  _buildHeaderCell('Khung giờ', headerStyle, alignment: Alignment.centerLeft),
                  _buildHeaderCell('PASS', headerStyle),
                  _buildHeaderCell('YR', headerStyle),
                  _buildHeaderCell('RR', headerStyle),
                ],
              ),
              ...List<TableRow>.generate(hours.length, (index) {
                final hour = hours[index];
                final metric = index < metrics.length
                    ? metrics[index]
                    : const OtCellMetrics(pass: 0, yr: 0, rr: 0);
                final bool isActive =
                    activeHourIndex != null && index == activeHourIndex;
                final bool canTapYr =
                    onSectionTap != null && metric.yr.isFinite && metric.yr > 0;
                final bool canTapRr = onSectionTap != null &&
                    metric.pass.isFinite &&
                    metric.pass > 0 &&
                    metric.rr.isFinite &&
                    metric.rr > 0;
                final rowColor = isActive
                    ? _activeRowBackground
                    : index.isEven
                        ? _rowBackground
                        : _altRowBackground;
                final TextStyle hourStyle = isActive
                    ? baseStyle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      )
                    : baseStyle;
                final Border? rowBorder = isActive
                    ? Border.all(color: _activeRowBorder, width: 1.1)
                    : null;

                return TableRow(
                  decoration: BoxDecoration(
                    color: rowColor,
                    border: rowBorder,
                  ),
                  children: [
                    _buildDataCell(
                      text: formatHourRange(hour),
                      style: hourStyle,
                      alignment: Alignment.centerLeft,
                    ),
                    _buildDataCell(
                      text: metric.pass.isFinite
                          ? metric.pass.round().toString()
                          : '0',
                      style: baseStyle.copyWith(
                        color: otPassColor(metric.pass),
                        fontWeight:
                            metric.pass > 0 ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    _buildDataCell(
                      text: otFormatRate(metric.yr),
                      style: baseStyle.copyWith(
                        color: otYieldRateColor(metric.yr),
                        fontWeight:
                            metric.yr >= 98 ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onTap: canTapYr ? () => onSectionTap!(hour) : null,
                    ),
                    _buildDataCell(
                      text: otFormatRate(metric.rr),
                      style: baseStyle.copyWith(
                        color: otRetestRateColor(metric.rr),
                        fontWeight: metric.rr > 0 && metric.rr < 3
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      onTap: canTapRr ? () => onSectionTap!(hour) : null,
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(
    String text,
    TextStyle style, {
    Alignment alignment = Alignment.center,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: isCompact ? 11 : 13,
      ),
      alignment: alignment,
      child: Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildDataCell({
    required String text,
    required TextStyle style,
    Alignment alignment = Alignment.center,
    VoidCallback? onTap,
  }) {
    Widget label = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: isCompact ? 10 : 12,
      ),
      alignment: alignment,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );

    if (onTap != null) {
      label = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: label,
        ),
      );
    }

    return label;
  }
}
