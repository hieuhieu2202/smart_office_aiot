import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ResponsiveHelper {

  static bool isMobile(BuildContext context) =>
      getDeviceType(MediaQuery.of(context).size) == DeviceScreenType.mobile;

  static bool isTablet(BuildContext context) =>
      getDeviceType(MediaQuery.of(context).size) == DeviceScreenType.tablet;

  static bool isDesktop(BuildContext context) =>
      getDeviceType(MediaQuery.of(context).size) == DeviceScreenType.desktop;



  static double responsiveWidth(BuildContext context, double percent) {
    assert(percent >= 0 && percent <= 1);
    final width = MediaQuery.of(context).size.width;
    return width * percent;
  }


  static double responsiveHeight(BuildContext context, double percent) {
    assert(percent >= 0 && percent <= 1);
    final height = MediaQuery.of(context).size.height;
    return height * percent;
  }




  static double scaleForDevice(
      BuildContext context, {
        double mobile = 1.0,
        double tablet = 1.2,
        double desktop = 1.4,
      }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }


  static double textScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1400) return 1.35;
    if (width >= 900) return 1.2;
    if (width >= 600) return 1.1;
    return 1.0;
  }


  static double iconScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1400) return 1.3;
    if (width >= 900) return 1.15;
    if (width >= 600) return 1.05;
    return 1.0;
  }


  static EdgeInsets contentPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 20);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 28);
    } else {
      return const EdgeInsets.symmetric(horizontal: 64, vertical: 32);
    }
  }


  static double sectionSpacing(BuildContext context) {
    if (isDesktop(context)) return 28;
    if (isTablet(context)) return 24;
    return 18;
  }

  static Widget builder({
    required Widget Function(
        BuildContext context,
        SizingInformation info,
        bool isMobile,
        bool isTablet,
        bool isDesktop,
        )
    builder,
  }) {
    return ResponsiveBuilder(
      builder: (context, info) {
        final isMobile = info.deviceScreenType == DeviceScreenType.mobile;
        final isTablet = info.deviceScreenType == DeviceScreenType.tablet;
        final isDesktop = info.deviceScreenType == DeviceScreenType.desktop;

        return builder(context, info, isMobile, isTablet, isDesktop);
      },
    );
  }
}
