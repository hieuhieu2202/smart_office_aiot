import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../../controller/nvidia_lc_switch_kanban_controller.dart';
import 'filter_panel.dart';
import 'mobile_cards.dart';
import 'output_tracking_view_state.dart';
import 'table.dart';

class OutputTrackingScreen extends StatefulWidget {
  const OutputTrackingScreen({super.key});

  @override
  State<OutputTrackingScreen> createState() => _OutputTrackingScreenState();
}

class _OutputTrackingScreenState extends State<OutputTrackingScreen> {
  late final KanbanController _controller;
  late DateTime _selectedDate;
  late String _selectedShift;
  List<String> _selectedModels = const [];
  Worker? _groupsWorker;

  static const List<String> _shiftOptions = ['Day', 'Night', 'All'];
  static const Color _pageBackground = Color(0xFF0B1422);

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<KanbanController>()
        ? Get.find<KanbanController>()
        : Get.put(KanbanController());

    _selectedDate = _controller.date.value;
    _selectedShift = _controller.shift.value;
    _selectedModels = _controller.groups.toList();

    _groupsWorker = ever<List<String>>(_controller.groups, (list) {
      if (!mounted) return;
      setState(() {
        _selectedModels = List<String>.from(list);
      });
    });

    if (_controller.groups.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.ensureModels(force: true, selectAll: true);
      });
    }
  }

  @override
  void dispose() {
    _groupsWorker?.dispose();
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

  void _onExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng Export Excel sẽ sớm có mặt.')),
    );
  }

  double _computeTableHeight(BuildContext context, bool isMobile, bool isTablet) {
    final size = MediaQuery.of(context).size;
    final reserved = isMobile
        ? 320.0
        : isTablet
            ? 360.0
            : 380.0;
    final base = size.height - reserved;
    final fallback = size.height * (isMobile ? 0.78 : 0.68);
    final candidate = base.isFinite && base > 220 ? base : fallback;
    final maxHeight = size.height * 0.92;
    return candidate
        .clamp(320.0, math.max(320.0, maxHeight))
        .toDouble();
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
        final isMobile = sizing.deviceScreenType == DeviceScreenType.mobile;
        final isTablet = sizing.deviceScreenType == DeviceScreenType.tablet;
        final horizontalPadding = isMobile ? 12.0 : 20.0;
        final title = 'NVIDIA ${_controller.modelSerial.value} Output Tracking';

        return Obx(() {
          final isLoading = _controller.isLoading.value;
          final isLoadingModels = _controller.isLoadingModels.value;
          final error = _controller.error.value;
          final view = _controller.outputTrackingView.value;
          final rows = view?.rows ?? const <OtRowView>[];
          final hours = view?.hours ?? const <String>[];
          final hasView = rows.isNotEmpty && hours.isNotEmpty;

          return Scaffold(
            backgroundColor: _pageBackground,
            appBar: OtTopBar(
              title: title,
              isMobile: isMobile,
              isTablet: isTablet,
              dateText: _formatDate(_selectedDate),
              shift: _selectedShift,
              shiftOptions: _shiftOptions,
              selectedModelCount: _selectedModels.length,
              isBusy: isLoading,
              isLoadingModels: isLoadingModels,
              onPickDate: _pickDate,
              onShiftChanged: _onShiftChanged,
              onSelectModels: _openModelPicker,
              onExport: _onExport,
              onQuery: _onQuery,
              onRefresh: isLoading ? null : () { _controller.loadAll(); },
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
                    isMobile: isMobile,
                    isTablet: isTablet,
                    horizontalPadding: horizontalPadding,
                    isLoading: isLoading,
                    error: error,
                    hasView: hasView,
                    view: view,
                    rows: rows,
                    hours: hours,
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
    required double horizontalPadding,
    required bool isLoading,
    required String? error,
    required bool hasView,
    required OtViewState? view,
    required List<OtRowView> rows,
    required List<String> hours,
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
          child: _StateBox(
            icon: Icons.error_outline,
            title: 'Không thể tải dữ liệu',
            subtitle: error,
            actionText: 'Thử lại',
            onPressed: _controller.loadAll,
          ),
        ),
      ];
    }

    if (!hasView) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _StateBox(
            icon: Icons.inbox_outlined,
            title: 'Không có dữ liệu',
            subtitle: 'Vui lòng điều chỉnh bộ lọc và thử lại.',
            actionText: 'Tải lại',
            onPressed: _controller.loadAll,
          ),
        ),
      ];
    }

    if (isMobile) {
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
                  ),
                );
              },
              childCount: rows.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 28),
        sliver: SliverToBoxAdapter(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF0F223F),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(.05)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: _computeTableHeight(context, isMobile, isTablet),
                child: OtTable(view: view!),
              ),
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 28)),
    ];
  }
}

class _StateBox extends StatelessWidget {
  const _StateBox({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          color: const Color(0xFF12203C),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 54, color: Colors.cyanAccent),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 160,
                  child: FilledButton(
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4C2CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(actionText),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    required this.dateText,
    required this.shift,
    required this.shiftOptions,
    required this.selectedModelCount,
    required this.isBusy,
    required this.isLoadingModels,
    required this.onPickDate,
    required this.onShiftChanged,
    required this.onSelectModels,
    required this.onExport,
    required this.onQuery,
    required this.onRefresh,
  }) : preferredSize = Size.fromHeight(
          isMobile
              ? 220
              : isTablet
                  ? 200
                  : 188,
        );

  final String title;
  final bool isMobile;
  final bool isTablet;
  final String dateText;
  final String shift;
  final List<String> shiftOptions;
  final int selectedModelCount;
  final bool isBusy;
  final bool isLoadingModels;
  final VoidCallback onPickDate;
  final ValueChanged<String?> onShiftChanged;
  final VoidCallback onSelectModels;
  final VoidCallback onExport;
  final VoidCallback onQuery;
  final VoidCallback? onRefresh;

  @override
  final Size preferredSize;

  @override
  Widget build(BuildContext context) {
    const gradientTop = Color(0xFF162B4F);
    const gradientBottom = Color(0xFF101C32);

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
          padding: EdgeInsets.fromLTRB(16, isMobile ? 12 : 16, 16, 18),
          child: Column(
            crossAxisAlignment:
                isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      textAlign: isMobile ? TextAlign.center : TextAlign.left,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: .4,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Tải lại ngay',
                    onPressed: onRefresh,
                    icon: isBusy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                            ),
                          )
                        : const Icon(Icons.refresh, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
                onExport: onExport,
                onQuery: onQuery,
                isMobile: isMobile,
                isTablet: isTablet,
              ),
            ],
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
    required this.onExport,
    required this.onQuery,
    required this.isMobile,
    required this.isTablet,
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
  final VoidCallback onExport;
  final VoidCallback onQuery;
  final bool isMobile;
  final bool isTablet;

  static const Color _fieldColor = Color(0xFF1A2740);
  static const Color _borderColor = Color(0xFF2C3B5A);

  @override
  Widget build(BuildContext context) {
    final double wideField = isMobile
        ? double.infinity
        : isTablet
            ? 240
            : 260;
    final double compactField = isMobile
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

    Widget buildActions() {
      final export = OtToolbarButton(
        label: 'EXPORT EXCEL',
        icon: Icons.file_download_outlined,
        backgroundColor: const Color(0xFF1E7B4E),
        onPressed: isBusy ? null : onExport,
      );
      final query = OtToolbarButton(
        label: isBusy ? 'LOADING...' : 'QUERY',
        icon: Icons.search,
        backgroundColor: const Color(0xFF6238F5),
        onPressed: isBusy ? null : onQuery,
      );

      if (isMobile) {
        return SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              export,
              const SizedBox(height: 10),
              query,
            ],
          ),
        );
      }

      return SizedBox(
        width: isTablet ? 320 : 360,
        child: Row(
          children: [
            Expanded(child: export),
            const SizedBox(width: 12),
            Expanded(child: query),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
      children: [
        buildDateField(),
        buildShiftField(),
        buildModelField(),
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
