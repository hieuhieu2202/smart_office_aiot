import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/config/global_text_style.dart';
import 'package:smart_factory/screen/home/controller/stencil_monitor_controller.dart';

import '../../../../../model/smt/stencil_detail.dart';
import '../../../../../widget/animation/loading/eva_loading_view.dart';

part 'widgets/stencil_monitor_filter_sheet.dart';
part 'widgets/stencil_monitor_common.dart';
part 'widgets/stencil_monitor_insights.dart';
part 'widgets/stencil_monitor_running_line.dart';
part 'widgets/stencil_monitor_detail_dialogs.dart';

class StencilMonitorScreen extends StatefulWidget {
  const StencilMonitorScreen({
    super.key,
    this.title,
    this.controllerTag,
  });

  final String? title;
  final String? controllerTag;

  @override
  State<StencilMonitorScreen> createState() => _StencilMonitorScreenState();
}

class _StencilMonitorScreenState extends State<StencilMonitorScreen> {
  late final String _controllerTag;
  late final StencilMonitorController controller;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  late _StencilColorScheme _palette;

  Color get _textPrimary => _palette.onSurface;
  Color get _textSecondary => _palette.onSurfaceMuted;
  Color get _axisLineColor => _palette.onSurface
      .withOpacity(_palette.isDark ? 0.25 : 0.2);

  @override
  void initState() {
    super.initState();
    _controllerTag = widget.controllerTag ?? 'stencil_monitor_default';
    controller = Get.put(StencilMonitorController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    if (Get.isRegistered<StencilMonitorController>(tag: _controllerTag)) {
      Get.delete<StencilMonitorController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _palette = _StencilColorScheme.of(context);
      final loading = controller.isLoading.value;
      final hasData = controller.stencilData.isNotEmpty;
      final filtered = controller.filteredData;
      final error = controller.error.value;

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(
          context,
          loading: loading,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _palette.backgroundGradient,
            ),
          ),
          child: SafeArea(
            child: loading && !hasData
                ? const Center(child: EvaLoadingView(size: 140))
                : _buildContent(
                    context,
                    loading: loading,
                    error: error,
                    filtered: filtered,
                    hasData: hasData,
                  ),
          ),
        ),
      );
    });
  }

  Widget _buildContent(
    BuildContext context, {
    required bool loading,
    required String error,
    required List<StencilDetail> filtered,
    required bool hasData,
  }) {
    if (error.isNotEmpty && !hasData) {
      return _buildFullError(error);
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      color: _palette.accentPrimary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (error.isNotEmpty) ...[
                      _buildErrorChip(error),
                      const SizedBox(height: 20),
                    ],
                    if (filtered.isEmpty)
                      _buildEmptyState()
                    else
                      _buildDashboard(context, filtered),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool loading,
  }) {
    final lastUpdated = controller.lastUpdated.value;
    final updateText = lastUpdated != null
        ? _dateFormat.format(lastUpdated)
        : 'Waiting for data…';
    final floorLabel = controller.selectedFloor.value == 'ALL'
        ? 'F06'
        : controller.selectedFloor.value;
    final titleStyle = GlobalTextStyles.bodyMedium(isDark: _palette.isDark)
        .copyWith(
      fontFamily: _StencilTypography.heading,
      fontWeight: FontWeight.w700,
      fontSize: 16,
      letterSpacing: 1.1,
      color: _palette.onSurface,
    );
    final subtitleStyle = GlobalTextStyles.bodySmall(isDark: _palette.isDark)
        .copyWith(
      fontFamily: _StencilTypography.numeric,
      fontSize: 11,
      color: _palette.onSurfaceMuted,
    );

    return AppBar(
      backgroundColor:
          _palette.isDark ? GlobalColors.appBarDarkBg : GlobalColors.appBarLightBg,
      elevation: 2,
      automaticallyImplyLeading: true,
      iconTheme: IconThemeData(color: _palette.onSurface),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'SMT $floorLabel STENCIL MONITOR',
            style: titleStyle,
          ),
          const SizedBox(height: 4),
          Text(
            'Last update: $updateText',
            style: subtitleStyle,
          ),
        ],
      ),
      actions: [
        _FilterActionButton(controller: controller),
        IconButton(
          tooltip: 'Refresh',
          icon: Icon(loading ? Icons.sync : Icons.refresh),
          onPressed: () => controller.fetchData(force: true),
        ),
      ],
    );
  }

  Widget _buildErrorChip(String message) {
    final palette = _palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.errorBorder),
        color: palette.errorFill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(Icons.error_outline, color: palette.errorText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GlobalTextStyles.bodySmall(isDark: palette.isDark)
                  .copyWith(color: palette.errorText, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => controller.fetchData(force: true),
            child: Text(
              'Retry',
              style: GlobalTextStyles.bodySmall(isDark: palette.isDark)
                  .copyWith(color: palette.accentPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, List<StencilDetail> filtered) {
    final customerSlices = _buildCustomerSlices(filtered);
    final statusSlices = _buildStatusSlices(filtered);
    final vendorSlices = _buildVendorSlices(filtered);
    final processSlices = _buildProcessSlices(filtered);

    final lineTracking = _buildLineTracking(filtered);
    final usingTimeSlices = _buildStandardBuckets(filtered);
    final checkSlices = _buildCheckTimeBuckets(filtered);

    final activeLines = _filterActiveLines(filtered);

    final insights = _buildInsightMetrics(activeLines);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOverviewGrid(
          customerSlices: customerSlices,
          statusSlices: statusSlices,
          vendorSlices: vendorSlices,
          processSlices: processSlices,
        ),
        if (insights.isNotEmpty) ...[
          const SizedBox(height: 20),
          _InsightsStrip(items: insights),
        ],
        const SizedBox(height: 20),
        _buildLineTrackingCard(context, lineTracking),
        const SizedBox(height: 20),
        _buildUsageRow(usingTimeSlices, checkSlices),
        const SizedBox(height: 20),
        _buildRunningLine(context, activeLines),
      ],
    );
  }

  List<_InsightMetric> _buildInsightMetrics(List<StencilDetail> activeLines) {
    if (activeLines.isEmpty) return const [];

    final accentPrimary = _palette.accentPrimary;
    final accentSecondary = _palette.accentSecondary;
    final neutralAccent =
        _palette.isDark ? GlobalColors.borderDark : GlobalColors.borderLight;
    final cautionAccent = _palette.isDark
        ? Colors.amberAccent.shade200
        : Colors.amberAccent.shade400;
    final alertAccent = _palette.isDark
        ? Colors.redAccent.shade200
        : Colors.redAccent.shade400;

    final total = activeLines.length;
    int good = 0;
    int warning = 0;
    int danger = 0;

    final now = DateTime.now();
    for (final item in activeLines) {
      final start = item.startTime;
      if (start == null) continue;
      final diff = now.difference(start).inMinutes / 60;
      if (diff <= 3.5) {
        good++;
      } else if (diff <= 4) {
        warning++;
      } else {
        danger++;
      }
    }

    final checkNow = DateTime.now();
    final recentCutoff = checkNow.subtract(const Duration(days: 180));
    final onCheck = activeLines
        .where((e) => (e.checkTime ?? checkNow).isAfter(recentCutoff))
        .length;

    return [
      _InsightMetric(
        label: 'ACTIVE LINES',
        value: total.toString(),
        accent: accentPrimary,
        description: 'Monitoring right now',
      ),
      _InsightMetric(
        label: 'STABLE',
        value: good.toString(),
        accent: accentSecondary,
        description: '< 3.5 hours runtime',
      ),
      _InsightMetric(
        label: 'WATCH',
        value: warning.toString(),
        accent: cautionAccent,
        description: '3.5 – 4 hours runtime',
      ),
      _InsightMetric(
        label: 'ALERT',
        value: danger.toString(),
        accent: alertAccent,
        description: '> 4 hours runtime',
      ),
      _InsightMetric(
        label: 'RECENT CHECK',
        value: onCheck.toString(),
        accent: neutralAccent,
        description: 'Checked in last 6 months',
      ),
    ];
  }

  Widget _buildOverviewGrid({
    required List<_PieSlice> customerSlices,
    required List<_PieSlice> statusSlices,
    required List<_PieSlice> vendorSlices,
    required List<_PieSlice> processSlices,
  }) {
    final accentPrimary = _palette.accentPrimary;
    final accentSecondary = _palette.accentSecondary;
    final accentInfo =
        _palette.isDark ? GlobalColors.borderDark : GlobalColors.borderLight;
    final accentSuccess = _palette.isDark
        ? GlobalColors.gradientDarkStart
        : GlobalColors.gradientLightStart;

    final cards = [
      _OverviewCardData(
        title: 'CUSTOMER',
        slices: customerSlices,
        accent: accentPrimary,
      ),
      _OverviewCardData(
        title: 'STATUS',
        slices: statusSlices,
        accent: accentSecondary,
      ),
      _OverviewCardData(
        title: 'VENDOR',
        slices: vendorSlices,
        accent: accentInfo,
      ),
      _OverviewCardData(
        title: 'STENCIL SIDE',
        slices: processSlices,
        accent: accentSuccess,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 520 ? 2 : 1;
        const spacing = 16.0;
        final itemWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  child: _buildOverviewCard(context, card),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildOverviewCard(BuildContext context, _OverviewCardData data) {
    final palette = _palette;
    final total = data.slices.fold<int>(0, (sum, slice) => sum + slice.value);
    final displaySlices = data.slices.take(4).toList();
    final hiddenSlices = data.slices.length > displaySlices.length
        ? data.slices.skip(displaySlices.length).toList()
        : <_PieSlice>[];
    final hiddenCount = hiddenSlices.length;
    final hiddenTotal = hiddenSlices.fold<int>(0, (sum, slice) => sum + slice.value);

    final titleStyle = GoogleFonts.spaceGrotesk(
      color: data.accent,
      fontSize: 15,
      letterSpacing: 1,
    );

    final totalStyle = GoogleFonts.spaceGrotesk(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: palette.onSurface,
    );

    final subtitleStyle = GoogleFonts.ibmPlexMono(
      fontSize: 12,
      color: palette.onSurfaceMuted,
    );

    final children = <Widget>[
      Text(data.title, style: titleStyle),
      const SizedBox(height: 12),
      Text('$total', style: totalStyle),
      const SizedBox(height: 2),
      Text('Total items', style: subtitleStyle),
      const SizedBox(height: 16),
    ];

    if (total == 0) {
      children.add(
        Text(
          'No data available',
          style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
            fontFamily: _StencilTypography.numeric,
            color: palette.onSurfaceMuted,
          ),
        ),
      );
    } else {
      for (final slice in displaySlices) {
        children.add(_buildSliceRow(slice.label, slice.value, data.accent));
      }
      if (hiddenCount > 0) {
        children.add(
          _buildMoreIndicator(
            context,
            hiddenCount,
            hiddenTotal,
            data.accent,
            data,
          ),
        );
      } else if (data.slices.length > 1) {
        children.add(
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _showBreakdownDetail(context, data),
              style: TextButton.styleFrom(
                foregroundColor: data.accent,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.open_in_full, size: 16),
              label: Text(
                'View breakdown',
                style: GlobalTextStyles.bodySmall(isDark: _palette.isDark).copyWith(
                  fontFamily: _StencilTypography.numeric,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        );
      }
    }

    final cardRadius = BorderRadius.circular(24);

    return Material(
      color: Colors.transparent,
      borderRadius: cardRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: cardRadius,
        splashColor: data.accent.withOpacity(0.12),
        highlightColor: data.accent.withOpacity(0.08),
        onTap: total > 0
            ? () => _showBreakdownDetail(
                  context,
                  data,
                )
            : null,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: cardRadius,
            border: Border.all(color: data.accent.withOpacity(0.45), width: 1.1),
            color: palette.cardBackground,
            gradient: LinearGradient(
              colors: [data.accent.withOpacity(0.12), Colors.transparent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: palette.cardShadow,
                blurRadius: 18,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildSliceRow(String label, int value, Color accent) {
    final palette = _palette;
    final nameStyle = GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
      fontFamily: _StencilTypography.numeric,
      fontSize: 12,
      color: palette.onSurface,
    );
    final valueStyle = nameStyle.copyWith(
      fontWeight: FontWeight.w600,
      color: accent,
    );

    final normalizedLabel = label.trim().isEmpty ? 'Unknown' : label.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.9),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              normalizedLabel,
              style: nameStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text('$value', style: valueStyle),
        ],
      ),
    );
  }

  Widget _buildMoreIndicator(
    BuildContext context,
    int hiddenCount,
    int hiddenTotal,
    Color accent,
    _OverviewCardData data,
  ) {
    final textStyle = GlobalTextStyles.bodySmall(isDark: _palette.isDark).copyWith(
      fontFamily: _StencilTypography.numeric,
      fontSize: 11,
      color: _palette.onSurface,
      fontWeight: FontWeight.w600,
    );

    final totalLabel = hiddenTotal > 0 ? ' (${hiddenTotal} items)' : '';
    final groupLabel = hiddenCount == 1 ? 'group' : 'groups';

    return InkWell(
      onTap: () => _showBreakdownDetail(context, data),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: accent.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '+ $hiddenCount more $groupLabel$totalLabel • View all',
                style: textStyle,
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: accent.withOpacity(0.8)),
          ],
        ),
      ),
    );
  }

  Widget _buildLineTrackingCard(
    BuildContext context,
    List<_LineTrackingDatum> data,
  ) {
    final palette = _palette;
    final accent = palette.accentSecondary;
    final coolColor = palette.accentPrimary;
    final cautionColor = _palette.isDark
        ? Colors.amberAccent.shade200
        : Colors.amberAccent.shade400;
    final dangerColor = _palette.isDark
        ? Colors.redAccent.shade200
        : Colors.redAccent.shade400;
    final titleStyle = GlobalTextStyles.bodyMedium(isDark: palette.isDark)
        .copyWith(
      fontFamily: _StencilTypography.heading,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.1,
      color: accent,
    );

    final top = data.take(8).toList();
    final maxHours = top.fold<double>(0, (max, item) => item.hours > max ? item.hours : max);
    final normalizedMax = maxHours <= 0 ? 1.0 : maxHours + 0.5;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.45)),
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.12),
            Colors.transparent,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LINE TRACKING',
            style: titleStyle,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildColorLegend(' < 3.5h', coolColor),
              const SizedBox(width: 12),
              _buildColorLegend('3.5 – 4h', cautionColor),
              const SizedBox(width: 12),
              _buildColorLegend('> 4h', dangerColor),
            ],
          ),
          const SizedBox(height: 16),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No runtime tracking data available',
                style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
                  fontFamily: _StencilTypography.numeric,
                  color: _textSecondary,
                ),
              ),
            )
          else ...[
            for (final item in top)
              _buildLineProgressRow(
                item,
                normalizedMax,
                onTap: () {
                  final detail = _findDetailBySn(item.stencilSn);
                  if (detail != null) {
                    _showSingleDetail(context, detail, item.hours);
                  }
                },
              ),
            if (data.length > top.length)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _showLineTrackingDetail(context, data),
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.auto_graph_rounded, size: 16),
                  label: Text(
                    'View all ${data.length} lines',
                    style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
                      fontFamily: _StencilTypography.numeric,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildLineProgressRow(
    _LineTrackingDatum item,
    double maxHours, {
    VoidCallback? onTap,
  }) {
    final palette = _palette;
    final labelStyle = GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
      fontFamily: _StencilTypography.numeric,
      fontSize: 12,
      color: palette.onSurface,
    );
    final valueStyle = labelStyle.copyWith(
      fontWeight: FontWeight.w600,
      color: _lineHoursColor(item.hours),
    );
    final metaStyle = GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
      fontFamily: _StencilTypography.numeric,
      fontSize: 11,
      color: _textSecondary,
    );

    final progress = (item.hours / maxHours).clamp(0.0, 1.0).toDouble();
    final formattedHours = item.hours >= 10
        ? item.hours.toStringAsFixed(1)
        : item.hours.toStringAsFixed(2);

    final radius = BorderRadius.circular(18);
    final content = Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: _lineHoursColor(item.hours).withOpacity(0.4)),
        gradient: LinearGradient(
          colors: [
            _lineHoursColor(item.hours).withOpacity(0.14),
            palette.cardBackground.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.category,
                  style: labelStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('$formattedHours h', style: valueStyle),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              valueColor: AlwaysStoppedAnimation<Color>(_lineHoursColor(item.hours)),
              backgroundColor: _lineHoursColor(item.hours).withOpacity(0.18),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${item.location} • ${_dateFormat.format(item.startTime)}',
            style: metaStyle,
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: content,
    );
  }

  Widget _buildColorLegend(String label, Color color) {
    final textStyle = GlobalTextStyles.bodySmall(isDark: _palette.isDark)
        .copyWith(
      fontFamily: _StencilTypography.numeric,
      fontSize: 11,
      color: _textSecondary,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: textStyle,
        ),
      ],
    );
  }

  Widget _buildUsageRow(
    List<_PieSlice> usingTime,
    List<_PieSlice> checkTime,
  ) {
    final usageAccent = _palette.accentPrimary;
    final checkingAccent =
        _palette.isDark ? GlobalColors.gradientDarkEnd : GlobalColors.gradientLightEnd;

    final cards = [
      _OverviewCardData(title: 'USING TIME', slices: usingTime, accent: usageAccent),
      _OverviewCardData(title: 'CHECKING TIME', slices: checkTime, accent: checkingAccent),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              _buildOverviewCard(context, cards[0]),
              const SizedBox(height: 16),
              _buildOverviewCard(context, cards[1]),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: _buildOverviewCard(context, cards[0])),
            const SizedBox(width: 16),
            Expanded(child: _buildOverviewCard(context, cards[1])),
          ],
        );
      },
    );
  }

  Widget _buildRunningLine(BuildContext context, List<StencilDetail> activeLines) {
    if (activeLines.isEmpty) {
      return _GlassCard(
        accent: _palette.accentPrimary,
        title: 'RUNNING LINE',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(
              'No active stencil on line',
              style: GoogleFonts.ibmPlexMono(
                color: _textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final limited = activeLines.take(8).toList();
    final accent = _palette.accentPrimary;
    final cautionColor = _palette.isDark
        ? Colors.amberAccent.shade200
        : Colors.amberAccent.shade400;
    final dangerColor = _palette.isDark
        ? Colors.redAccent.shade200
        : Colors.redAccent.shade400;

    return _GlassCard(
      accent: accent,
      title: 'RUNNING LINE',
      action: TextButton.icon(
        onPressed: () => _showRunningLineDetail(context, activeLines),
        style: TextButton.styleFrom(foregroundColor: accent),
        icon: Icon(Icons.list_alt_rounded, color: accent, size: 18),
        label: Text(
          'View all',
          style: GlobalTextStyles.bodySmall(isDark: _palette.isDark).copyWith(
            fontFamily: _StencilTypography.numeric,
            fontSize: 12,
            color: accent,
          ),
        ),
      ),
      child: Column(
        children: [
          ...limited.map((item) {
            final diffHours = item.startTime == null
                ? 0.0
                : now.difference(item.startTime!).inMinutes / 60.0;
            final color = diffHours <= 3.5
                ? accent
                : diffHours <= 4
                    ? cautionColor
                    : dangerColor;

            return _RunningLineTile(
              detail: item,
              hourDiff: diffHours,
              accent: color,
              onTap: () => _showSingleDetail(context, item, diffHours),
            );
          }),
          if (activeLines.length > limited.length) ...[
            const SizedBox(height: 12),
            Text(
              '+${activeLines.length - limited.length} more lines running',
              style: GoogleFonts.ibmPlexMono(
                color: _textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _axisLineColor),
        color: _palette.surfaceOverlay,
      ),
      child: Column(
        children: [
          Icon(Icons.sensors_off, size: 48, color: _textSecondary.withOpacity(0.7)),
          const SizedBox(height: 12),
          Text(
            'No stencil records match the selected filters.',
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexMono(
              color: _textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 52, color: _palette.errorText.withOpacity(0.9)),
            const SizedBox(height: 12),
            Text(
              'Unable to load stencil monitor data.',
              style: GoogleFonts.spaceGrotesk(
                color: _textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexMono(
                color: _textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => controller.fetchData(force: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  List<_PieSlice> _buildCustomerSlices(List<StencilDetail> data) {
    final map = <String, int>{};
    for (final item in data) {
      final label = item.customerLabel;
      map[label] = (map[label] ?? 0) + 1;
    }

    final entries = map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return entries.map((entry) => _PieSlice(entry.key, entry.value)).toList();
  }

  List<_PieSlice> _buildStatusSlices(List<StencilDetail> data) {
    final map = <String, int>{};
    for (final item in data) {
      if (_isIgnoredCustomer(item)) {
        continue;
      }
      final status = item.status?.trim() ?? '';
      if (status.toUpperCase() == 'TOOLROOM') {
        continue;
      }
      final label = status.isEmpty ? 'UNKNOWN' : status;
      map[label] = (map[label] ?? 0) + 1;
    }

    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((entry) => _PieSlice(entry.key, entry.value)).toList();
  }

  List<_PieSlice> _buildVendorSlices(List<StencilDetail> data) {
    final map = <String, int>{};
    for (final item in data) {
      if (_isIgnoredCustomer(item)) {
        continue;
      }
      final vendor = item.vendorName.trim();
      final label = vendor.isEmpty ? 'UNKNOWN' : vendor;
      map[label] = (map[label] ?? 0) + 1;
    }

    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((entry) => _PieSlice(entry.key, entry.value)).toList();
  }

  List<_PieSlice> _buildProcessSlices(List<StencilDetail> data) {
    final map = <String, int>{};
    for (final item in data) {
      if (_isIgnoredCustomer(item)) {
        continue;
      }
      final label = _mapProcess(item.process);
      map[label] = (map[label] ?? 0) + 1;
    }

    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((entry) => _PieSlice(entry.key, entry.value)).toList();
  }

  List<StencilDetail> _filterActiveLines(List<StencilDetail> data) {
    final list = data
        .where((item) => item.isActive && !_isIgnoredCustomer(item))
        .toList();
    list.sort((a, b) =>
        (a.startTime ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
            b.startTime ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return list;
  }

  String _mapProcess(String? raw) {
    final value = raw?.trim().toUpperCase() ?? '';
    if (value == 'T' || value == 'TOP') return 'TOP';
    if (value == 'B' || value == 'BOTTOM') return 'BOTTOM';
    if (value == 'D' || value == 'DOUBLE') return 'DOUBLE';
    if (value.isEmpty) return 'DOUBLE';
    return value;
  }

  List<_LineTrackingDatum> _buildLineTracking(List<StencilDetail> data) {
    final now = DateTime.now();
    final list = <_LineTrackingDatum>[];

    for (final item in data) {
      if (_isIgnoredCustomer(item)) {
        continue;
      }
      final start = item.startTime;
      if (start == null) continue;
      final diff = now.difference(start).inMinutes / 60.0;
      final category = item.lineName?.isNotEmpty == true
          ? item.lineName!
          : item.location?.isNotEmpty == true
              ? item.location!
              : item.stencilSn;
      list.add(
        _LineTrackingDatum(
          category: category,
          hours: diff < 0 ? 0.0 : diff,
          stencilSn: item.stencilSn,
          startTime: start,
          location: item.location ?? '-',
          totalUse: item.totalUseTimes,
        ),
      );
    }

    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  bool _isIgnoredCustomer(StencilDetail detail) {
    final raw = detail.customer.trim().toUpperCase();
    return StencilMonitorController.ignoredCustomers.contains(raw);
  }

  StencilDetail? _findDetailBySn(String? sn) {
    if (sn == null || sn.isEmpty) return null;
    for (final detail in controller.stencilData) {
      final stencilSn = detail.stencilSn;
      if (stencilSn != null && stencilSn.isNotEmpty && stencilSn == sn) {
        return detail;
      }
    }
    return null;
  }

  List<_PieSlice> _buildStandardBuckets(List<StencilDetail> data) {
    final ranges = <_UsageRange>[
      const _UsageRange(min: double.negativeInfinity, max: 0, label: '0'),
      const _UsageRange(min: 1, max: 20000, label: '1 – 20K'),
      const _UsageRange(min: 20001, max: 50000, label: '20K – 50K'),
      const _UsageRange(min: 50001, max: 80000, label: '50K – 80K'),
      const _UsageRange(min: 80001, max: 90000, label: '80K – 90K'),
      const _UsageRange(min: 90001, max: 100000, label: '90K – 100K'),
      const _UsageRange(
        min: 100001,
        max: double.infinity,
        label: 'Greater than 100K',
      ),
    ];

    final counts = <String, int>{for (final range in ranges) range.label: 0};
    var unknownCount = 0;

    for (final item in data) {
      if (_isIgnoredCustomer(item)) {
        continue;
      }
      final value = item.totalUseTimes;
      if (value == null) {
        unknownCount++;
        continue;
      }

      final matched = ranges.firstWhere(
        (range) => range.matches(value),
        orElse: () => const _UsageRange(
          min: double.nan,
          max: double.nan,
          label: 'Unknown',
        ),
      );

      if (matched.label == 'Unknown') {
        unknownCount++;
      } else {
        counts[matched.label] = (counts[matched.label] ?? 0) + 1;
      }
    }

    final slices = counts.entries
        .where((entry) => entry.value > 0)
        .map((entry) => _PieSlice(entry.key, entry.value))
        .toList();

    if (unknownCount > 0) {
      slices.add(_PieSlice('Unknown', unknownCount));
    }

    return slices;
  }

  List<_PieSlice> _buildCheckTimeBuckets(List<StencilDetail> data) {
    final map = <String, int>{
      '0 – 6 Months': 0,
      '6 Months – 1 Year': 0,
      '1 – 2 Years': 0,
      'Over 2 Years': 0,
      'Unknown': 0,
    };

    final now = DateTime.now();
    for (final item in data) {
      if (_isIgnoredCustomer(item)) {
        continue;
      }
      final check = item.checkTime;
      if (check == null) {
        map['Unknown'] = map['Unknown']! + 1;
        continue;
      }

      final months = now.difference(check).inDays / 30.0;
      if (months <= 6) {
        map['0 – 6 Months'] = map['0 – 6 Months']! + 1;
      } else if (months <= 12) {
        map['6 Months – 1 Year'] = map['6 Months – 1 Year']! + 1;
      } else if (months <= 24) {
        map['1 – 2 Years'] = map['1 – 2 Years']! + 1;
      } else {
        map['Over 2 Years'] = map['Over 2 Years']! + 1;
      }
    }

    final order = {
      '0 – 6 Months': 0,
      '6 Months – 1 Year': 1,
      '1 – 2 Years': 2,
      'Over 2 Years': 3,
      'Unknown': 4,
    };

    final list = map.entries
        .where((entry) => entry.value > 0)
        .map((entry) => _PieSlice(entry.key, entry.value))
        .toList()
      ..sort((a, b) => (order[a.label] ?? 99).compareTo(order[b.label] ?? 99));

    return list;
  }

  Color _lineHoursColor(double hours) {
    if (hours >= 4) {
      return _palette.isDark
          ? Colors.redAccent.shade200
          : Colors.redAccent.shade400;
    }
    if (hours >= 3.5) {
      return _palette.isDark
          ? Colors.amberAccent.shade200
          : Colors.amberAccent.shade400;
    }
    return _palette.accentPrimary;
  }
}

class _PieSlice {
  _PieSlice(this.label, this.value);

  final String label;
  final int value;
}

class _LineTrackingDatum {
  _LineTrackingDatum({
    required this.category,
    required this.hours,
    required this.stencilSn,
    required this.startTime,
    required this.location,
    required this.totalUse,
  });

  final String category;
  final double hours;
  final String stencilSn;
  final DateTime startTime;
  final String location;
  final int? totalUse;
}

class _OverviewCardData {
  const _OverviewCardData({
    required this.title,
    required this.slices,
    required this.accent,
  });

  final String title;
  final List<_PieSlice> slices;
  final Color accent;
}

class _UsageRange {
  const _UsageRange({
    required this.min,
    required this.max,
    required this.label,
  });

  final double min;
  final double max;
  final String label;

  bool matches(num value) {
    final doubleVal = value.toDouble();
    return doubleVal >= min && doubleVal <= max;
  }
}

