part of 'stencil_monitor_screen.dart';

extension _StencilMonitorDetailDialogs on _StencilMonitorScreenState {
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
                    value: detail.customer?.trim().isNotEmpty == true
                        ? detail.customer!.trim()
                        : 'UNKNOWN',
                  ),
                  _DetailRow(
                    label: 'Factory',
                    value: detail.floor?.trim().isNotEmpty == true
                        ? detail.floor!.trim()
                        : 'UNKNOWN',
                  ),
                  _DetailRow(
                    label: 'Status',
                    value: detail.status?.trim().isNotEmpty == true
                        ? detail.status!.trim()
                        : 'UNKNOWN',
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
                    value: detail.venderName?.trim().isNotEmpty == true
                        ? detail.venderName!.trim()
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
