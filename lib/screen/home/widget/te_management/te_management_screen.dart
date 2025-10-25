import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

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
    _ColumnDef(label: 'S.P.R', width: 110),
    _ColumnDef(label: 'Y.R', width: 110),
    _ColumnDef(label: 'R.R', width: 100),
  ];

  late final String _controllerTag;
  late final TEManagementController controller;
  late final ScrollController _verticalController;
  late final ScrollController _horizontalController;

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
  }

  @override
  void dispose() {
    if (Get.isRegistered<TEManagementController>(tag: _controllerTag)) {
      Get.delete<TEManagementController>(tag: _controllerTag);
    }
    _verticalController.dispose();
    _horizontalController.dispose();
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
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(widget.title ?? '$serial TE Report'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildToolbar(),
                const SizedBox(height: 18),
                _buildSelectedChips(),
                const SizedBox(height: 18),
                Expanded(child: _buildTableCard(groups)),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildToolbar() {
    final selectedCount = controller.selectedModelList.length;
    final range = controller.range;
    final serialOptions = <String>{
      'ADAPTER',
      'SWITCH',
      controller.modelSerial.value,
    }.where((element) => element.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _ToolbarField(
            label: 'Date',
            child: _SelectionButton(
              label: range,
              icon: Icons.calendar_today_rounded,
              onTap: _pickDateRange,
            ),
          ),
          _ToolbarField(
            label: 'Models',
            child: _SelectionButton(
              label:
                  selectedCount > 0 ? 'Selected: $selectedCount' : 'Select Models',
              icon: Icons.list_alt,
              onTap: _openModelSelector,
            ),
          ),
          _ToolbarField(
            label: 'Model Serial',
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
                      .map((item) => DropdownMenuItem(value: item, child: Text(item)))
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
          SizedBox(
            width: 240,
            child: _ToolbarField(
              label: 'Search',
              child: TextField(
                style: const TextStyle(color: _textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search model, group, value...',
                  hintStyle: TextStyle(color: _textMuted.withOpacity(.7)),
                  prefixIcon: const Icon(Icons.search, color: _textMuted),
                  filled: true,
                  fillColor: const Color(0xFF162741),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: controller.updateQuickFilter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _exportCsv(controller.filteredData),
                  icon: const Icon(Icons.file_download_outlined, color: Colors.white),
                  label: const Text(
                    'EXPORT EXCEL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => controller.fetchData(force: true),
                  icon: const Icon(Icons.search, color: Colors.white),
                  label: const Text(
                    'QUERY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

    return Container(
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
