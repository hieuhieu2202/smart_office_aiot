import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../controllers/output_tracking_controller.dart';
import '../widgets/filter_panel.dart';
import '../widgets/detail_dialogs.dart';
import '../widgets/mobile_cards.dart';
import '../viewmodels/output_tracking_view_state.dart';
import '../viewmodels/series_utils.dart';
import '../widgets/table.dart';

class OutputTrackingPage extends StatefulWidget {
  const OutputTrackingPage({
    super.key,
    this.initialModelSerial = 'SWITCH',
  });

  final String initialModelSerial;

  @override
  State<OutputTrackingPage> createState() => _OutputTrackingPageState();
}

class _OutputTrackingPageState extends State<OutputTrackingPage> {
  late final OutputTrackingController _controller;
  late DateTime _selectedDate;
  late String _selectedShift;
  List<String> _selectedModels = const [];
  late final TextEditingController _searchCtl;
  Worker? _groupsWorker;

  static const List<String> _shiftOptions = ['Day', 'Night', 'All'];
  static const Color _pageBackground = Color(0xFF0B1422);

  @override
  void initState() {
    super.initState();
    final String desiredSerial = widget.initialModelSerial.trim().isEmpty
        ? 'SWITCH'
        : widget.initialModelSerial.trim().toUpperCase();

    _controller = Get.isRegistered<OutputTrackingController>()
        ? Get.find<OutputTrackingController>()
        : Get.put(
            OutputTrackingController(initialModelSerial: desiredSerial),
          );

    _selectedDate = _controller.date.value;
    _selectedShift = _controller.shift.value;
    _selectedModels = _controller.groups.toList();
    _searchCtl = TextEditingController();

    _groupsWorker = ever<List<String>>(_controller.groups, (list) {
      if (!mounted) return;
      setState(() {
        _selectedModels = List<String>.from(list);
      });
    });

    if (_controller.modelSerial.value != desiredSerial) {
      Future.microtask(() {
        if (!mounted) return;
        _controller.updateFilter(
          newModelSerial: desiredSerial,
          newGroups: const <String>[],
        );
      });
    }

    if (_controller.groups.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.ensureModels(force: true, selectAll: true);
      });
    }
  }

  @override
  void dispose() {
    _groupsWorker?.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _selectedDate,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _openModelPicker() async {
    await _controller.ensureModels(force: true);
    final allModels = _controller.allModels.toList();
    if (allModels.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có model để lựa chọn cho bộ lọc hiện tại.')),
      );
      return;
    }

    final result = await showOtModelPicker(
      context: context,
      allModels: allModels,
      initialSelection: _selectedModels.toSet(),
    );

    if (result != null) {
      setState(() {
        _selectedModels = result.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });
    }
  }

  void _onShiftChanged(String? newShift) {
    if (newShift == null) return;
    setState(() => _selectedShift = newShift);
  }

  Future<void> _showStationTrend(OtRowView row) async {
    final view = _controller.outputTrackingView.value;
    if (view == null || view.hours.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có dữ liệu biểu đồ cho trạm này.')),
      );
      return;
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => OtStationTrendDialog(
        station: row.station,
        hours: view.hours,
        metrics: row.metrics,
      ),
    );
  }

  Future<void> _showSectionDetail(OtRowView row, String section) async {
    if (section.trim().isEmpty) return;
    if (!mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final detail = await _controller.fetchOutputTrackingDetail(
        station: row.station,
        section: section,
      );

      final didPop = navigator.canPop();
      if (didPop) navigator.pop();
      if (!mounted) return;

      if (detail.errorDetails.isEmpty && detail.testerDetails.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có dữ liệu chi tiết cho khung giờ này.')),
        );
        return;
      }

      await showDialog(
        context: context,
        builder: (_) => OtSectionDetailDialog(
          station: row.station,
          section: section,
          detail: detail,
        ),
      );
    } catch (e) {
      if (navigator.canPop()) navigator.pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải dữ liệu chi tiết: $e')),
      );
    }
  }

  Future<void> _onQuery() async {
    final groups = _selectedModels.isEmpty
        ? _controller.groups.toList()
        : List<String>.from(_selectedModels);
    try {
      await _controller.updateFilter(
        newDate: _selectedDate,
        newShift: _selectedShift,
        newGroups: groups,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải dữ liệu: $e')),
      );
    }
  }

  void _handleSearchChanged(String value) {
    setState(() {});
  }

  void _clearSearch() {
    if (_searchCtl.text.isEmpty) return;
    setState(() {
      _searchCtl.clear();
    });
  }

  Future<void> _openFilterDrawer() async {
    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Bộ lọc',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final media = MediaQuery.of(dialogContext);
        final size = media.size;
        final bool isCompactWidth = size.width < 700;
        final double panelWidth = math.min(
          isCompactWidth ? size.width * 0.92 : size.width * 0.6,
          isCompactWidth ? 420.0 : 520.0,
        );

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerRight,
              child: Builder(
                builder: (panelContext) {
                  final navigator = Navigator.of(panelContext);

                  return StatefulBuilder(
                    builder: (context, setSheetState) {
                      Future<void> handlePickDate() async {
                        await _pickDate();
                        if (!mounted) return;
                        setSheetState(() {});
                      }

                      void handleShiftChange(String? value) {
                        _onShiftChanged(value);
                        setSheetState(() {});
                      }

                      Future<void> handleModelSelect() async {
                        await _openModelPicker();
                        if (!mounted) return;
                        setSheetState(() {});
                      }

                      void handleSearchChanged(String value) {
                        _handleSearchChanged(value);
                        setSheetState(() {});
                      }

                      void handleClearSearch() {
                        _clearSearch();
                        setSheetState(() {});
                      }

                      Future<void> handleQuery() async {
                        await _onQuery();
                        if (navigator.canPop()) navigator.pop();
                      }

                      return Obx(() {
                        final bool isBusy = _controller.isLoading.value;
                        final bool isLoadingModels =
                            _controller.isLoadingModels.value;

                        return Material(
                          color: Colors.transparent,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: panelWidth,
                              minWidth: math.min(panelWidth, 320),
                              maxHeight: size.height - 24,
                            ),
                            child: _FilterDrawer(
                              onClose: () {
                                if (navigator.canPop()) navigator.pop();
                              },
                              child: OtFilterToolbar(
                                dateText: _formatDate(_selectedDate),
                                shift: _selectedShift,
                                shiftOptions: _shiftOptions,
                                selectedModelCount: _selectedModels.length,
                                isBusy: isBusy,
                                isLoadingModels: isLoadingModels,
                                onPickDate: handlePickDate,
                                onShiftChanged: handleShiftChange,
                                onSelectModels: handleModelSelect,
                                onQuery: handleQuery,
                                isMobile: true,
                                isTablet: false,
                                useFullWidthLayout: true,
                                searchController: _searchCtl,
                                searchText: _searchCtl.text,
                                onSearchChanged: handleSearchChanged,
                                onClearSearch: handleClearSearch,
                              ),
                            ),
                          ),
                        );
                      });
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  double _computeTableHeight(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    int rowCount,
  ) {
    final size = MediaQuery.of(context).size;
    final reserved = isMobile
        ? 160.0
        : isTablet
            ? 210.0
            : 255.0;
    final base = size.height - reserved;
    final fallback = size.height * (isMobile ? 0.9 : 0.82);
    final candidate = base.isFinite && base > 320 ? base : fallback;
    final maxHeight = math.min(size.height * 0.98, math.max(320.0, candidate));

    final effectiveRows = rowCount <= 0 ? 1 : rowCount;
    final rowsHeight =
        (effectiveRows * OtTable.rowHeight) + ((effectiveRows - 1) * OtTable.rowGap);
    final naturalHeight = OtTable.headerHeight + rowsHeight;

    return naturalHeight <= maxHeight ? naturalHeight : maxHeight;
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizing) {
        final bool isPhone = sizing.deviceScreenType == DeviceScreenType.mobile;
        final bool isTabletDevice = sizing.deviceScreenType == DeviceScreenType.tablet;
        final double screenWidth = sizing.screenSize.width;
        final bool isCompactTablet =
            isTabletDevice && screenWidth < 900;
        final bool useCompactChrome = isPhone || isCompactTablet;
        final bool isLargeTablet = isTabletDevice && !isCompactTablet;
        final bool useCardList = isPhone;
        final bool useCardWrap = isCompactTablet;
        final bool showInlineFilters = !useCompactChrome;
        final double horizontalPadding = useCardList
            ? 12.0
            : useCardWrap
                ? 18.0
                : 20.0;
        final title = 'NVIDIA ${_controller.modelSerial.value} Output Tracking';

        return Obx(() {
          final isLoading = _controller.isLoading.value;
          final isLoadingModels = _controller.isLoadingModels.value;
          final error = _controller.error.value;
          final view = _controller.outputTrackingView.value;
          final allRows = view?.rows ?? const <OtRowView>[];
          final hours = view?.hours ?? const <String>[];
          final hasView = allRows.isNotEmpty && hours.isNotEmpty;
          final searchTerm = _searchCtl.text.trim().toLowerCase();
          final filteredRows = searchTerm.isEmpty
              ? allRows
              : allRows
                  .where((row) {
                    final station = row.station.toLowerCase();
                    final model = row.model.toLowerCase();
                    return station.contains(searchTerm) ||
                        model.contains(searchTerm);
                  })
                  .toList();
          final isFiltering = searchTerm.isNotEmpty;
          final hasLoadedOnce = _controller.hasLoadedOnce.value;

          return Scaffold(
            backgroundColor: _pageBackground,
            appBar: OtTopBar(
              title: title,
              isMobile: isPhone,
              isTablet: isLargeTablet,
              useCompactHeader: useCompactChrome,
              showInlineFilters: showInlineFilters,
              useFullWidthFilters: isPhone,
              onBack: Get.back,
              dateText: _formatDate(_selectedDate),
              shift: _selectedShift,
              shiftOptions: _shiftOptions,
              selectedModelCount: _selectedModels.length,
              isBusy: isLoading,
              isLoadingModels: isLoadingModels,
              onPickDate: _pickDate,
              onShiftChanged: _onShiftChanged,
              onSelectModels: _openModelPicker,
              onQuery: _onQuery,
              onRefresh: isLoading ? null : () { _controller.loadAll(); },
              searchController: _searchCtl,
              searchText: _searchCtl.text,
              onSearchChanged: _handleSearchChanged,
              onClearSearch: _clearSearch,
              onOpenFilters: showInlineFilters ? null : _openFilterDrawer,
            ),
            body: SafeArea(
              top: false,
              child: RefreshIndicator(
                color: Colors.cyanAccent,
                backgroundColor: const Color(0xFF0F233F),
                onRefresh: _controller.loadAll,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: _buildContentSlivers(
                    context: context,
                    isMobile: isPhone,
                    isTablet: isLargeTablet,
                    useCardList: useCardList,
                    useCardWrap: useCardWrap,
                    horizontalPadding: horizontalPadding,
                    isLoading: isLoading,
                    error: error,
                    hasView: hasView,
                    hasLoadedOnce: hasLoadedOnce,
                    view: view,
                    rows: filteredRows,
                    hours: hours,
                    isFiltering: isFiltering,
                    onClearSearch: _clearSearch,
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  List<Widget> _buildContentSlivers({
    required BuildContext context,
    required bool isMobile,
    required bool isTablet,
    required bool useCardList,
    required bool useCardWrap,
    required double horizontalPadding,
    required bool isLoading,
    required String? error,
    required bool hasView,
    required bool hasLoadedOnce,
    required OtViewState? view,
    required List<OtRowView> rows,
    required List<String> hours,
    required bool isFiltering,
    required VoidCallback onClearSearch,
  }) {
    if (isLoading && view == null) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (error != null && error.isNotEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _ErrorNotice(
            message: error,
            onRetry: _controller.loadAll,
          ),
        ),
      ];
    }

    final int? activeHourIndex = hasView
        ? findActiveHourIndex(hours, _selectedDate)
        : null;

    if (!hasView) {
      if (!hasLoadedOnce || isLoading) {
        return const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      }
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: const _EmptyNotice(),
        ),
      ];
    }

    if (rows.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: isFiltering
              ? _FilteredEmptyNotice(onClear: onClearSearch)
              : const _EmptyNotice(),
        ),
      ];
    }

    if (useCardList) {
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final row = rows[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index == rows.length - 1 ? 0 : 14),
                  child: OtMobileRowCard(
                    row: row,
                    hours: hours,
                    activeHourIndex: activeHourIndex,
                    onStationTap: () => _showStationTrend(row),
                    onSectionTap: (section) => _showSectionDetail(row, section),
                  ),
                );
              },
              childCount: rows.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ];
    }

    if (useCardWrap) {
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 24),
          sliver: SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double spacing = 18.0;
                final double maxWidth = constraints.maxWidth;
                final int columnCount = maxWidth >= 1024
                    ? 3
                    : maxWidth >= 720
                        ? 2
                        : 1;
                final double itemWidth = columnCount <= 1
                    ? maxWidth
                    : (maxWidth - spacing * (columnCount - 1)) / columnCount;

                return Align(
                  alignment:
                      columnCount <= 1 ? Alignment.center : Alignment.centerLeft,
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final row in rows)
                        SizedBox(
                          width: itemWidth,
                          child: OtMobileRowCard(
                            row: row,
                            hours: hours,
                            activeHourIndex: activeHourIndex,
                            onStationTap: () => _showStationTrend(row),
                            onSectionTap: (section) =>
                                _showSectionDetail(row, section),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 12),
        sliver: SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            color: const Color(0xFF0D213A),
            child: SizedBox(
              width: double.infinity,
              height: _computeTableHeight(
                context,
                isMobile,
                isTablet,
                rows.length,
              ),
              child: OtTable(
                view: view!,
                rowsOverride: rows,
                activeHourIndex: activeHourIndex,
                onStationTap: _showStationTrend,
                onSectionTap: _showSectionDetail,
              ),
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
    ];
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.cyanAccent),
            const SizedBox(height: 18),
            Text(
              'Không thể tải dữ liệu',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4C2CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotice extends StatelessWidget {
  const _EmptyNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 56, color: Colors.white54),
          const SizedBox(height: 16),
          Text(
            'Không có dữ liệu',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng thử lại sau.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilteredEmptyNotice extends StatelessWidget {
  const _FilteredEmptyNotice({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 56, color: Colors.white54),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy kết quả phù hợp',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng điều chỉnh từ khóa tìm kiếm.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onClear,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4C2CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xóa tìm kiếm'),
          ),
        ],
      ),
    );
  }
}

class OtTopBar extends StatelessWidget implements PreferredSizeWidget {
  OtTopBar({
    super.key,
    required this.title,
    required this.isMobile,
    required this.isTablet,
    required this.useCompactHeader,
    required this.showInlineFilters,
    required this.useFullWidthFilters,
    required this.onBack,
    required this.dateText,
    required this.shift,
    required this.shiftOptions,
    required this.selectedModelCount,
    required this.isBusy,
    required this.isLoadingModels,
    required this.onPickDate,
    required this.onShiftChanged,
    required this.onSelectModels,
    required this.onQuery,
    required this.onRefresh,
    required this.searchController,
    required this.searchText,
    required this.onSearchChanged,
    required this.onClearSearch,
    this.onOpenFilters,
  }) : preferredSize = Size.fromHeight(
          _calcPreferredHeight(
            useCompactHeader: useCompactHeader,
            isTablet: isTablet,
            showInlineFilters: showInlineFilters,
          ),
        );

  final String title;
  final bool isMobile;
  final bool isTablet;
  final bool useCompactHeader;
  final bool showInlineFilters;
  final bool useFullWidthFilters;
  final VoidCallback? onBack;
  final String dateText;
  final String shift;
  final List<String> shiftOptions;
  final int selectedModelCount;
  final bool isBusy;
  final bool isLoadingModels;
  final VoidCallback onPickDate;
  final ValueChanged<String?> onShiftChanged;
  final VoidCallback onSelectModels;
  final VoidCallback onQuery;
  final VoidCallback? onRefresh;
  final TextEditingController searchController;
  final String searchText;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback? onOpenFilters;

  @override
  final Size preferredSize;

  static double _calcPreferredHeight({
    required bool useCompactHeader,
    required bool isTablet,
    required bool showInlineFilters,
  }) {
    if (!showInlineFilters) {
      return useCompactHeader
          ? 118
          : isTablet
              ? 170
              : 160;
    }
    return useCompactHeader
        ? 252
        : isTablet
            ? 220
            : 206;
  }

  @override
  Widget build(BuildContext context) {
    const gradientTop = Color(0xFF162B4F);
    const gradientBottom = Color(0xFF101C32);

    final headerHeight = useCompactHeader ? 48.0 : 54.0;
    final horizontalPadding = useCompactHeader ? 16.0 : 24.0;

    Widget buildHeader() {
      final backButton = _HeaderActionButton(
        icon: Icons.arrow_back_ios_new,
        tooltip: 'Quay lại',
        onTap: onBack,
        size: useCompactHeader ? 42.0 : 46.0,
      );

      final refreshButton = _HeaderActionButton(
        icon: Icons.refresh,
        tooltip: 'Tải lại ngay',
        onTap: onRefresh,
        isBusy: isBusy,
        size: useCompactHeader ? 42.0 : 46.0,
      );

      final filterButton = _HeaderActionButton(
        icon: Icons.tune,
        tooltip: 'Bộ lọc',
        onTap: onOpenFilters,
        size: useCompactHeader ? 42.0 : 46.0,
      );

      final titleWidget = Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: .3,
                  ) ??
              const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: .3,
              ),
        ),
      );

      if (!useCompactHeader) {
        return SizedBox(
          height: headerHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              backButton,
              const SizedBox(width: 14),
              titleWidget,
              const SizedBox(width: 12),
              refreshButton,
              if (!showInlineFilters) ...[
                const SizedBox(width: 10),
                filterButton,
              ],
            ],
          ),
        );
      }

      return SizedBox(
        height: headerHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            backButton,
            const SizedBox(width: 12),
            titleWidget,
            const SizedBox(width: 12),
            refreshButton,
            if (!showInlineFilters) ...[
              const SizedBox(width: 10),
              filterButton,
            ],
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientTop, gradientBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            useCompactHeader ? 14 : 20,
            horizontalPadding,
            useCompactHeader
                ? (showInlineFilters ? 18 : 14)
                : (showInlineFilters ? 22 : 18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              buildHeader(),
              if (showInlineFilters) ...[
                SizedBox(height: useCompactHeader ? 16 : 20),
                OtFilterToolbar(
                  dateText: dateText,
                  shift: shift,
                  shiftOptions: shiftOptions,
                  selectedModelCount: selectedModelCount,
                  isBusy: isBusy,
                  isLoadingModels: isLoadingModels,
                  onPickDate: onPickDate,
                  onShiftChanged: onShiftChanged,
                  onSelectModels: onSelectModels,
                  onQuery: onQuery,
                  isMobile: isMobile,
                  isTablet: isTablet,
                  useFullWidthLayout: useFullWidthFilters,
                  searchController: searchController,
                  searchText: searchText,
                  onSearchChanged: onSearchChanged,
                  onClearSearch: onClearSearch,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterDrawer extends StatelessWidget {
  const _FilterDrawer({
    required this.onClose,
    required this.child,
  });

  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(22),
        bottomLeft: Radius.circular(22),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F233F),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 18,
              offset: Offset(-6, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A3057), Color(0xFF13233D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: Colors.cyanAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bộ lọc',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ) ??
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFF1F314F),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.isBusy = false,
    this.size = 46.0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isBusy;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.08),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isBusy ? null : onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: isBusy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                      ),
                    )
                  : Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class OtFilterToolbar extends StatelessWidget {
  const OtFilterToolbar({
    super.key,
    required this.dateText,
    required this.shift,
    required this.shiftOptions,
    required this.selectedModelCount,
    required this.isBusy,
    required this.isLoadingModels,
    required this.onPickDate,
    required this.onShiftChanged,
    required this.onSelectModels,
    required this.onQuery,
    required this.isMobile,
    required this.isTablet,
    required this.useFullWidthLayout,
    required this.searchController,
    required this.searchText,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  final String dateText;
  final String shift;
  final List<String> shiftOptions;
  final int selectedModelCount;
  final bool isBusy;
  final bool isLoadingModels;
  final VoidCallback onPickDate;
  final ValueChanged<String?> onShiftChanged;
  final VoidCallback onSelectModels;
  final VoidCallback onQuery;
  final bool isMobile;
  final bool isTablet;
  final bool useFullWidthLayout;
  final TextEditingController searchController;
  final String searchText;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  static const Color _fieldColor = Color(0xFF1A2740);
  static const Color _borderColor = Color(0xFF2C3B5A);

  @override
  Widget build(BuildContext context) {
    final bool stretchFields = useFullWidthLayout || isMobile;
    final double wideField = stretchFields
        ? double.infinity
        : isTablet
            ? 240
            : 260;
    final double compactField = stretchFields
        ? double.infinity
        : isTablet
            ? 190
            : 200;

    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
          letterSpacing: .2,
        );

    Widget buildDateField() {
      final disabled = isBusy;
      return _FilterField(
        width: wideField,
        label: 'Date',
        labelStyle: labelStyle,
        child: InkWell(
          onTap: disabled ? null : onPickDate,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _fieldDecoration(disabled),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dateText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_month,
                  color: disabled ? Colors.white38 : Colors.cyanAccent,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildShiftField() {
      final disabled = isBusy;
      final current = shiftOptions.contains(shift) ? shift : shiftOptions.first;
      return _FilterField(
        width: compactField,
        label: 'Shift',
        labelStyle: labelStyle,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: _fieldDecoration(disabled),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              dropdownColor: const Color(0xFF15223D),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              onChanged: disabled ? null : onShiftChanged,
              items: [
                for (final item in shiftOptions)
                  DropdownMenuItem(
                    value: item,
                    child: Text(item.toUpperCase()),
                  ),
              ],
              iconEnabledColor: Colors.cyanAccent,
              iconDisabledColor: Colors.white38,
              isExpanded: true,
            ),
          ),
        ),
      );
    }

    Widget buildModelField() {
      final disabled = isBusy || isLoadingModels;
      final label = selectedModelCount > 0
          ? 'Selected: $selectedModelCount'
          : 'Select Models';
      return _FilterField(
        width: wideField,
        label: 'Models',
        labelStyle: labelStyle,
        child: InkWell(
          onTap: disabled ? null : onSelectModels,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _fieldDecoration(disabled),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isLoadingModels)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildSearchField() {
      return _FilterField(
        width: wideField,
        label: 'Search',
        labelStyle: labelStyle,
        child: TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: 'Search station or model',
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
            prefixIcon:
                const Icon(Icons.search, color: Colors.white54, size: 18),
            suffixIcon: searchText.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear,
                        color: Colors.white54, size: 18),
                    onPressed: onClearSearch,
                  )
                : null,
            filled: true,
            fillColor: _fieldColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _borderColor.withOpacity(.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );
    }

    Widget buildActions() {
      final query = OtToolbarButton(
        label: isBusy ? 'LOADING...' : 'QUERY',
        icon: Icons.search,
        backgroundColor: const Color(0xFF6238F5),
        onPressed: isBusy ? null : onQuery,
      );

      if (useFullWidthLayout || isMobile) {
        return SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              query,
            ],
          ),
        );
      }

      final actionWidth = isTablet ? 200.0 : 220.0;
      return _FilterField(
        width: actionWidth,
        label: 'Action',
        labelStyle: labelStyle,
        child: query,
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      crossAxisAlignment: WrapCrossAlignment.start,
      alignment:
          (useFullWidthLayout || isMobile) ? WrapAlignment.center : WrapAlignment.start,
      children: [
        buildDateField(),
        buildShiftField(),
        buildModelField(),
        buildSearchField(),
        buildActions(),
      ],
    );
  }

  BoxDecoration _fieldDecoration(bool disabled) {
    return BoxDecoration(
      color: disabled ? _fieldColor.withOpacity(.55) : _fieldColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _borderColor.withOpacity(.8)),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.width,
    required this.label,
    required this.labelStyle,
    required this.child,
  });

  final double width;
  final String label;
  final TextStyle? labelStyle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class OtToolbarButton extends StatelessWidget {
  const OtToolbarButton({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final bg = disabled ? backgroundColor.withOpacity(.45) : backgroundColor;
    final borderColor = backgroundColor.withOpacity(.7);

    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: .3),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: borderColor.withOpacity(.8)),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
      ),
    );
  }
}
