import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../model/te_management/te_report_models.dart';
import '../../../../widget/animation/loading/eva_loading_view.dart';
import '../../controller/te_management_controller.dart';
import '../../../../service/te_management_api.dart';

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
    _ColumnDef(label: 'S.P.R', width: 110),
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

  Future<void> _exportCsv(List<TEReportGroup> groups) async {
    if (groups.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export.')),
        );
      }
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln([
      '#',
      'MODEL NAME',
      'GROUP NAME',
      'WIP QTY',
      'INPUT',
      'FIRST FAIL',
      'REPAIR QTY',
      'FIRST PASS',
      'REPAIR PASS',
      'PASS',
      'TOTAL PASS',
      'F.P.R',
      'S.P.R',
      'Y.R',
      'R.R',
    ].join(','));

    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      for (var rowIndex = 0; rowIndex < group.rows.length; rowIndex++) {
        final row = group.rows[rowIndex];
        final cells = [
          if (rowIndex == 0) '${i + 1}' else '',
          if (rowIndex == 0) group.modelName else '',
          row.groupName,
          row.wipQty.toString(),
          row.input.toString(),
          row.firstFail.toString(),
          row.repairQty.toString(),
          row.firstPass.toString(),
          row.repairPass.toString(),
          row.pass.toString(),
          row.totalPass.toString(),
          '${row.fpr.toStringAsFixed(2)}%',
          '${row.spr.toStringAsFixed(2)}%',
          '${row.yr.toStringAsFixed(2)}%',
          '${row.rr.toStringAsFixed(2)}%',
        ];
        buffer.writeln(cells.map(_escapeCsv).join(','));
      }
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV copied to clipboard.')),
      );
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
        appBar: _buildAppBar(serial),
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

  PreferredSizeWidget _buildAppBar(String serial) {
    final title = widget.title ?? '$serial TE Report';
    final range = controller.range;
    return PreferredSize(
      preferredSize: const Size.fromHeight(68),
      child: Container(
        decoration: const BoxDecoration(
          color: _backgroundColor,
          border: Border(bottom: BorderSide(color: _borderColor)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                ),
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
                  label: 'EXPORT',
                  icon: Icons.file_download_outlined,
                  onTap: () => _exportCsv(controller.filteredData),
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
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
        ),
      ),
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
            initialModelSerial: widget.initialModelSerial,
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
      case RateType.spr:
        return 'S.P.R';
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
      case RateType.spr:
        return row.spr;
      case RateType.yr:
        return row.yr;
      case RateType.rr:
        return row.rr;
    }
  }

  Future<void> _showRateDetail(TEReportRow row, RateType type) async {
    final future = TEManagementApi.fetchErrorDetail(
      modelSerial: controller.modelSerial.value,
      rangeDateTime: controller.range,
      model: row.modelName,
      group: row.groupName,
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _RateDetailSheet(
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
      child: Text(
        label,
        style: const TextStyle(
          color: _textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
      child: Text(
        text,
        style: const TextStyle(
          color: _textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
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
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: rateType == null ? FontWeight.w500 : FontWeight.w700,
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
        return RateType.spr;
      case 11:
        return RateType.yr;
      case 12:
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
        return row.spr;
      case 11:
        return row.yr;
      case 12:
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
      case RateType.spr:
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
        return '${row.spr.toStringAsFixed(2)}%';
      case 11:
        return '${row.yr.toStringAsFixed(2)}%';
      case 12:
        return '${row.rr.toStringAsFixed(2)}%';
      default:
        return '';
    }
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('\n') || value.contains('"')) {
      return '"' + value.replaceAll('"', '""') + '"';
    }
    return value;
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
    required this.initialModelSerial,
    required this.onClose,
    required this.onPickDateRange,
    required this.onOpenModelSelector,
    required this.onApply,
    required this.onReset,
  });

  final TEManagementController controller;
  final String initialModelSerial;
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
            final serialOptions = <String>{
              'ADAPTER',
              'SWITCH',
              controller.modelSerial.value,
              if (initialModelSerial.isNotEmpty) initialModelSerial,
            }.where((element) => element.isNotEmpty).toList();

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
                        if (selectedCount > 0) const SizedBox(height: 24),
                        _ToolbarField(
                          label: 'Model serial',
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF162741),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _borderColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: controller.modelSerial.value,
                                dropdownColor: _surfaceColor,
                                iconEnabledColor: _textPrimary,
                                style: const TextStyle(color: _textPrimary),
                                items: serialOptions
                                    .map((item) => DropdownMenuItem(
                                          value: item,
                                          child: Text(item),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.modelSerial.value = value;
                                  }
                                },
                              ),
                            ),
                          ),
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

class _RateDetailSheet extends StatelessWidget {
  const _RateDetailSheet({
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
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final metrics = [
      _MetricEntry('WIP QTY', row.wipQty.toString()),
      _MetricEntry('INPUT', row.input.toString()),
      _MetricEntry('FIRST FAIL', row.firstFail.toString()),
      _MetricEntry('REPAIR QTY', row.repairQty.toString()),
      _MetricEntry('FIRST PASS', row.firstPass.toString()),
      _MetricEntry('REPAIR PASS', row.repairPass.toString()),
      _MetricEntry('PASS', row.pass.toString()),
      _MetricEntry('TOTAL PASS', row.totalPass.toString()),
    ];

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Model ${row.modelName}',
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Group ${row.groupName}',
              style: TextStyle(
                color: _textMuted.withOpacity(.85),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF10213A),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rateLabel,
                    style: const TextStyle(
                      color: _textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${rateValue.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      color: _accentCyan,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final metric in metrics)
                  _MetricPill(label: metric.label, value: metric.value),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<TEErrorDetail?>(
                future: detailFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _accentCyan),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load error detail\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _textMuted),
                      ),
                    );
                  }
                  final detail = snapshot.data;
                  if (detail == null || !detail.hasData) {
                    return Center(
                      child: Text(
                        'No additional error detail available for this record.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _textMuted),
                      ),
                    );
                  }
                  return ListView(
                    children: [
                      if (detail.byErrorCode.isNotEmpty)
                        _RateBreakdownSection(
                          title: 'Order By Error Code',
                          clusters: detail.byErrorCode,
                        ),
                      if (detail.byMachine.isNotEmpty)
                        _RateBreakdownSection(
                          title: 'Order By Tester Name',
                          clusters: detail.byMachine,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RateBreakdownSection extends StatelessWidget {
  const _RateBreakdownSection({
    required this.title,
    required this.clusters,
  });

  final String title;
  final List<TEErrorDetailCluster> clusters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (clusters.isEmpty)
            Text(
              'No data available.',
              style: TextStyle(color: _textMuted.withOpacity(.85)),
            ),
          for (final cluster in clusters)
            _RateBreakdownCard(cluster: cluster),
        ],
      ),
    );
  }
}

class _RateBreakdownCard extends StatelessWidget {
  const _RateBreakdownCard({required this.cluster});

  final TEErrorDetailCluster cluster;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1A2B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cluster.label.isEmpty ? '(N/A)' : cluster.label,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Fail Qty: ${cluster.totalFail}',
            style: const TextStyle(
              color: _accentCyan,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (cluster.hasBreakdown) ...[
            const SizedBox(height: 12),
            Column(
              children: [
                for (final breakdown in cluster.breakdowns)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            breakdown.label,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          '${breakdown.failQty}',
                          style: const TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'No drill-down data.',
              style: TextStyle(color: _textMuted.withOpacity(.8)),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF162741),
        borderRadius: BorderRadius.circular(12),
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

class _MetricEntry {
  const _MetricEntry(this.label, this.value);

  final String label;
  final String value;
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

enum RateType { fpr, spr, yr, rr }
