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
            heightFactor: 0.7,
            child: _DetailSheetContainer(
              title: lineTitle,
              controller: scrollController,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _DetailHeroHeader(
                    accent: accent,
                    palette: palette,
                    title: lineLabel,
                    stencilSn: stencilSn,
                    status: statusLabel,
                    location: locationLabel,
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _DetailMetricCard(
                        icon: Icons.speed_rounded,
                        label: 'Hours running',
                        value: '${diffHours.toStringAsFixed(2)} h',
                        accent: accent,
                        emphasize: true,
                      ),
                      _DetailMetricCard(
                        icon: Icons.loop_outlined,
                        label: 'Use times',
                        value: '$useTimes',
                        accent: palette.accentPrimary,
                      ),
                      _DetailMetricCard(
                        icon: Icons.rule_rounded,
                        label: 'Standard',
                        value: standardTimes != null ? '$standardTimes' : 'Unknown',
                        accent: palette.accentSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DetailSection(
                    icon: Icons.factory_outlined,
                    title: 'Assignment',
                    entries: [
                      _DetailSectionEntry('Line', lineLabel),
                      _DetailSectionEntry('Location', locationLabel),
                      _DetailSectionEntry(
                        'Customer',
                        detail.customerLabel?.trim().isNotEmpty == true
                            ? detail.customerLabel!.trim()
                            : '--',
                      ),
                      _DetailSectionEntry(
                        'Factory',
                        detail.floorLabel?.trim().isNotEmpty == true
                            ? detail.floorLabel!.trim()
                            : '--',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailSection(
                    icon: Icons.insights_outlined,
                    title: 'Specification',
                    entries: [
                      _DetailSectionEntry(
                        'Process',
                        detail.process?.trim().isNotEmpty == true
                            ? detail.process!.trim()
                            : 'Unknown',
                      ),
                      _DetailSectionEntry(
                        'Vendor',
                        detail.vendorName.trim().isNotEmpty
                            ? detail.vendorName.trim()
                            : 'Unknown',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailSection(
                    icon: Icons.schedule_rounded,
                    title: 'Timeline',
                    entries: [
                      _DetailSectionEntry('Start time', dateText),
                      _DetailSectionEntry('Check time', checkText),
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

class _DetailHeroHeader extends StatelessWidget {
  const _DetailHeroHeader({
    required this.accent,
    required this.palette,
    required this.title,
    required this.stencilSn,
    required this.status,
    required this.location,
  });

  final Color accent;
  final _StencilColorScheme palette;
  final String title;
  final String stencilSn;
  final String status;
  final String location;

  @override
  Widget build(BuildContext context) {
    final statusColor = accent.withOpacity(0.9);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(palette.isDark ? 0.55 : 0.75),
            accent.withOpacity(0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GlobalTextStyles.bodyMedium(isDark: palette.isDark).copyWith(
                        fontFamily: _StencilTypography.heading,
                        fontSize: 20,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stencil $stencilSn',
                      style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
                        fontFamily: _StencilTypography.numeric,
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
                    fontFamily: _StencilTypography.numeric,
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.place_outlined, color: Colors.white.withOpacity(0.8), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location,
                  style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
                    fontFamily: _StencilTypography.numeric,
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailMetricCard extends StatelessWidget {
  const _DetailMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final palette = _StencilColorScheme.of(context);
    final background = accent.withOpacity(palette.isDark ? 0.18 : 0.12);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.45)),
          color: palette.cardBackground,
          gradient: LinearGradient(
            colors: [background, Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
                    fontFamily: _StencilTypography.numeric,
                    color: accent,
                    fontSize: 12,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GlobalTextStyles.bodyMedium(isDark: palette.isDark).copyWith(
                fontFamily: _StencilTypography.heading,
                color: emphasize ? accent : palette.onSurface,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.entries,
  });

  final IconData icon;
  final String title;
  final List<_DetailSectionEntry> entries;

  @override
  Widget build(BuildContext context) {
    final palette = _StencilColorScheme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.dividerColor.withOpacity(0.6)),
        color: palette.cardBackground,
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.surfaceOverlay.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 18, color: palette.onSurface),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GlobalTextStyles.bodyMedium(isDark: palette.isDark).copyWith(
                  fontFamily: _StencilTypography.heading,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...entries
              .expand((entry) => [
                    _DetailSectionRow(entry: entry),
                    if (entry != entries.last)
                      Divider(
                        color: palette.dividerColor.withOpacity(0.35),
                        height: 14,
                      ),
                  ])
              .toList(),
        ],
      ),
    );
  }
}

class _DetailSectionRow extends StatelessWidget {
  const _DetailSectionRow({required this.entry});

  final _DetailSectionEntry entry;

  @override
  Widget build(BuildContext context) {
    final palette = _StencilColorScheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.label,
            style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
              fontFamily: _StencilTypography.numeric,
              color: palette.onSurfaceMuted,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.value,
            style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
              fontFamily: _StencilTypography.numeric,
              color: palette.onSurface,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSectionEntry {
  const _DetailSectionEntry(this.label, this.value);

  final String label;
  final String value;
}
