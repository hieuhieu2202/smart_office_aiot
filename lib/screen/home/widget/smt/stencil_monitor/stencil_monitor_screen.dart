import 'dart:math' as math;
import 'dart:ui' as ui show TextDirection;

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
part 'widgets/stencil_monitor_detail_dialogs.dart';
part 'widgets/stencil_monitor_usage_chart.dart';

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

class _StencilMonitorScreenState extends State<StencilMonitorScreen>
    with TickerProviderStateMixin {
  late final String _controllerTag;
  late final StencilMonitorController controller;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  late _StencilColorScheme _palette;
  late final TextEditingController _lineTrackingSearchController;
  String _lineTrackingQuery = '';

  TabController? _overviewTabController;
  int _overviewTabIndex = 0;

  Color get _textPrimary => _palette.onSurface;
  Color get _textSecondary => _palette.onSurfaceMuted;
  Color get _axisLineColor => _palette.onSurface
      .withOpacity(_palette.isDark ? 0.25 : 0.2);

  @override
  void initState() {
    super.initState();
    _controllerTag = widget.controllerTag ?? 'stencil_monitor_default';
    controller = Get.put(StencilMonitorController(), tag: _controllerTag);
    _lineTrackingSearchController = TextEditingController()
      ..addListener(_handleLineTrackingQueryChanged);
  }

  @override
  void dispose() {
    _overviewTabController?.removeListener(_handleOverviewTabChange);
    _overviewTabController?.dispose();
    _lineTrackingSearchController.removeListener(_handleLineTrackingQueryChanged);
    _lineTrackingSearchController.dispose();
    if (Get.isRegistered<StencilMonitorController>(tag: _controllerTag)) {
      Get.delete<StencilMonitorController>(tag: _controllerTag);
    }
    super.dispose();
  }

  void _ensureOverviewTabController(int length) {
    assert(length > 0, 'Overview tab controller requires at least one tab');
    final controller = _overviewTabController;
    final desiredIndex = math.min(math.max(_overviewTabIndex, 0), length - 1);

    if (controller == null || controller.length != length) {
      controller?.removeListener(_handleOverviewTabChange);
      controller?.dispose();

      _overviewTabController = TabController(
        length: length,
        vsync: this,
        initialIndex: desiredIndex,
      )..addListener(_handleOverviewTabChange);
    } else if (controller.index != desiredIndex) {
      controller.index = desiredIndex;
    }

    _overviewTabIndex = _overviewTabController!.index;
  }

  void _handleOverviewTabChange() {
    final controller = _overviewTabController;
    if (controller == null || controller.indexIsChanging) {
      return;
    }

    if (_overviewTabIndex != controller.index) {
      setState(() {
        _overviewTabIndex = controller.index;
      });
    }
  }

  void _handleLineTrackingQueryChanged() {
    final query = _lineTrackingSearchController.text;
    if (query != _lineTrackingQuery) {
      setState(() {
        _lineTrackingQuery = query;
      });
    }
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
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (error.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, filtered.isEmpty ? 16 : 20),
              sliver: SliverToBoxAdapter(
                child: _buildErrorChip(error),
              ),
            ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildEmptyState(),
              ),
            )
          else ..._buildDashboardSlivers(
              context,
              filtered,
              includeTopPadding: error.isEmpty,
            ),
        ],
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

  List<Widget> _buildDashboardSlivers(
    BuildContext context,
    List<StencilDetail> filtered, {
    required bool includeTopPadding,
  }) {
    final customerSlices = _buildCustomerSlices(filtered);
    final statusSlices = _buildStatusSlices(filtered);
    final vendorSlices = _buildVendorSlices(filtered);
    final processSlices = _buildProcessSlices(filtered);

    final activeLines = _filterActiveLines(filtered);
    final lineTracking = _buildLineTracking(activeLines);
    final usingTimeSlices = _buildStandardBuckets(filtered);
    final checkSlices = _buildCheckTimeBuckets(filtered);

    final insights = _buildInsightMetrics(activeLines);

    final cards = [
      _OverviewCardData(
        title: 'CUSTOMER',
        slices: customerSlices,
        accent: _palette.accentPrimary,
      ),
      _OverviewCardData(
        title: 'STATUS',
        slices: statusSlices,
        accent: _palette.accentSecondary,
      ),
      _OverviewCardData(
        title: 'VENDOR',
        slices: vendorSlices,
        accent: _palette.isDark
            ? GlobalColors.borderDark
            : GlobalColors.borderLight,
      ),
      _OverviewCardData(
        title: 'STENCIL SIDE',
        slices: processSlices,
        accent: _palette.isDark
            ? GlobalColors.gradientDarkStart
            : GlobalColors.gradientLightStart,
      ),
    ];

    _ensureOverviewTabController(cards.length);
    final controller = _overviewTabController!;
    final activeIndex = math.min(math.max(controller.index, 0), cards.length - 1);
    final activeCard = cards[activeIndex];

    const sectionSpacing = 18.0;

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16, includeTopPadding ? 16 : 0, 16, 0),
        sliver: SliverPersistentHeader(
          pinned: true,
          delegate: _OverviewTabHeaderDelegate(
            palette: _palette,
            controller: controller,
            cards: cards,
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16, sectionSpacing, 16, sectionSpacing),
        sliver: SliverToBoxAdapter(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isWide = width >= 900;

              Widget buildOverviewSection() {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: KeyedSubtree(
                    key: ValueKey<String>(activeCard.title),
                    child: _buildOverviewCard(context, activeCard),
                  ),
                );
              }

              Widget? buildInsightsSection() {
                if (insights.isEmpty) return null;
                return _InsightsStrip(items: insights);
              }

              Widget buildUsageSection() {
                return _buildUsageAnalyticsCard(
                  context,
                  usingTimeSlices,
                  checkSlices,
                );
              }

              Widget buildLineTrackingSection() {
                return _buildLineTrackingCard(context, lineTracking);
              }

              final overviewSection = buildOverviewSection();
              final insightsSection = buildInsightsSection();
              final usageSection = buildUsageSection();
              final lineTrackingSection = buildLineTrackingSection();

              if (isWide) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (insightsSection != null) ...[
                              insightsSection,
                              const SizedBox(height: sectionSpacing),
                            ],
                            Expanded(child: usageSection),
                          ],
                        ),
                      ),
                      const SizedBox(width: sectionSpacing),
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            overviewSection,
                            const SizedBox(height: sectionSpacing),
                            lineTrackingSection,
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  overviewSection,
                  if (insightsSection != null) ...[
                    const SizedBox(height: sectionSpacing),
                    insightsSection,
                  ],
                  const SizedBox(height: sectionSpacing),
                  usageSection,
                  const SizedBox(height: sectionSpacing),
                  lineTrackingSection,
                ],
              );
            },
          ),
        ),
      ),
    ];
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

  Widget _buildOverviewCard(BuildContext context, _OverviewCardData data) {
    final palette = _palette;
    final total = data.slices.fold<int>(0, (sum, slice) => sum + slice.value);

    final titleStyle = GoogleFonts.spaceGrotesk(
      color: data.accent,
      fontSize: 14,
      letterSpacing: 0.8,
    );

    final totalStyle = GoogleFonts.spaceGrotesk(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: palette.onSurface,
    );

    final subtitleStyle = GoogleFonts.ibmPlexMono(
      fontSize: 11,
      color: palette.onSurfaceMuted,
    );

    return _buildOverviewContainer(
      accent: data.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(data.title, style: titleStyle)),
              if (total > 0)
                Text('$total', style: totalStyle),
              if (total > 0) ...[
                const SizedBox(width: 4),
                Text('items', style: subtitleStyle),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No data available',
                style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
                  fontFamily: _StencilTypography.numeric,
                  color: palette.onSurfaceMuted,
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.center,
              child: Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final slice in data.slices)
                    _buildSliceChip(slice, data.accent, palette),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliceChip(
    _PieSlice slice,
    Color accent,
    _StencilColorScheme palette,
  ) {
    final label = slice.label.trim().isEmpty ? 'Unknown' : slice.label.trim();
    final baseStyle = GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
      fontFamily: _StencilTypography.body,
      fontSize: 12,
      color: palette.onSurface,
    );
    final valueStyle = baseStyle.copyWith(
      fontFamily: _StencilTypography.numeric,
      fontWeight: FontWeight.w600,
      color: accent,
    );

    const indicatorSize = 8.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.4), width: 1),
        color: palette.surfaceOverlay.withOpacity(palette.isDark ? 0.6 : 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: indicatorSize,
            height: indicatorSize,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.85),
              borderRadius: BorderRadius.circular(indicatorSize / 2),
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              label,
              style: baseStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Text('${slice.value}', style: valueStyle),
        ],
      ),
    );
  }

  Widget _buildOverviewContainer({
    required Color accent,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
  }) {
    final palette = _palette;
    final borderRadius = BorderRadius.circular(20);

    final container = Container(
      margin: margin ?? EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: accent.withOpacity(0.3), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.cardBackground.withOpacity(palette.isDark ? 0.92 : 0.96),
            palette.surfaceOverlay.withOpacity(palette.isDark ? 0.5 : 0.4),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow.withOpacity(0.55),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: accent.withOpacity(0.15),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return container;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        splashColor: accent.withOpacity(0.12),
        highlightColor: accent.withOpacity(0.08),
        child: container,
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
    final metaStyle = GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
      fontFamily: _StencilTypography.numeric,
      fontSize: 11,
      color: _textSecondary,
    );

    final filtered = _filterLineTrackingData(data, _lineTrackingQuery);
    final top = filtered.take(8).toList();
    final maxHours = top.fold<double>(0, (max, item) => item.hours > max ? item.hours : max);
    final normalizedMax = maxHours <= 0 ? 1.0 : maxHours + 0.5;
    final query = _lineTrackingQuery.trim();
    final hasQuery = query.isNotEmpty;

    return _buildOverviewContainer(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'LINE TRACKING',
                  style: titleStyle,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: TextField(
                    controller: _lineTrackingSearchController,
                    style: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
                      fontFamily: _StencilTypography.numeric,
                      color: palette.onSurface,
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search line, location, or stencil SN',
                      hintStyle: GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
                        fontFamily: _StencilTypography.numeric,
                        color: palette.onSurfaceMuted,
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(Icons.search, color: _textSecondary, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: palette.surfaceOverlay.withOpacity(0.6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: palette.dividerColor.withOpacity(0.6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: palette.dividerColor.withOpacity(0.6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: accent),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
          if (filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                hasQuery
                    ? 'Showing ${top.length} of ${filtered.length} matches for "$query"'
                    : 'Top ${math.min(top.length, data.length)} of ${data.length} active lines by runtime',
                style: metaStyle,
              ),
            ),
          const SizedBox(height: 12),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                hasQuery
                    ? 'No lines found for "$query"'
                    : 'No active line runtime data available',
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
            if ((hasQuery ? filtered.length : data.length) > top.length)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _showLineTrackingDetail(
                    context,
                    data,
                    initialQuery: _lineTrackingQuery,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.auto_graph_rounded, size: 16),
                  label: Text(
                    hasQuery
                        ? 'View all ${filtered.length} matches'
                        : 'View & search all ${data.length} lines',
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
    final usesText =
        item.totalUse != null ? '${item.totalUse} uses' : 'Uses unknown';
    final snText = item.stencilSn.isNotEmpty ? item.stencilSn : 'Unknown';

    final radius = BorderRadius.circular(16);
    final content = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              valueColor: AlwaysStoppedAnimation<Color>(_lineHoursColor(item.hours)),
              backgroundColor: _lineHoursColor(item.hours).withOpacity(0.18),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${item.location} • ${_dateFormat.format(item.startTime)}',
            style: metaStyle,
          ),
          const SizedBox(height: 2),
          Text('SN $snText • $usesText', style: metaStyle),
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

  Widget _buildUsageAnalyticsCard(
    BuildContext context,
    List<_PieSlice> usingTime,
    List<_PieSlice> checkTime,
  ) {
    final palette = _palette;
    final usageAccent = palette.accentPrimary;
    final checkingAccent =
        palette.isDark ? GlobalColors.gradientDarkEnd : GlobalColors.gradientLightEnd;

    final usageData =
        _OverviewCardData(title: 'USING TIME', slices: usingTime, accent: usageAccent);
    final checkingData =
        _OverviewCardData(title: 'CHECKING TIME', slices: checkTime, accent: checkingAccent);

    final usageTotal = usageData.slices.fold<int>(0, (sum, slice) => sum + slice.value);
    final checkingTotal =
        checkingData.slices.fold<int>(0, (sum, slice) => sum + slice.value);

    final titleStyle = GoogleFonts.spaceGrotesk(
      color: usageAccent,
      fontSize: 15,
      letterSpacing: 1,
    );
    final subtitleStyle = GoogleFonts.ibmPlexMono(
      fontSize: 12,
      color: palette.onSurfaceMuted,
    );
    final totalStyle = GoogleFonts.spaceGrotesk(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: palette.onSurface,
    );
    final sectionLabelStyle = GoogleFonts.spaceGrotesk(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: palette.onSurface,
    );

    final usageLegend = usageData.slices.isEmpty
        ? null
        : Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final label in _usageLegendOrder)
                if (usageData.slices.any((slice) => slice.label == label))
                  _UsageLegendChip(
                    label: label,
                    color: _usageColorForLabel(label, palette),
                    textStyle: subtitleStyle,
                    palette: palette,
                  ),
            ],
          );

    final checkingBody = checkingData.slices.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No checking data recorded',
              style: subtitleStyle,
            ),
          )
        : Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final slice in checkingData.slices)
                _buildSliceChip(slice, checkingAccent, palette),
            ],
          );

    Widget buildContent({required bool expandChart, required BoxConstraints constraints}) {
      final chart = _UsagePrismChart(
        slices: usageData.slices,
        palette: palette,
      );

      final chartSection = expandChart
          ? Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: chart),
                  if (usageLegend != null) ...[
                    const SizedBox(height: 12),
                    usageLegend!,
                  ],
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 190, child: chart),
                if (usageLegend != null) ...[
                  const SizedBox(height: 10),
                  usageLegend!,
                ],
              ],
            );

      final children = <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Text(usageData.title, style: titleStyle)),
            if (usageTotal > 0) ...[
              Text('$usageTotal', style: totalStyle),
              const SizedBox(width: 4),
              Text('items', style: subtitleStyle),
            ],
          ],
        ),
        const SizedBox(height: 14),
        chartSection,
        const SizedBox(height: 12),
        Divider(color: palette.dividerColor.withOpacity(0.6)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                checkingData.title,
                style: sectionLabelStyle.copyWith(color: checkingAccent),
              ),
            ),
            if (checkingTotal > 0)
              Text(
                '$checkingTotal',
                style: totalStyle.copyWith(fontSize: 20, color: checkingAccent),
              ),
            const SizedBox(width: 4),
            Text('items', style: subtitleStyle.copyWith(fontSize: 11)),
          ],
        ),
        const SizedBox(height: 10),
        checkingBody,
      ];

      if (!expandChart) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      }

      return SizedBox(
        height: constraints.maxHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final expandChart = constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight > 0;

        return _buildOverviewContainer(
          accent: usageAccent,
          child: buildContent(expandChart: expandChart, constraints: constraints),
        );
      },
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
    final isNetworkError =
        message.trim() == StencilMonitorController.networkErrorMessage;
    final detailText =
        isNetworkError ? message : 'Error details: $message';

    final descriptionStyle = GlobalTextStyles.bodyMedium(isDark: _palette.isDark)
        .copyWith(
      fontFamily: _StencilTypography.body,
      color: _textSecondary,
      fontSize: 13,
      height: 1.45,
    );

    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: _palette.accentPrimary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: GlobalTextStyles.bodyMedium(isDark: _palette.isDark).copyWith(
        fontFamily: _StencilTypography.heading,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline,
              size: 56,
              color: _palette.errorText.withOpacity(0.9),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load stencil monitor data',
              textAlign: TextAlign.center,
              style: GlobalTextStyles.bodyLarge(isDark: _palette.isDark).copyWith(
                fontFamily: _StencilTypography.heading,
                color: _textPrimary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              detailText,
              textAlign: TextAlign.center,
              style: descriptionStyle,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: buttonStyle,
              onPressed: () => controller.fetchData(force: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reload'),
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

      final hours = now.difference(start).inMinutes / 60.0;
      final lineName = item.lineName?.trim() ?? '';
      final location = item.location?.trim() ?? '';
      final stencilSn = item.stencilSn?.trim() ?? '';
      final category = lineName.isNotEmpty
          ? lineName
          : location.isNotEmpty
              ? location
              : (stencilSn.isNotEmpty ? stencilSn : 'Unknown');

      list.add(
        _LineTrackingDatum(
          category: category,
          hours: hours < 0 ? 0.0 : hours,
          stencilSn: stencilSn,
          startTime: start,
          location: location.isNotEmpty ? location : '-',
          totalUse: item.totalUseTimes,
        ),
      );
    }

    list.sort((a, b) => b.hours.compareTo(a.hours));
    return list;
  }

  List<_LineTrackingDatum> _filterLineTrackingData(
    List<_LineTrackingDatum> items,
    String query,
  ) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return items;
    }

    return items
        .where(
          (datum) => datum.category.toLowerCase().contains(needle) ||
              datum.stencilSn.toLowerCase().contains(needle) ||
              datum.location.toLowerCase().contains(needle),
        )
        .toList();
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
      const _UsageRange(min: 1, max: 20000, label: '1–20K'),
      const _UsageRange(min: 20001, max: 50000, label: '20K–50K'),
      const _UsageRange(min: 50001, max: 80000, label: '50K–80K'),
      const _UsageRange(min: 80001, max: 90000, label: '80K–90K'),
      const _UsageRange(min: 90001, max: 100000, label: '90K–100K'),
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

class _OverviewTabHeaderDelegate extends SliverPersistentHeaderDelegate {
  _OverviewTabHeaderDelegate({
    required this.palette,
    required this.controller,
    required this.cards,
  });

  final _StencilColorScheme palette;
  final TabController controller;
  final List<_OverviewCardData> cards;

  @override
  double get minExtent => kTextTabBarHeight + 12;

  @override
  double get maxExtent => kTextTabBarHeight + 12;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final activeIndex = math.min(math.max(controller.index, 0), cards.length - 1);
    final activeCard = cards[activeIndex];

    final labelStyle = GlobalTextStyles.bodySmall(isDark: palette.isDark).copyWith(
      fontFamily: _StencilTypography.heading,
      fontWeight: FontWeight.w600,
      fontSize: 12,
      letterSpacing: 0.6,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: activeCard.accent.withOpacity(0.45)),
        color: palette.cardBackground,
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: TabBar(
        controller: controller,
        isScrollable: false,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 24),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: activeCard.accent, width: 3),
          insets: const EdgeInsets.symmetric(horizontal: 24),
        ),
        indicatorWeight: 3,
        labelPadding: EdgeInsets.zero,
        labelColor: activeCard.accent,
        unselectedLabelColor: palette.onSurfaceMuted,
        labelStyle: labelStyle,
        tabs: [
          for (final card in cards) Tab(text: card.title),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _OverviewTabHeaderDelegate oldDelegate) {
    return palette != oldDelegate.palette ||
        controller != oldDelegate.controller ||
        cards != oldDelegate.cards;
  }
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

