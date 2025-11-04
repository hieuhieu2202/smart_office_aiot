import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../controllers/upd_tracking_controller.dart';
import '../viewmodels/upd_tracking_view_state.dart';
import '../widgets/filter_panel.dart';
import '../widgets/tracking_tables.dart';
import 'output_tracking_page.dart' show OtFilterToolbar, OtTopBar;

class UpdTrackingPage extends StatefulWidget {
  const UpdTrackingPage({
    super.key,
    this.initialModelSerial = 'SWITCH',
  });

  final String initialModelSerial;

  @override
  State<UpdTrackingPage> createState() => _UpdTrackingPageState();
}

class _UpdTrackingPageState extends State<UpdTrackingPage> {
  late final UpdTrackingController _controller;
  late DateTimeRange _selectedRange;
  List<String> _selectedModels = const [];
  late final TextEditingController _searchCtl;
  Worker? _groupsWorker;

  static const List<String> _shiftOptions = ['ALL'];
  static const Color _pageBackground = Color(0xFF0B1422);

  @override
  void initState() {
    super.initState();

    final desiredSerial = widget.initialModelSerial.trim().isEmpty
        ? 'SWITCH'
        : widget.initialModelSerial.trim().toUpperCase();

    _controller = Get.isRegistered<UpdTrackingController>()
        ? Get.find<UpdTrackingController>()
        : Get.put(UpdTrackingController(initialModelSerial: desiredSerial));

    _selectedRange = _controller.range.value;
    _selectedModels = _controller.selectedGroups.toList();
    _searchCtl = TextEditingController();

    _groupsWorker = ever<List<String>>(_controller.selectedGroups, (list) {
      if (!mounted) return;
      setState(() {
        _selectedModels = List<String>.from(list);
      });
    });

    if (_controller.modelSerial.value != desiredSerial) {
      Future.microtask(() {
        if (!mounted) return;
        _controller.updateFilter(newModelSerial: desiredSerial);
      });
    }

    if (_controller.allGroups.isEmpty) {
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

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedRange,
      saveText: 'Chọn',
    );
    if (picked != null) {
      setState(() => _selectedRange = picked);
    }
  }

  Future<void> _openModelPicker() async {
    await _controller.ensureModels(force: true);
    final allModels = _controller.allGroups.toList();
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

  Future<void> _onQuery() async {
    final groups = _selectedModels.isEmpty
        ? _controller.selectedGroups.toList()
        : List<String>.from(_selectedModels);
    try {
      await _controller.updateFilter(
        newRange: _selectedRange,
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
                      Future<void> handlePickRange() async {
                        await _pickRange();
                        if (!mounted) return;
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
                                dateText: _formatRange(_selectedRange),
                                shift: 'ALL',
                                shiftOptions: _shiftOptions,
                                selectedModelCount: _selectedModels.length,
                                isBusy: isBusy,
                                isLoadingModels: isLoadingModels,
                                onPickDate: handlePickRange,
                                onShiftChanged: (_) {},
                                onSelectModels: handleModelSelect,
                                onQuery: handleQuery,
                                isMobile: true,
                                isTablet: false,
                                useFullWidthLayout: true,
                                searchController: _searchCtl,
                                searchText: _searchCtl.text,
                                onSearchChanged: handleSearchChanged,
                                onClearSearch: handleClearSearch,
                                showShiftField: false,
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
    final rowsHeight = (effectiveRows * 52) + ((effectiveRows - 1) * 0.6);
    final naturalHeight = 56 + 36 + rowsHeight;

    return naturalHeight <= maxHeight ? naturalHeight : maxHeight;
  }

  String _formatRange(DateTimeRange range) {
    final start = _formatDate(range.start);
    final end = _formatDate(range.end);
    return '$start ~ $end';
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _formatTime(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    final ss = d.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizing) {
        final bool isPhone = sizing.deviceScreenType == DeviceScreenType.mobile;
        final bool isTabletDevice = sizing.deviceScreenType == DeviceScreenType.tablet;
        final double screenWidth = sizing.screenSize.width;
        final bool isCompactTablet = isTabletDevice && screenWidth < 900;
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
        final title = 'NVIDIA ${_controller.modelSerial.value} UPD Tracking';

        return Obx(() {
          final isLoading = _controller.isLoading.value;
          final isLoadingModels = _controller.isLoadingModels.value;
          final isRefreshing = _controller.isRefreshing.value;
          final error = _controller.error.value;
          final view = _controller.viewState.value;
          final allRows = view?.rows ?? const <UpdTrackingRowView>[];
          final dates = view?.dates ?? const <String>[];
          final hasView = view != null && view.hasData;
          final DateTime? lastUpdatedAt = _controller.lastUpdatedAt.value;
          final bool showUpdateBadge = _controller.showUpdateBadge.value;
          final searchTerm = _searchCtl.text.trim().toLowerCase();
          final filteredRows = searchTerm.isEmpty
              ? allRows
              : allRows
                  .where((row) => row.station.toLowerCase().contains(searchTerm))
                  .toList();
          final isFiltering = searchTerm.isNotEmpty;
          final hasLoadedOnce = _controller.hasLoadedOnce.value;
          final String? statusText = isRefreshing
              ? 'Đang cập nhật dữ liệu…'
              : lastUpdatedAt != null
                  ? (showUpdateBadge
                      ? 'Đã cập nhật lúc ${_formatTime(lastUpdatedAt)}'
                      : 'Cập nhật: ${_formatTime(lastUpdatedAt)}')
                  : null;
          final bool statusHighlight = !isRefreshing && showUpdateBadge;
          final String? updateBannerLabel = showUpdateBadge && lastUpdatedAt != null
              ? 'Đã cập nhật lúc ${_formatTime(lastUpdatedAt)}'
              : null;

          void handleBack() {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
              return;
            }
            if (Get.key.currentState?.canPop() ?? false) {
              Get.back();
            }
          }

          return Scaffold(
            backgroundColor: _pageBackground,
            appBar: OtTopBar(
              title: title,
              isMobile: isPhone,
              isTablet: isLargeTablet,
              useCompactHeader: useCompactChrome,
              showInlineFilters: showInlineFilters,
              useFullWidthFilters: isPhone,
              onBack: handleBack,
              showShiftField: false,
              statusText: statusText,
              statusHighlight: statusHighlight,
              isRefreshing: isRefreshing,
              dateText: _formatRange(_selectedRange),
              shift: 'ALL',
              shiftOptions: _shiftOptions,
              selectedModelCount: _selectedModels.length,
              isBusy: isLoading,
              isLoadingModels: isLoadingModels,
              onPickDate: _pickRange,
              onShiftChanged: (_) {},
              onSelectModels: _openModelPicker,
              onQuery: _onQuery,
              onRefresh: isLoading ? null : () => _controller.loadAll(),
              searchController: _searchCtl,
              searchText: _searchCtl.text,
              onSearchChanged: _handleSearchChanged,
              onClearSearch: _clearSearch,
              screenWidth: screenWidth,
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
                    dates: dates,
                    isFiltering: isFiltering,
                    onClearSearch: _clearSearch,
                    showUpdateBanner: showUpdateBadge,
                    updateBannerLabel: updateBannerLabel,
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
    required UpdTrackingViewState? view,
    required List<UpdTrackingRowView> rows,
    required List<String> dates,
    required bool isFiltering,
    required VoidCallback onClearSearch,
    required bool showUpdateBanner,
    required String? updateBannerLabel,
  }) {
    Widget buildUpdateBanner() {
      if (!showUpdateBanner || updateBannerLabel == null) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B334F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyanAccent.withOpacity(.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.cyanAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                updateBannerLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isLoading && !hasView) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          ),
        ),
      ];
    }

    if (error != null && error.trim().isNotEmpty) {
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

    if (!isLoading && hasLoadedOnce && rows.isEmpty) {
      if (isFiltering) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _FilteredEmptyNotice(onClear: onClearSearch),
          ),
        ];
      }

      if (!hasView) {
        return const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyNotice(),
          ),
        ];
      }
    }

    return [
      if (showUpdateBanner && updateBannerLabel != null)
        SliverToBoxAdapter(child: buildUpdateBanner()),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        sliver: SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F233F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Các model',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  view?.modelsText ?? '-',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          16,
          horizontalPadding,
          24,
        ),
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
              child: UpdTrackingTable(
                view: view!,
                rows: rows,
                onStationTap: (row) {
                  // Placeholder for potential station detail actions.
                },
              ),
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
    ];
  }
}

class _FilterDrawer extends StatelessWidget {
  const _FilterDrawer({required this.onClose, required this.child});

  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F233F),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(child: child),
            ),
          ],
        ),
      ),
    );
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
