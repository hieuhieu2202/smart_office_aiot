import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:smart_factory/config/global_color.dart';
import 'package:smart_factory/config/global_text_style.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../model/AppModel.dart';
import '../../../../widget/full_screen_image.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class ProjectDetailScreen extends StatelessWidget {
  final AppProject project;
  static const String imageUrl =
      "https://10.220.130.117/CCDMachine/AOIVI/GetImage?path=%2FCCDMachine%2FAVI%2FF16%2FF163F-AVI-03%2F920-9K36F-B4MV-GD0%2FMT2519600GL9%2FSequence1%2F11.Jpeg";

  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    HttpOverrides.global = MyHttpOverrides();
    final bool isDark = Get.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? GlobalColors.bodyDarkBg
          : GlobalColors.bodyLightBg,
      appBar: AppBar(
        title: Text(
          project.name,
          style: GlobalTextStyles.bodyLarge(isDark: isDark).copyWith(
            color: isDark
                ? GlobalColors.appBarDarkText
                : GlobalColors.appBarLightText,
          ),
        ),
        backgroundColor: isDark
            ? GlobalColors.appBarDarkBg
            : GlobalColors.appBarLightBg,
        iconTheme: IconThemeData(
          color: isDark
              ? GlobalColors.appBarDarkText
              : GlobalColors.appBarLightText,
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _buildCalendar(context, isDark),

              Container(
                height: 400,
                margin: const EdgeInsets.only(top: 20),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    PhotoView(
                      imageProvider: CachedNetworkImageProvider(imageUrl),
                      loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Text(
                          'Không thể tải hình ảnh',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.white, size: 30),
                        onPressed: () {
                          Get.to(() => FullScreenImage(imageUrl: imageUrl), transition: Transition.fade);
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.5),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? GlobalColors.cardDarkBg : GlobalColors.cardLightBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: DateTime.now(),
        calendarFormat: CalendarFormat.month,
        headerStyle: HeaderStyle(
          titleTextStyle: GlobalTextStyles.bodyLarge(isDark: isDark).copyWith(
            color: isDark ? GlobalColors.darkPrimaryText : GlobalColors.lightPrimaryText,
            fontWeight: FontWeight.bold,
          ),
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon: Icon(Icons.chevron_left,
              color: isDark ? GlobalColors.primaryButtonDark : GlobalColors.primaryButtonLight),
          rightChevronIcon: Icon(Icons.chevron_right,
              color: isDark ? GlobalColors.primaryButtonDark : GlobalColors.primaryButtonLight),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: GlobalTextStyles.bodyMedium(isDark: isDark),
          weekendTextStyle: GlobalTextStyles.bodyMedium(isDark: isDark).copyWith(color: Colors.redAccent),
          todayDecoration: BoxDecoration(
            color: isDark
                ? GlobalColors.primaryButtonDark.withOpacity(0.3)
                : GlobalColors.primaryButtonLight.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: isDark
                ? GlobalColors.primaryButtonDark
                : GlobalColors.primaryButtonLight,
            shape: BoxShape.circle,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GlobalTextStyles.bodySmall(isDark: isDark),
          weekendStyle: GlobalTextStyles.bodySmall(isDark: isDark).copyWith(color: Colors.redAccent),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          Get.snackbar(
            'Ngày được chọn',
            DateFormat('dd/MM/yyyy').format(selectedDay),
            snackPosition: SnackPosition.TOP,
            backgroundColor: isDark
                ? GlobalColors.primaryButtonDark
                : GlobalColors.primaryButtonLight,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        },
      ),
    );
  }
}
