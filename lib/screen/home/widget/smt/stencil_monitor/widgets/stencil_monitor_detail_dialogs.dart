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
    final lineTitle =
        (detail.lineName?.trim().isNotEmpty == true ? detail.lineName!.trim() : null) ??
            (detail.location?.trim().isNotEmpty == true ? detail.location!.trim() : null) ??
            (detail.stencilSn?.trim().isNotEmpty == true ? detail.stencilSn!.trim() : 'Detail');
    final locationLabel =
        detail.location?.trim().isNotEmpty == true ? detail.location!.trim() : '--';
    final lineLabel =
        detail.lineName?.trim().isNotEmpty == true ? detail.lineName!.trim() : locationLabel;
    final stencilSn = detail.stencilSn?.trim().isNotEmpty == true
        ? detail.stencilSn!.trim()
        : '--';
    final statusLabel = detail.statusLabel?.trim().isNotEmpty == true
        ? detail.statusLabel!.trim()
        : 'Unknown';
    final useTimes = detail.totalUseTimes ?? 0;
    final standardTimes = detail.standardTimes;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        final bottomPadding = media.viewPadding.bottom;
        final palette = _StencilColorScheme.of(ctx);
        final dateText = detail.startTime != null
            ? _dateFormat.format(detail.startTime!)
            : 'Unknown';
        final checkText = detail.checkTime != null
            ? _dateFormat.format(detail.checkTime!)
            : 'Unknown';

        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: FractionallySizedBox(
            heightFactor: 0.65,
            child: _DetailSheetContainer(
              title: lineTitle,
              controller: scrollController,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final summarySection = _DetailSummarySection(
                        accent: accent,
                        lineLabel: lineLabel,
                        stencilSn: stencilSn,
                        status: statusLabel,
                        location: locationLabel,
                        diffHours: diffHours,
                        useTimes: useTimes,
                        standardTimes: standardTimes,
                      );
                      final infoTable = _DetailInfoTable(
                        groups: [
                          _DetailInfoGroup(
                            title: 'Assignment',
                            rows: [
                              _DetailInfoRow('Line', lineLabel),
                              _DetailInfoRow('Location', locationLabel),
                              _DetailInfoRow(
                                'Customer',
                                detail.customerLabel?.trim().isNotEmpty == true
                                    ? detail.customerLabel!.trim()
                                    : '--',
                              ),
                              _DetailInfoRow(
                                'Factory',
                                detail.floorLabel?.trim().isNotEmpty == true
                                    ? detail.floorLabel!.trim()
                                    : '--',
                              ),
                            ],
                          ),
                          _DetailInfoGroup(
                            title: 'Specification',
                            rows: [
                              _DetailInfoRow(
                                'Process',
                                detail.process?.trim().isNotEmpty == true
                                    ? detail.process!.trim()
                                    : 'Unknown',
                              ),
                              _DetailInfoRow(
                                'Vendor',
                                detail.vendorName.trim().isNotEmpty
                                    ? detail.vendorName.trim()
                                    : 'Unknown',
                              ),
                            ],
                          ),
                          _DetailInfoGroup(
                            title: 'Timeline',
                            rows: [
                              _DetailInfoRow('Start time', dateText),
                              _DetailInfoRow('Check time', checkText),
                            ],
                          ),
                        ],
                      );

                      if (constraints.maxWidth >= 860) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: summarySection,
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 4,
                              child: infoTable,
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          summarySection,
                          const SizedBox(height: 24),
                          infoTable,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailSummaryCard extends StatelessWidget {
  const _DetailSummaryCard({
    required this.accent,
    required this.lineLabel,
    required this.stencilSn,
    required this.status,
    required this.location,
  });

  final Color accent;
  final String lineLabel;
  final String stencilSn;
  final String status;
  final String location;

  @override
  Widget build(BuildContext context) {
    final palette = _StencilColorScheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lineLabel,
            style: GlobalTextStyles.bodyLarge(isDark: palette.isDark).copyWith(
              fontFamily: _StencilTypography.heading,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _DetailSummaryChip(
                icon: Icons.place_outlined,
                label: location,
              ),
              _DetailSummaryChip(
                icon: Icons.confirmation_number_outlined,
                label: 'Stencil: $stencilSn',
              ),
              _DetailSummaryChip(
                icon: Icons.verified_rounded,
                label: status,
                accent: accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSummaryChip extends StatelessWidget {
  const _DetailSummaryChip({
    required this.icon,
    required this.label,
    this.accent,
  });

  final IconData icon;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final palette = _StencilColorScheme.of(context);
    final color = accent ?? palette.onSurfaceMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
        color: accent != null
            ? accent!.withOpacity(palette.isDark ? 0.18 : 0.12)
            : palette.surfaceOverlay.withOpacity(0.55),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
              fontFamily: _StencilTypography.numeric,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStatRow extends StatelessWidget {
  const _DetailStatRow({
    required this.accent,
    required this.diffHours,
    required this.useTimes,
    required this.standardTimes,
  });

  final Color accent;
  final double diffHours;
  final int useTimes;
  final int? standardTimes;

  @override
  Widget build(BuildContext context) {
    final palette = _StencilColorScheme.of(context);
    TextStyle labelStyle(bool highlight) =>
        GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
          fontFamily: _StencilTypography.numeric,
          color: highlight ? accent : palette.onSurfaceMuted,
        );
    TextStyle valueStyle(bool highlight) =>
        GlobalTextStyles.bodyMedium(isDark: palette.isDark).copyWith(
          fontFamily: _StencilTypography.heading,
          color: highlight ? accent : palette.onSurface,
          fontSize: 16,
        );

    Widget buildTile(String label, String value, {bool highlight = false}) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight ? accent.withOpacity(0.45) : palette.dividerColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle(highlight)),
            const SizedBox(height: 6),
            Text(value, style: valueStyle(highlight)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final isThreeAcross = constraints.maxWidth >= 520;
        final hoursTile = buildTile(
          'Hours running',
          '${diffHours.toStringAsFixed(2)} h',
          highlight: true,
        );
        final useTile = buildTile('Use times', '$useTimes');
        final standardTile = buildTile(
          'Standard',
          standardTimes != null ? '$standardTimes' : 'Unknown',
        );

        if (isThreeAcross) {
          return Row(
            children: [
              Expanded(child: hoursTile),
              const SizedBox(width: 12),
              Expanded(child: useTile),
              const SizedBox(width: 12),
              Expanded(child: standardTile),
            ],
          );
        }

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hoursTile,
              const SizedBox(height: 12),
              useTile,
              const SizedBox(height: 12),
              standardTile,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            hoursTile,
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: useTile),
                const SizedBox(width: 12),
                Expanded(child: standardTile),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DetailSummarySection extends StatelessWidget {
  const _DetailSummarySection({
    required this.accent,
    required this.lineLabel,
    required this.stencilSn,
    required this.status,
    required this.location,
    required this.diffHours,
    required this.useTimes,
    required this.standardTimes,
  });

  final Color accent;
  final String lineLabel;
  final String stencilSn;
  final String status;
  final String location;
  final double diffHours;
  final int useTimes;
  final int? standardTimes;

  @override
  Widget build(BuildContext context) {
    final summary = _DetailSummaryCard(
      accent: accent,
      lineLabel: lineLabel,
      stencilSn: stencilSn,
      status: status,
      location: location,
    );
    final stats = _DetailStatRow(
      accent: accent,
      diffHours: diffHours,
      useTimes: useTimes,
      standardTimes: standardTimes,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: summary),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: stats),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            summary,
            const SizedBox(height: 16),
            stats,
          ],
        );
      },
    );
  }
}

class _DetailInfoRow {
  const _DetailInfoRow(this.label, this.value);

  final String label;
  final String value;
}

class _DetailInfoGroup {
  const _DetailInfoGroup({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_DetailInfoRow> rows;
}

class _DetailInfoTable extends StatelessWidget {
  const _DetailInfoTable({required this.groups});

  final List<_DetailInfoGroup> groups;

  @override
  Widget build(BuildContext context) {
    final palette = _StencilColorScheme.of(context);
    final dividerColor = palette.dividerColor.withOpacity(0.5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumn = constraints.maxWidth >= 420;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var groupIndex = 0; groupIndex < groups.length; groupIndex++) ...[
                if (groupIndex != 0) ...[
                  const SizedBox(height: 12),
                  Divider(color: dividerColor),
                  const SizedBox(height: 12),
                ],
                Text(
                  groups[groupIndex].title,
                  style:
                      GlobalTextStyles.bodyMedium(isDark: palette.isDark).copyWith(
                    fontFamily: _StencilTypography.heading,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                if (useTwoColumn)
                  _DetailInfoTwoColumnGroup(
                    rows: groups[groupIndex].rows,
                    dividerColor: dividerColor,
                  )
                else
                  ...List.generate(groups[groupIndex].rows.length, (rowIndex) {
                    final row = groups[groupIndex].rows[rowIndex];
                    final isLastRow = rowIndex == groups[groupIndex].rows.length - 1;
                    return _DetailInfoTableRow(
                      label: row.label,
                      value: row.value,
                      showDivider: !isLastRow,
                      dividerColor: dividerColor,
                    );
                  }),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DetailInfoTableRow extends StatelessWidget {
  const _DetailInfoTableRow({
    required this.label,
    required this.value,
    required this.showDivider,
    required this.dividerColor,
  });

  final String label;
  final String value;
  final bool showDivider;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final palette = _StencilColorScheme.of(context);
    final labelStyle = GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
      fontFamily: _StencilTypography.numeric,
      color: palette.onSurfaceMuted,
    );
    final valueStyle = GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
      fontFamily: _StencilTypography.numeric,
      color: palette.onSurface,
    );

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 96),
              child: Text(label, style: labelStyle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: valueStyle,
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 10),
          Divider(color: dividerColor),
          const SizedBox(height: 10),
        ] else
          const SizedBox(height: 4),
      ],
    );
  }
}

class _DetailInfoTwoColumnGroup extends StatelessWidget {
  const _DetailInfoTwoColumnGroup({
    required this.rows,
    required this.dividerColor,
  });

  final List<_DetailInfoRow> rows;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < rows.length; index += 2) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailInfoTableCell(
                  label: rows[index].label,
                  value: rows[index].value,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: index + 1 < rows.length
                    ? _DetailInfoTableCell(
                        label: rows[index + 1].label,
                        value: rows[index + 1].value,
                      )
                    : const SizedBox(),
              ),
            ],
          ),
          if (index + 2 < rows.length) ...[
            const SizedBox(height: 12),
            Divider(color: dividerColor),
            const SizedBox(height: 12),
          ] else
            const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _DetailInfoTableCell extends StatelessWidget {
  const _DetailInfoTableCell({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = _StencilColorScheme.of(context);
    final labelStyle = GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
      fontFamily: _StencilTypography.numeric,
      color: palette.onSurfaceMuted,
    );
    final valueStyle = GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
      fontFamily: _StencilTypography.numeric,
      color: palette.onSurface,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 6),
        Text(value, style: valueStyle),
      ],
    );
  }
}
