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
                                  fontFamily: GoogleFonts.orbitron().fontFamily,
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
                                  fontFamily: GoogleFonts.robotoMono().fontFamily,
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
                                fontFamily: GoogleFonts.orbitron().fontFamily,
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
    List<_LineTrackingDatum> items,
  ) async {
    if (items.isEmpty) return;

    final sorted = items.toList()
      ..sort((a, b) => b.hours.compareTo(a.hours));
    final maxHours = sorted.fold<double>(0, (max, item) => item.hours > max ? item.hours : max);
    final normalizedMax = maxHours <= 0 ? 1.0 : maxHours + 0.5;
    final scrollController = ScrollController();

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
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final datum = sorted[index];
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
  }

  Future<void> _showRunningLineDetail(
    BuildContext context,
    List<StencilDetail> items,
  ) async {
    if (items.isEmpty) return;

    final scrollController = ScrollController();

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
            heightFactor: 0.85,
            child: _DetailSheetContainer(
              title: 'Running line (${items.length})',
              controller: scrollController,
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final detail = items[index];
                  final diffHours = detail.startTime == null
                      ? 0.0
                      : DateTime.now()
                              .difference(detail.startTime!)
                              .inMinutes /
                          60.0;
                  final accent = _lineHoursColor(diffHours);
                  return _RunningLineTile(
                    detail: detail,
                    hourDiff: diffHours,
                    accent: accent,
                    dense: false,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showSingleDetail(context, detail, diffHours);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSingleDetail(
    BuildContext context,
    StencilDetail detail,
    double diffHours,
  ) async {
    final scrollController = ScrollController();
    final accent = _lineHoursColor(diffHours);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        final bottomPadding = media.viewPadding.bottom;
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
              title: detail.lineName ?? detail.location ?? detail.stencilSn ?? 'Detail',
              controller: scrollController,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _DetailRow(
                    label: 'Stencil SN',
                    value: detail.stencilSn ?? '--',
                    accent: accent,
                  ),
                  _DetailRow(
                    label: 'Line / Location',
                    value: detail.lineName ?? detail.location ?? '--',
                  ),
                  _DetailRow(
                    label: 'Customer',
                    value: detail.customerLabel,
                  ),
                  _DetailRow(
                    label: 'Factory',
                    value: detail.floorLabel,
                  ),
                  _DetailRow(
                    label: 'Status',
                    value: detail.statusLabel,
                  ),
                  _DetailRow(
                    label: 'Hours running',
                    value: '${diffHours.toStringAsFixed(2)} h',
                    accent: accent,
                  ),
                  _DetailRow(label: 'Start time', value: dateText),
                  _DetailRow(label: 'Check time', value: checkText),
                  _DetailRow(
                    label: 'Use times',
                    value: '${detail.totalUseTimes ?? 0}',
                  ),
                  _DetailRow(
                    label: 'Standard times',
                    value: detail.standardTimes != null
                        ? '${detail.standardTimes}'
                        : 'Unknown',
                  ),
                  _DetailRow(
                    label: 'Process',
                    value: detail.process?.trim().isNotEmpty == true
                        ? detail.process!.trim()
                        : 'Unknown',
                  ),
                  _DetailRow(
                    label: 'Vendor',
                    value: detail.vendorName.trim().isNotEmpty
                        ? detail.vendorName.trim()
                        : 'Unknown',
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
