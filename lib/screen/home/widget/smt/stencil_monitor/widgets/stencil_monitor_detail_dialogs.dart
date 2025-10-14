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
                  _DetailSummaryCard(
                    accent: accent,
                    lineLabel: lineLabel,
                    stencilSn: stencilSn,
                    status: statusLabel,
                    location: locationLabel,
                  ),
                  const SizedBox(height: 16),
                  _DetailStatRow(
                    accent: accent,
                    diffHours: diffHours,
                    useTimes: useTimes,
                    standardTimes: standardTimes,
                  ),
                  const SizedBox(height: 24),
                  _DetailInfoSection(
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
                  const SizedBox(height: 16),
                  _DetailInfoSection(
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
                  const SizedBox(height: 16),
                  _DetailInfoSection(
                    title: 'Timeline',
                    rows: [
                      _DetailInfoRow('Start time', dateText),
                      _DetailInfoRow('Check time', checkText),
                    ],
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
        final isCompact = constraints.maxWidth < 520;
        final tiles = [
          buildTile(
            'Hours running',
            '${diffHours.toStringAsFixed(2)} h',
            highlight: true,
          ),
          buildTile('Use times', '$useTimes'),
          buildTile('Standard', standardTimes != null ? '$standardTimes' : 'Unknown'),
        ];

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tiles[0],
              const SizedBox(height: 12),
              tiles[1],
              const SizedBox(height: 12),
              tiles[2],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: 12),
            Expanded(child: tiles[1]),
            const SizedBox(width: 12),
            Expanded(child: tiles[2]),
          ],
        );
      },
    );
  }
}

class _DetailInfoSection extends StatelessWidget {
  const _DetailInfoSection({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_DetailInfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final palette = _StencilColorScheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.dividerColor.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GlobalTextStyles.bodyMedium(isDark: palette.isDark).copyWith(
              fontFamily: _StencilTypography.heading,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _DetailInfoRowWidget(row: row),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailInfoRow {
  const _DetailInfoRow(this.label, this.value);

  final String label;
  final String value;
}

class _DetailInfoRowWidget extends StatelessWidget {
  const _DetailInfoRowWidget({required this.row});

  final _DetailInfoRow row;

  @override
  Widget build(BuildContext context) {
    final palette = _StencilColorScheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            row.label,
            style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
              fontFamily: _StencilTypography.numeric,
              color: palette.onSurfaceMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            row.value,
            style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
              fontFamily: _StencilTypography.numeric,
              color: palette.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
