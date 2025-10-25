import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../../model/te_management/te_report_models.dart';
import '../../../../widget/animation/loading/eva_loading_view.dart';
import '../../controller/te_management_controller.dart';

const Color _backgroundColor = Color(0xFF050F1F);
const Color _surfaceColor = Color(0xFF111F34);
const Color _headerColor = Color(0xFF0C2748);
const Color _borderColor = Color(0xFF1F3A5F);
const Color _rowColor = Color(0xFF10213A);
const Color _rowAltColor = Color(0xFF0D1B30);
const Color _textPrimary = Color(0xFFE2E8F0);
const Color _textMuted = Color(0xFF9AB3CF);
const Color _accentCyan = Color(0xFF22D3EE);

class TEManagementScreen extends StatefulWidget {
  const TEManagementScreen({
    super.key,
    this.initialModelSerial = 'SWITCH',
    this.initialModel = '',
    this.controllerTag,
    this.title,
  });

  final String initialModelSerial;
  final String initialModel;
  final String? controllerTag;
  final String? title;

  @override
  State<TEManagementScreen> createState() => _TEManagementScreenState();
}

class _TEManagementScreenState extends State<TEManagementScreen> {
  static const double _rowHeight = 48;
  static const double _indexWidth = 64;
  static const double _modelWidth = 220;

  static const List<_ColumnDef> _columns = [
    _ColumnDef(
      label: 'GROUP NAME',
      width: 220,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 12),
    ),
    _ColumnDef(label: 'WIP QTY', width: 110),
    _ColumnDef(label: 'INPUT', width: 110),
    _ColumnDef(label: 'FIRST FAIL', width: 120),
    _ColumnDef(label: 'REPAIR QTY', width: 120),
    _ColumnDef(label: 'FIRST PASS', width: 120),
    _ColumnDef(label: 'REPAIR PASS', width: 130),
    _ColumnDef(label: 'PASS', width: 110),
    _ColumnDef(label: 'TOTAL PASS', width: 130),
    _ColumnDef(label: 'F.P.R', width: 110),
    _ColumnDef(label: 'Y.R', width: 110),
    _ColumnDef(label: 'R.R', width: 100),
  ];

  late final String _controllerTag;
  late final TEManagementController controller;
  late final ScrollController _verticalController;
  late final ScrollController _horizontalController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _controllerTag = widget.controllerTag ??
        'TE_MANAGEMENT_${widget.initialModelSerial}_${widget.initialModel}';
    controller = Get.put(
      TEManagementController(
        initialModelSerial: widget.initialModelSerial,
        initialModel: widget.initialModel,
      ),
      tag: _controllerTag,
    );
    _verticalController = ScrollController();
    _horizontalController = ScrollController();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    if (Get.isRegistered<TEManagementController>(tag: _controllerTag)) {
      Get.delete<TEManagementController>(tag: _controllerTag);
    }
    _verticalController.dispose();
    _horizontalController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final start = controller.startDate.value;
    final end = controller.endDate.value;

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: start, end: end),
      firstDate: DateTime(start.year - 1),
      lastDate: DateTime(end.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accentCyan,
              surface: _surfaceColor,
              background: _surfaceColor,
              onSurface: _textPrimary,
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final startDate = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
        7,
        30,
      );
      final endDate = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        19,
        30,
      );
      controller.setDateRange(startDate, endDate);
    }
  }

  Future<void> _openModelSelector() async {
    final available = controller.availableModelList;
    if (available.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Models are not available yet.')),
        );
      }
      return;
    }

    final initialSelection = controller.selectedModelList;
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final selected = LinkedHashSet<String>.from(initialSelection);
        String query = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final filtered = available
                .where((model) =>
                    model.toLowerCase().contains(query.toLowerCase()))
                .toList();
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: const BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border.fromBorderSide(BorderSide(color: _borderColor)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Select Models',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: _textPrimary),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        style: const TextStyle(color: _textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search models...',
                          hintStyle: TextStyle(color: _textMuted.withOpacity(.7)),
                          prefixIcon: const Icon(Icons.search, color: _textMuted),
                          filled: true,
                          fillColor: const Color(0xFF162741),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.transparent),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _accentCyan),
                          ),
                        ),
                        onChanged: (value) => setState(() => query = value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final model = filtered[index];
                          final isChecked = selected.contains(model);
                          return CheckboxListTile(
                            value: isChecked,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selected.add(model);
                                } else {
                                  selected.remove(model);
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: _accentCyan,
                            checkColor: Colors.black,
                            title: Text(
                              model,
                              style: const TextStyle(color: _textPrimary),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _textMuted),
                                foregroundColor: _textPrimary,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentCyan,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () =>
                                  Navigator.of(context).pop(selected.toList()),
                              child: Text('Apply (${selected.length})'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      controller.setSelectedModels(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final serial = controller.modelSerial.value;
      final groups = controller.filteredData;
      final quickText = controller.quickFilter.value;
      if (_searchController.text != quickText) {
        _searchController.value = TextEditingValue(
          text: quickText,
          selection: TextSelection.collapsed(offset: quickText.length),
        );
      }
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: _buildAppBar(context, serial),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
                _buildSelectedChips(),
                const SizedBox(height: 16),
                Expanded(child: _buildTableCard(groups)),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _handleBackNavigation() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    final rootNavigator = Get.key.currentState;
    if (rootNavigator?.canPop() ?? false) {
      rootNavigator!.pop();
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String serial) {
    final title = widget.title ?? '$serial TE Report';
    final range = controller.range;
    return AppBar(
      backgroundColor: _backgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
      leadingWidth: 48,
      titleSpacing: 0,
      centerTitle: false,
      shape: const Border(bottom: BorderSide(color: _borderColor)),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          onPressed: _handleBackNavigation,
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back, color: _textMuted),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            range,
            style: TextStyle(
              color: _textMuted.withOpacity(.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AppBarActionButton(
                label: 'FILTER',
                icon: Icons.tune,
                onTap: _openFilterPanel,
                backgroundColor: Colors.transparent,
                foregroundColor: _accentCyan,
                borderColor: _accentCyan.withOpacity(.7),
              ),
              const SizedBox(width: 10),
              _AppBarActionButton(
                label: 'QUERY',
                icon: Icons.search,
                onTap: () => controller.fetchData(force: true),
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: controller.updateQuickFilter,
      style: const TextStyle(color: _textPrimary),
      decoration: InputDecoration(
        hintText: 'Search model, group, or value...',
        hintStyle: TextStyle(color: _textMuted.withOpacity(.7)),
        prefixIcon: const Icon(Icons.search, color: _textMuted),
        filled: true,
        fillColor: const Color(0xFF162741),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _accentCyan.withOpacity(.7)),
        ),
      ),
    );
  }

  Future<void> _openFilterPanel() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filters',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: _FilterDrawer(
            controller: controller,
            onClose: () => Navigator.of(context).pop(),
            onPickDateRange: _pickDateRange,
            onOpenModelSelector: _openModelSelector,
            onApply: () {
              controller.fetchData(force: true);
              Navigator.of(context).pop();
            },
            onReset: () {
              controller.resetToTodayRange();
              controller.clearSelectedModels();
              if (widget.initialModelSerial.isNotEmpty) {
                controller.modelSerial.value = widget.initialModelSerial;
              }
              controller.updateQuickFilter('');
              _searchController.clear();
            },
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return SlideTransition(
          position: offset,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
    );
  }

  String _labelForRateType(RateType type) {
    switch (type) {
      case RateType.fpr:
        return 'F.P.R';
      case RateType.yr:
        return 'Y.R';
      case RateType.rr:
        return 'R.R';
    }
  }

  double _valueForRateType(TEReportRow row, RateType type) {
    switch (type) {
      case RateType.fpr:
        return row.fpr;
      case RateType.yr:
        return row.yr;
      case RateType.rr:
        return row.rr;
    }
  }

  Future<void> _showRateDetail(TEReportRow row, RateType type) async {
    final future = controller.fetchErrorDetail(row: row);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(.6),
      builder: (context) {
        return _RateDetailDialog(
          row: row,
          rateLabel: _labelForRateType(type),
          rateValue: _valueForRateType(row, type),
          detailFuture: future,
        );
      },
    );
  }

  Widget _buildSelectedChips() {
    final selected = controller.selectedModelList;
    if (selected.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final model in selected)
          Chip(
            backgroundColor: const Color(0xFF1E3A5F),
            label: Text(
              model,
              style: const TextStyle(color: _textPrimary),
            ),
            deleteIconColor: _textPrimary,
            onDeleted: () {
              final updated = controller.selectedModelList..remove(model);
              controller.setSelectedModels(updated);
            },
          ),
        ActionChip(
          backgroundColor: const Color(0xFF162741),
          label: const Text(
            'Clear all',
            style: TextStyle(color: _textMuted),
          ),
          onPressed: controller.clearSelectedModels,
        ),
      ],
    );
  }

  Widget _buildTableCard(List<TEReportGroup> groups) {
    if (controller.isLoading.value) {
      return const Center(child: EvaLoadingView(size: 220));
    }

    if (controller.error.isNotEmpty) {
      return Center(
        child: Text(
          controller.error.value,
          style: const TextStyle(color: _textPrimary),
        ),
      );
    }

    if (groups.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: _textMuted.withOpacity(.85)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: const [
                Icon(Icons.double_arrow, color: _accentCyan),
                SizedBox(width: 10),
                Text(
                  'Table Details',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderColor),
          Expanded(child: _buildTable(groups)),
        ],
      ),
    );
  }

  Widget _buildTable(List<TEReportGroup> groups) {
    return Scrollbar(
      controller: _verticalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalController,
        child: Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          notificationPredicate: (notification) => notification.depth == 1,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow(),
                for (var i = 0; i < groups.length; i++)
                  _buildGroupRow(groups[i], i),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        _buildHeaderCell('#', _indexWidth),
        _buildHeaderCell('MODEL NAME', _modelWidth,
            alignment: Alignment.centerLeft),
        for (final column in _columns)
          _buildHeaderCell(column.label, column.width,
              alignment: column.alignment),
      ],
    );
  }

  Widget _buildTooltipText(
    String text,
    TextStyle style, {
    int maxLines = 1,
    TextAlign? textAlign,
  }) {
    final widget = Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
    );

    if (text.trim().isEmpty) {
      return widget;
    }

    return Tooltip(
      message: text,
      waitDuration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.85),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white),
      child: widget,
    );
  }

  Widget _buildHeaderCell(String label, double width,
      {Alignment alignment = Alignment.center}) {
    return Container(
      width: width,
      height: _rowHeight,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: _headerColor,
        border: Border(
          right: BorderSide(color: _borderColor),
          bottom: BorderSide(color: _borderColor),
        ),
      ),
      child: _buildTooltipText(
        label,
        const TextStyle(
          color: _textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
  Widget _buildGroupRow(TEReportGroup group, int index) {
    final rows = group.rows;
    final height = _rowHeight * rows.length;
    final color = index.isEven ? _rowColor : _rowAltColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSpannedCell('${index + 1}', _indexWidth, height,
            alignment: Alignment.center, background: color),
        _buildSpannedCell(group.modelName, _modelWidth, height,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            background: color,
            maxLines: 3),
        for (var col = 0; col < _columns.length; col++)
          _buildColumnCells(rows, col, color),
      ],
    );
  }

  Widget _buildSpannedCell(
    String text,
    double width,
    double height, {
    Alignment alignment = Alignment.center,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 8),
    Color background = _rowColor,
    int maxLines = 2,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: _borderColor),
      ),
      child: _buildTooltipText(
        text,
        const TextStyle(
          color: _textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildColumnCells(
      List<TEReportRow> rows, int columnIndex, Color rowColor) {
    final column = _columns[columnIndex];
    return SizedBox(
      width: column.width,
      child: Column(
        children: [
          for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
            _buildDataCell(rows[rowIndex], column, columnIndex, rowColor),
        ],
      ),
    );
  }

  Widget _buildDataCell(
    TEReportRow row,
    _ColumnDef column,
    int columnIndex,
    Color baseColor,
  ) {
    final rateType = _rateTypeForColumn(columnIndex);
    final rateValue = _rateValueForColumn(row, columnIndex);
    final background = _resolveBackground(baseColor, rateType, rateValue);
    final textColor = _resolveTextColor(rateType, rateValue);
    final text = _formatValue(row, columnIndex);

    final child = Container(
      height: _rowHeight,
      alignment: column.alignment,
      padding: column.padding,
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: _borderColor),
      ),
      child: _buildTooltipText(
        text,
        TextStyle(
          color: textColor,
          fontWeight: rateType == null ? FontWeight.w500 : FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );

    if (rateType != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showRateDetail(row, rateType),
          child: child,
        ),
      );
    }

    return child;
  }

  RateType? _rateTypeForColumn(int columnIndex) {
    switch (columnIndex) {
      case 9:
        return RateType.fpr;
      case 10:
        return RateType.yr;
      case 11:
        return RateType.rr;
      default:
        return null;
    }
  }

  double? _rateValueForColumn(TEReportRow row, int columnIndex) {
    switch (columnIndex) {
      case 9:
        return row.fpr;
      case 10:
        return row.yr;
      case 11:
        return row.rr;
      default:
        return null;
    }
  }

  Color _resolveBackground(Color base, RateType? type, double? value) {
    if (type == null || value == null) {
      return base;
    }
    final highlight = _rateBaseColor(type, value);
    if (highlight == null) {
      return base;
    }
    return Color.alphaBlend(highlight.withOpacity(.18), base);
  }

  Color _resolveTextColor(RateType? type, double? value) {
    if (type == null || value == null) {
      return _textPrimary;
    }
    final highlight = _rateBaseColor(type, value);
    return highlight ?? _textPrimary;
  }

  Color? _rateBaseColor(RateType type, double value) {
    switch (type) {
      case RateType.fpr:
      case RateType.yr:
        if (value <= 90) return const Color(0xFFE11D48);
        if (value <= 97) return const Color(0xFFF59E0B);
        if (value > 97) return const Color(0xFF22C55E);
        return null;
      case RateType.rr:
        if (value >= 5) return const Color(0xFFE11D48);
        if (value > 2 && value < 5) return const Color(0xFFF59E0B);
        if (value <= 2) return const Color(0xFF22C55E);
        return null;
    }
  }

  String _formatValue(TEReportRow row, int columnIndex) {
    switch (columnIndex) {
      case 0:
        return row.groupName;
      case 1:
        return row.wipQty.toString();
      case 2:
        return row.input.toString();
      case 3:
        return row.firstFail.toString();
      case 4:
        return row.repairQty.toString();
      case 5:
        return row.firstPass.toString();
      case 6:
        return row.repairPass.toString();
      case 7:
        return row.pass.toString();
      case 8:
        return row.totalPass.toString();
      case 9:
        return '${row.fpr.toStringAsFixed(2)}%';
      case 10:
        return '${row.yr.toStringAsFixed(2)}%';
      case 11:
        return '${row.rr.toStringAsFixed(2)}%';
      default:
        return '';
    }
  }

}

class _AppBarActionButton extends StatelessWidget {
  const _AppBarActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 38),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: borderColor != null
              ? BorderSide(color: borderColor!)
              : BorderSide.none,
        ),
      ),
      icon: Icon(icon, size: 18, color: foregroundColor),
      label: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _FilterDrawer extends StatelessWidget {
  const _FilterDrawer({
    required this.controller,
    required this.onClose,
    required this.onPickDateRange,
    required this.onOpenModelSelector,
    required this.onApply,
    required this.onReset,
  });

  final TEManagementController controller;
  final VoidCallback onClose;
  final Future<void> Function() onPickDateRange;
  final Future<void> Function() onOpenModelSelector;
  final VoidCallback onApply;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.of(context).size.width * 0.9, 420.0);
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 24,
              offset: Offset(-8, 0),
            ),
          ],
          border: Border(
            left: BorderSide(color: _borderColor),
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            final selectedCount = controller.selectedModelList.length;
            final range = controller.range;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                  child: Row(
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close, color: _textPrimary),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: _borderColor),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ToolbarField(
                          label: 'Date range',
                          child: _SelectionButton(
                            label: range,
                            icon: Icons.calendar_today_rounded,
                            onTap: () async {
                              await onPickDateRange();
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        _ToolbarField(
                          label: 'Models',
                          child: _SelectionButton(
                            label: selectedCount > 0
                                ? 'Selected: $selectedCount'
                                : 'Select Models',
                            icon: Icons.list_alt,
                            onTap: () async {
                              await onOpenModelSelector();
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (selectedCount > 0)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final model in controller.selectedModelList)
                                Chip(
                                  backgroundColor: const Color(0xFF1E3A5F),
                                  label: Text(
                                    model,
                                    style: const TextStyle(color: _textPrimary),
                                  ),
                                  deleteIconColor: _textPrimary,
                                  onDeleted: () {
                                    final updated = controller.selectedModelList
                                      ..remove(model);
                                    controller.setSelectedModels(updated);
                                  },
                                ),
                              ActionChip(
                                backgroundColor: const Color(0xFF162741),
                                label: const Text(
                                  'Clear all',
                                  style: TextStyle(color: _textMuted),
                                ),
                                onPressed: controller.clearSelectedModels,
                              ),
                            ],
                        ),
                        const SizedBox(height: 24),
                        TextButton.icon(
                          onPressed: onReset,
                          icon: const Icon(Icons.refresh, color: _accentCyan),
                          label: const Text(
                            'Reset to today range',
                            style: TextStyle(color: _accentCyan),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textPrimary,
                            side: const BorderSide(color: _borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: onClose,
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentCyan,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: onApply,
                          icon: const Icon(Icons.check_circle),
                          label: const Text(
                            'Apply filters',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _ToolbarField extends StatelessWidget {
  const _ToolbarField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _SelectionButton extends StatelessWidget {
  const _SelectionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF162741),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: _accentCyan),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RateDetailDialog extends StatefulWidget {
  const _RateDetailDialog({
    required this.row,
    required this.rateLabel,
    required this.rateValue,
    required this.detailFuture,
  });

  final TEReportRow row;
  final String rateLabel;
  final double rateValue;
  final Future<TEErrorDetail?> detailFuture;

  @override
  State<_RateDetailDialog> createState() => _RateDetailDialogState();
}

class _RateDetailDialogState extends State<_RateDetailDialog> {
  TEErrorDetailCluster? _activeErrorCluster;
  TEErrorDetailCluster? _activeMachineCluster;

  late final TooltipBehavior _errorTooltip;
  late final TooltipBehavior _machineTooltip;

  @override
  void initState() {
    super.initState();
    _errorTooltip = _buildTooltip();
    _machineTooltip = _buildTooltip();
  }

  TooltipBehavior _buildTooltip() {
    return TooltipBehavior(
      enable: true,
      color: const Color(0xFF0F172A),
      borderColor: Colors.white.withOpacity(.12),
      borderWidth: 1,
      textStyle: const TextStyle(
        color: _textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _drillErrorCluster(TEErrorDetailCluster cluster) {
    HapticFeedback.selectionClick();
    setState(() {
      _activeErrorCluster = cluster;
    });
  }

  void _drillMachineCluster(TEErrorDetailCluster cluster) {
    HapticFeedback.selectionClick();
    setState(() {
      _activeMachineCluster = cluster;
    });
  }

  void _resetErrorCluster() {
    HapticFeedback.lightImpact();
    setState(() {
      _activeErrorCluster = null;
    });
  }

  void _resetMachineCluster() {
    HapticFeedback.lightImpact();
    setState(() {
      _activeMachineCluster = null;
    });
  }

  void _showNoBreakdownToast() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.clearSnackBars();
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('No drill-down data available for this column.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180, maxHeight: 660),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<TEErrorDetail?>(
            future: widget.detailFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: EvaLoadingView(size: 160));
              }
              if (snapshot.hasError) {
                return _RateDetailMessage(
                  icon: Icons.error_outline,
                  message: 'Failed to load error detail data.',
                  onClose: () => Navigator.of(context).pop(),
                );
              }
              final detail = snapshot.data;
              if (detail == null || !detail.hasData) {
                return _RateDetailMessage(
                  icon: Icons.info_outline,
                  message: 'No detail data available for this selection.',
                  onClose: () => Navigator.of(context).pop(),
                );
              }

              final errorState = _buildErrorChartState(detail);
              final machineState = _buildMachineChartState(detail);

              final machineChart = detail.byMachine.isEmpty
                  ? _EmptyChartCard(
                      title: 'Order By Tester Name',
                      message: 'No tester data available for this selection.',
                    )
                  : _RateChartCard(
                      title: 'Order By Tester Name',
                      state: machineState,
                      tooltip: _machineTooltip,
                      onPointTap: (cluster) {
                        if (cluster == null) {
                          return;
                        }
                        if (!cluster.hasBreakdown) {
                          _showNoBreakdownToast();
                          return;
                        }
                        _drillMachineCluster(cluster);
                      },
                      onBack: _resetMachineCluster,
                    );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 18),
                  _RateSummaryGrid(
                    row: widget.row,
                    rateLabel: widget.rateLabel,
                    rateValue: widget.rateValue,
                  ),
                  const SizedBox(height: 22),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isVertical = constraints.maxWidth < 960;
                        final spacing = isVertical
                            ? const SizedBox(height: 18)
                            : const SizedBox(width: 18);
                        final children = <Widget>[
                          Expanded(
                            child: _RateChartCard(
                              title: 'Order By Error Code',
                              state: errorState,
                              tooltip: _errorTooltip,
                              onPointTap: (cluster) {
                                if (cluster == null) {
                                  return;
                                }
                                if (!cluster.hasBreakdown) {
                                  _showNoBreakdownToast();
                                  return;
                                }
                                _drillErrorCluster(cluster);
                              },
                              onBack: _resetErrorCluster,
                            ),
                          ),
                          spacing,
                          Expanded(child: machineChart),
                        ];
                        if (isVertical) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: children,
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: children,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: _accentCyan,
                        backgroundColor: const Color(0xFF0F1F36),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: _borderColor),
                        ),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Information about Group Name: ${widget.row.groupName} with Model Name: ${widget.row.modelName}',
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.rateLabel} ${widget.rateValue.toStringAsFixed(2)}%',
                style: const TextStyle(
                  color: _accentCyan,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: _textPrimary),
        ),
      ],
    );
  }

  _ChartState _buildErrorChartState(TEErrorDetail detail) {
    if (_activeErrorCluster == null) {
      final points = detail.byErrorCode
          .map(
            (cluster) => _ChartPoint(
              label: cluster.label.isEmpty ? '(N/A)' : cluster.label,
              value: cluster.totalFail,
              cluster: cluster,
            ),
          )
          .toList();
      final total = points.fold<int>(0, (sum, item) => sum + item.value);
      return _ChartState(
        points: points,
        subtitle: 'Tap a column to drill down by tester • Total $total',
        total: total,
        isDetail: false,
      );
    }

    final cluster = _activeErrorCluster!;
    final points = cluster.breakdowns
        .map(
          (breakdown) => _ChartPoint(
            label: breakdown.label.isEmpty ? '(N/A)' : breakdown.label,
            value: breakdown.failQty,
          ),
        )
        .toList();
    final total = points.fold<int>(0, (sum, item) => sum + item.value);
    final label = cluster.label.isEmpty ? '(N/A)' : cluster.label;
    return _ChartState(
      points: points,
      subtitle: 'Error $label • by Tester • Total $total',
      total: total,
      isDetail: true,
      cluster: cluster,
    );
  }

  _ChartState _buildMachineChartState(TEErrorDetail detail) {
    if (detail.byMachine.isEmpty) {
      return _ChartState(
        points: const <_ChartPoint>[],
        subtitle: 'No tester data available for this selection.',
        total: 0,
        isDetail: false,
      );
    }

    if (_activeMachineCluster == null) {
      final points = detail.byMachine
          .map(
            (cluster) => _ChartPoint(
              label: cluster.label.isEmpty ? '(N/A)' : cluster.label,
              value: cluster.totalFail,
              cluster: cluster,
            ),
          )
          .toList();
      final total = points.fold<int>(0, (sum, item) => sum + item.value);
      return _ChartState(
        points: points,
        subtitle: 'Tap a column to drill down by error code • Total $total',
        total: total,
        isDetail: false,
      );
    }

    final cluster = _activeMachineCluster!;
    final points = cluster.breakdowns
        .map(
          (breakdown) => _ChartPoint(
            label: breakdown.label.isEmpty ? '(N/A)' : breakdown.label,
            value: breakdown.failQty,
          ),
        )
        .toList();
    final total = points.fold<int>(0, (sum, item) => sum + item.value);
    final label = cluster.label.isEmpty ? '(N/A)' : cluster.label;
    return _ChartState(
      points: points,
      subtitle: 'Machine $label • by Error Code • Total $total',
      total: total,
      isDetail: true,
      cluster: cluster,
    );
  }
}

class _RateSummaryGrid extends StatelessWidget {
  const _RateSummaryGrid({
    required this.row,
    required this.rateLabel,
    required this.rateValue,
  });

  final TEReportRow row;
  final String rateLabel;
  final double rateValue;

  @override
  Widget build(BuildContext context) {
    final metrics = <_MetricData>[
      _MetricData('WIP QTY', row.wipQty.toString()),
      _MetricData('INPUT', row.input.toString()),
      _MetricData('FIRST FAIL', row.firstFail.toString()),
      _MetricData('REPAIR QTY', row.repairQty.toString()),
      _MetricData('FIRST PASS', row.firstPass.toString()),
      _MetricData('REPAIR PASS', row.repairPass.toString()),
      _MetricData('PASS', row.pass.toString()),
      _MetricData('TOTAL PASS', row.totalPass.toString()),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _HighlightMetric(
          label: rateLabel,
          value: '${rateValue.toStringAsFixed(2)}%',
        ),
        for (final metric in metrics)
          _SummaryMetric(
            label: metric.label,
            value: metric.value,
          ),
      ],
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value);

  final String label;
  final String value;
}

class _HighlightMetric extends StatelessWidget {
  const _HighlightMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF10213A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RateChartCard extends StatelessWidget {
  const _RateChartCard({
    required this.title,
    required this.state,
    required this.tooltip,
    required this.onPointTap,
    required this.onBack,
  });

  final String title;
  final _ChartState state;
  final TooltipBehavior tooltip;
  final void Function(TEErrorDetailCluster?) onPointTap;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1C32),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.subtitle,
                      style: TextStyle(
                        color: _textMuted.withOpacity(.9),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.isDetail) ...[
                IconButton(
                  onPressed: onBack,
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: _accentCyan,
                ),
                const SizedBox(width: 12),
              ],
              _TotalBadge(total: state.total),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: state.points.isEmpty
                ? _ChartEmptyMessage(
                    message: state.isDetail
                        ? 'No drill-down data for this selection.'
                        : 'No data available.',
                  )
                : SfCartesianChart(
                    plotAreaBackgroundColor: Colors.transparent,
                    backgroundColor: Colors.transparent,
                    tooltipBehavior: tooltip,
                    primaryXAxis: CategoryAxis(
                      labelStyle: const TextStyle(
                        color: _textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      labelRotation: state.points.length > 4 ? -35 : 0,
                      majorGridLines: const MajorGridLines(width: 0),
                      axisLine: const AxisLine(color: Colors.transparent),
                      majorTickLines: const MajorTickLines(color: Colors.transparent),
                    ),
                    primaryYAxis: NumericAxis(
                      labelStyle: const TextStyle(
                        color: _textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      axisLine: const AxisLine(color: Colors.transparent),
                      majorGridLines: MajorGridLines(
                        color: Colors.white.withOpacity(.08),
                      ),
                      majorTickLines: const MajorTickLines(color: Colors.transparent),
                      minimum: 0,
                    ),
                    legend: const Legend(isVisible: false),
                    plotAreaBorderWidth: 0,
                    series: <CartesianSeries<_ChartPoint, String>>[
                      ColumnSeries<_ChartPoint, String>(
                        dataSource: state.points,
                        xValueMapper: (point, _) => point.label,
                        yValueMapper: (point, _) => point.value,
                        borderRadius: BorderRadius.circular(10),
                        width: 0.6,
                        spacing: 0.1,
                        onPointTap: (details) {
                          if (state.isDetail) {
                            return;
                          }
                          final index = details.pointIndex;
                          if (index == null ||
                              index < 0 ||
                              index >= state.points.length) {
                            return;
                          }
                          onPointTap(state.points[index].cluster);
                        },
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: true,
                          textStyle: TextStyle(
                            color: _textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        selectionBehavior: SelectionBehavior(
                          enable: true,
                          unselectedOpacity: 0.25,
                          selectedOpacity: 1,
                        ),
                        onCreateShader: (details) {
                          return ui.Gradient.linear(
                            details.rect.topCenter,
                            details.rect.bottomCenter,
                            const [
                              Color(0xFF22D3EE),
                              Color(0xFF38BDF8),
                              Color(0xFF0EA5E9),
                            ],
                            const [0.0, 0.55, 1.0],
                          );
                        },
                      ),
                      if (state.points.length > 1)
                        SplineSeries<_ChartPoint, String>(
                          dataSource: state.points,
                          xValueMapper: (point, _) => point.label,
                          yValueMapper: (point, _) => point.value,
                          color: const Color(0xFF60A5FA),
                          width: 2,
                          markerSettings: const MarkerSettings(
                            isVisible: true,
                            color: Color(0xFF0F172A),
                            borderWidth: 2,
                            borderColor: Color(0xFF60A5FA),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChartCard extends StatelessWidget {
  const _EmptyChartCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1C32),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textMuted.withOpacity(.85),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartEmptyMessage extends StatelessWidget {
  const _ChartEmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: _textMuted.withOpacity(.85)),
      ),
    );
  }
}

class _RateDetailMessage extends StatelessWidget {
  const _RateDetailMessage({
    required this.icon,
    required this.message,
    required this.onClose,
  });

  final IconData icon;
  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _accentCyan, size: 56),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: onClose,
            child: const Text(
              'Close',
              style: TextStyle(
                color: _accentCyan,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalBadge extends StatelessWidget {
  const _TotalBadge({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF162741),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total',
            style: TextStyle(
              color: _textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$total',
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartState {
  const _ChartState({
    required this.points,
    required this.subtitle,
    required this.total,
    required this.isDetail,
    this.cluster,
  });

  final List<_ChartPoint> points;
  final String subtitle;
  final int total;
  final bool isDetail;
  final TEErrorDetailCluster? cluster;
}

class _ChartPoint {
  const _ChartPoint({
    required this.label,
    required this.value,
    this.cluster,
  });

  final String label;
  final int value;
  final TEErrorDetailCluster? cluster;
}


class _ColumnDef {
  const _ColumnDef({
    required this.label,
    required this.width,
    this.alignment = Alignment.center,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
  });

  final String label;
  final double width;
  final Alignment alignment;
  final EdgeInsets padding;
}

enum RateType { fpr, yr, rr }
