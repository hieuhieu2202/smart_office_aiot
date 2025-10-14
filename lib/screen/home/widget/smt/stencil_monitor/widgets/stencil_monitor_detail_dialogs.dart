part of 'package:smart_factory/screen/home/widget/smt/stencil_monitor/stencil_monitor_screen.dart';

extension _StencilMonitorDetailDialogs on _StencilMonitorScreenState {
  Future<void> _showBreakdownDetail(
    BuildContext context,
    _OverviewCardData data,
  ) async {
    if (data.slices.isEmpty) return;

    final sorted = data.slices.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (sum, slice) => sum + slice.value);
    final scrollController = ScrollController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        final bottomPadding = media.viewPadding.bottom;
        final palette = _StencilColorScheme.of(ctx);
        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: FractionallySizedBox(
            heightFactor: 0.75,
            child: _DetailSheetContainer(
              title: '${data.title} • $total total',
              controller: scrollController,
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final slice = sorted[index];
                  final rank = index + 1;
                  final ratio = total == 0
                      ? 0.0
                      : (slice.value / total).clamp(0.0, 1.0);
                  final accent = data.accent;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: accent.withOpacity(0.35)),
                      gradient: LinearGradient(
                        colors: [accent.withOpacity(0.12), Colors.transparent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: accent.withOpacity(0.45)),
                              ),
                              child: Text(
                                '$rank',
                                style: GlobalTextStyles.bodySmall(
                                  isDark: palette.isDark,
                                ).copyWith(
                                  fontFamily: _StencilTypography.heading,
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                slice.label.trim().isEmpty
                                    ? 'Unknown'
                                    : slice.label.trim(),
                                style: GlobalTextStyles.bodyMedium(
                                  isDark: palette.isDark,
                                ).copyWith(
                                  fontFamily: _StencilTypography.numeric,
                                  fontSize: 14,
                                  color: palette.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              slice.value.toString(),
                              style: GlobalTextStyles.bodyMedium(
                                isDark: palette.isDark,
                              ).copyWith(
                                fontFamily: _StencilTypography.heading,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: ratio.toDouble(),
                          minHeight: 6,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                          backgroundColor: accent.withOpacity(0.18),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
    scrollController.dispose();
  }

  Future<void> _showLineTrackingDetail(
    BuildContext context,
    List<_LineTrackingDatum> items, {
    String initialQuery = '',
  }) async {
    if (items.isEmpty) return;

    final sorted = items.toList()
      ..sort((a, b) => b.hours.compareTo(a.hours));
    final maxHours = sorted.fold<double>(0, (max, item) => item.hours > max ? item.hours : max);
    final normalizedMax = maxHours <= 0 ? 1.0 : maxHours + 0.5;
    final scrollController = ScrollController();
    final queryController = TextEditingController(text: initialQuery);
    final filteredNotifier =
        ValueNotifier<List<_LineTrackingDatum>>(_filterLineTrackingData(sorted, initialQuery));

    List<_LineTrackingDatum> _applyFilter(String raw) {
      return _filterLineTrackingData(sorted, raw);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        final bottomPadding = media.viewPadding.bottom;
        final palette = _StencilColorScheme.of(ctx);
        final previous = _palette;
        _palette = palette;

        try {
          return Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: FractionallySizedBox(
              heightFactor: 0.85,
              child: _DetailSheetContainer(
                title: 'Line tracking (${sorted.length})',
                controller: scrollController,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: TextField(
                        controller: queryController,
                        onChanged: (value) =>
                            filteredNotifier.value = _applyFilter(value),
                        style: GlobalTextStyles.bodySmall(isDark: palette.isDark)
                            .copyWith(
                          fontFamily: _StencilTypography.numeric,
                          color: palette.onSurface,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search, color: _textSecondary),
                          hintText: 'Search line, location, or stencil SN',
                          hintStyle:
                              GlobalTextStyles.bodySmall(isDark: palette.isDark)
                                  .copyWith(
                            fontFamily: _StencilTypography.numeric,
                            color: palette.onSurfaceMuted,
                          ),
                          filled: true,
                          fillColor: palette.surfaceOverlay.withOpacity(0.6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: palette.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: palette.dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: palette.accentSecondary),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ValueListenableBuilder<List<_LineTrackingDatum>>(
                        valueListenable: filteredNotifier,
                        builder: (_, filtered, __) {
                          if (filtered.isEmpty) {
                            final query = queryController.text.trim();
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  query.isEmpty
                                      ? 'No line tracking data to display'
                                      : 'No lines found for "$query"',
                                  style: GlobalTextStyles.bodySmall(
                                          isDark: palette.isDark)
                                      .copyWith(
                                    fontFamily: _StencilTypography.numeric,
                                    color: _textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final datum = filtered[index];
                              return _buildLineProgressRow(
                                datum,
                                normalizedMax,
                                onTap: () {
                                  final detail = _findDetailBySn(datum.stencilSn);
                                  if (detail != null) {
                                    Navigator.of(ctx).pop();
                                    _showSingleDetail(context, detail, datum.hours);
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } finally {
          _palette = previous;
        }
      },
    );
    scrollController.dispose();
    queryController.dispose();
    filteredNotifier.dispose();
  }

  Future<void> _showSingleDetail(
    BuildContext context,
    StencilDetail detail,
    double diffHours,
  ) async {
    final scrollController = ScrollController();
    final accent = _lineHoursColor(diffHours);
    final stencilSn = detail.stencilSn?.trim().isNotEmpty == true
        ? detail.stencilSn!.trim()
        : '--';
    final lineNameLabel = detail.lineName?.trim().isNotEmpty == true
        ? detail.lineName!.trim()
        : null;
    final locationLabel = detail.location?.trim().isNotEmpty == true
        ? detail.location!.trim()
        : null;
    final lineTitle = lineNameLabel ?? locationLabel ?? (stencilSn != '--' ? stencilSn : 'Detail');
    final lineLocationParts = [
      if (lineNameLabel != null) lineNameLabel,
      if (locationLabel != null) locationLabel,
    ];
    final lineLocationText = lineLocationParts.isEmpty
        ? '--'
        : lineLocationParts.join(' • ');
    final statusLabel = detail.statusLabel?.trim().isNotEmpty == true
        ? detail.statusLabel!.trim()
        : 'Unknown';
    final customerLabel = detail.customerLabel?.trim().isNotEmpty == true
        ? detail.customerLabel!.trim()
        : '--';
    final factoryLabel = detail.floorLabel?.trim().isNotEmpty == true
        ? detail.floorLabel!.trim()
        : '--';
    final processLabel = detail.process?.trim().isNotEmpty == true
        ? detail.process!.trim()
        : 'Unknown';
    final vendorLabel = detail.vendorName.trim().isNotEmpty
        ? detail.vendorName.trim()
        : 'Unknown';
    final useTimes = detail.totalUseTimes ?? 0;
    final standardText = detail.standardTimes != null
        ? '${detail.standardTimes}'
        : 'Unknown';
    final hoursText = '${diffHours.toStringAsFixed(2)} h';
    final dateText = detail.startTime != null
        ? _dateFormat.format(detail.startTime!)
        : 'Unknown';
    final checkText = detail.checkTime != null
        ? _dateFormat.format(detail.checkTime!)
        : 'Unknown';

    final rows = [
      _DetailEntry(label: 'Stencil SN', value: stencilSn, accent: accent),
      _DetailEntry(label: 'Line / Location', value: lineLocationText),
      _DetailEntry(label: 'Customer', value: customerLabel),
      _DetailEntry(label: 'Factory', value: factoryLabel),
      _DetailEntry(label: 'Status', value: statusLabel),
      _DetailEntry(label: 'Hours running', value: hoursText, accent: accent),
      _DetailEntry(label: 'Start time', value: dateText),
      _DetailEntry(label: 'Check time', value: checkText),
      _DetailEntry(label: 'Use times', value: '$useTimes'),
      _DetailEntry(label: 'Standard times', value: standardText),
      _DetailEntry(label: 'Process', value: processLabel),
      _DetailEntry(label: 'Vendor', value: vendorLabel),
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        final bottomPadding = media.viewPadding.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: FractionallySizedBox(
            heightFactor: 0.7,
            child: _DetailSheetContainer(
              title: lineTitle,
              controller: scrollController,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _DetailInfoTable(entries: rows),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailEntry {
  const _DetailEntry({
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;
}

class _DetailInfoTable extends StatelessWidget {
  const _DetailInfoTable({required this.entries});

  final List<_DetailEntry> entries;

  @override
  Widget build(BuildContext context) {
    final palette = _StencilColorScheme.of(context);
    final baseLabelStyle = GlobalTextStyles.bodySmall(isDark: palette.isDark);
    final baseValueStyle = GlobalTextStyles.bodyMedium(isDark: palette.isDark);

    final labelStyle = baseLabelStyle.copyWith(
      fontFamily: _StencilTypography.body,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: palette.onSurfaceMuted,
      letterSpacing: 0.2,
    );
    final valueStyle = baseValueStyle.copyWith(
      fontFamily: _StencilTypography.body,
      fontSize: 18,
      color: palette.onSurface,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
    const cellPadding = EdgeInsets.symmetric(vertical: 8, horizontal: 6);

    Widget buildLabel(String text) {
      return Padding(
        padding: cellPadding,
        child: Text(
          text,
          style: labelStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    Widget buildValue(_DetailEntry entry) {
      final accentStyle = valueStyle.copyWith(
        color: entry.accent ?? palette.onSurface,
        fontWeight: entry.accent != null ? FontWeight.w700 : valueStyle.fontWeight,
      );

      return Padding(
        padding: cellPadding,
        child: Text(
          entry.value,
          style: accentStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 420;
        final rowDividerColor = palette.dividerColor.withOpacity(0.7);
        final columnWidths = isWide
            ? const <int, TableColumnWidth>{
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1.4),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1.4),
              }
            : const <int, TableColumnWidth>{
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1.6),
              };

        final rows = <TableRow>[];

        if (isWide) {
          for (var i = 0; i < entries.length; i += 2) {
            final left = entries[i];
            final right = i + 1 < entries.length ? entries[i + 1] : null;

            rows.add(
              TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: rowDividerColor, width: 1),
                  ),
                ),
                children: [
                  buildLabel(left.label),
                  buildValue(left),
                  if (right != null) ...[
                    buildLabel(right.label),
                    buildValue(right),
                  ] else ...[
                    const SizedBox.shrink(),
                    const SizedBox.shrink(),
                  ],
                ],
              ),
            );
          }
        } else {
          for (final entry in entries) {
            rows.add(
              TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: rowDividerColor, width: 1),
                  ),
                ),
                children: [
                  buildLabel(entry.label),
                  buildValue(entry),
                ],
              ),
            );
          }
        }

        return Table(
          columnWidths: columnWidths,
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: rows,
        );
      },
    );
  }
}
