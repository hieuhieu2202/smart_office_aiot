import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../config/global_color.dart';
import '../../../../service/aoivi_dashboard_api.dart';
import '../../../../widget/animation/loading/eva_loading_view.dart';
import '../../../../widget/auto/avi/avi_dashboard_detail_card.dart';
import '../../../../widget/auto/avi/avi_dashboard_detail_empty.dart';

class PTHDashboardDetailScreen extends StatefulWidget {
  final String status;
  final String groupName;
  final String machineName;
  final String modelName;
  final String rangeDateTime;

  const PTHDashboardDetailScreen({
    Key? key,
    required this.status,
    required this.groupName,
    required this.machineName,
    required this.modelName,
    required this.rangeDateTime,
  }) : super(key: key);

  @override
  State<PTHDashboardDetailScreen> createState() => _PTHDashboardDetailScreenState();
}

class _PTHDashboardDetailScreenState extends State<PTHDashboardDetailScreen> {
  RxList<Map<String, dynamic>> _detailList = <Map<String, dynamic>>[].obs;
  RxBool _isLoading = false.obs;
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchText = "".obs;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    _isLoading.value = true;
    try {
      final data = await PTHDashboardApi.getMonitoringDetailByStatus(
        status: widget.status,
        groupName: widget.groupName,
        machineName: widget.machineName,
        modelName: widget.modelName,
        rangeDateTime: widget.rangeDateTime,
      );
      _detailList.value = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      Get.snackbar("Lỗi", e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? GlobalColors.bodyDarkBg : GlobalColors.bodyLightBg;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Chi tiết ${widget.status.toUpperCase()}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? GlobalColors.appBarDarkText : GlobalColors.appBarLightText,
          ),
        ),
        backgroundColor: isDark ? GlobalColors.appBarDarkBg : GlobalColors.appBarLightBg,
        iconTheme: IconThemeData(
            color: isDark ? GlobalColors.appBarDarkText : GlobalColors.appBarLightText
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Tải lại",
            onPressed: _fetchDetail,
          ),
        ],
        elevation: 0.5,
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const EvaLoadingView();
        }
        // Search/filter logic
        final filteredList = _detailList.where((item) {
          final query = _searchText.value.toLowerCase();
          if (query.isEmpty) return true;
          return [
            item['serialNumber'],
            item['modelName'],
            item['employeeID'],
            item['inspectionTime'] != null
                ? DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.tryParse(item['inspectionTime']) ?? DateTime(2000))
                : ''
          ].join(" ").toLowerCase().contains(query);
        }).toList();

        return Column(
          children: [
            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Tìm SN, Model, Nhân viên, Thời gian...',
                  prefixIcon: Icon(Icons.search, color: GlobalColors.iconLight),
                  filled: true,
                  fillColor: isDark
                      ? GlobalColors.inputDarkFill
                      : GlobalColors.inputLightFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  suffixIcon: Obx(() => _searchText.value.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, size: 20, color: Colors.grey[500]),
                    onPressed: () {
                      _searchController.clear();
                      _searchText.value = '';
                    },
                  )
                      : const SizedBox.shrink()
                  ),
                ),
                onChanged: (text) => _searchText.value = text.trim(),
              ),
            ),
            Expanded(
              child: filteredList.isEmpty
                  ? PTHDashboardDetailEmpty(isDark: isDark)
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                itemCount: filteredList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final item = filteredList[idx];
                  return PTHDashboardDetailCard(item: item);
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
