import 'package:flutter/material.dart';
import '../widget/animated_app_icon.dart';

AppIconEffect getIconEffect(IconData icon, String status) {
  switch (icon.codePoint) {
    case 0xe8b8: // Icons.settings_applications
      return AppIconEffect.glow;
    case 0xe30c: // Icons.developer_board
      return AppIconEffect.pulse;
    case 0xe9f8: // Icons.hub
      return AppIconEffect.pulse;
    case 0xe3af: // Icons.camera_alt
    case 0xe3b0: // Icons.camera
      return AppIconEffect.flash;
    case 0xf102: // Icons.electrical_services
      return AppIconEffect.pulse;
    case 0xe53c: // Icons.contactless
      return AppIconEffect.shake;
    case 0xf02e: // Icons.manage_accounts
      return AppIconEffect.pulse;
    case 0xe322: // Icons.memory
      return AppIconEffect.glow;
    case 0xe871: // Icons.dashboard
      return AppIconEffect.sweep;
    case 0xe3ec: // Icons.analytics, bar_chart, pie_chart
    case 0xe26e:
    case 0xf200:
      return AppIconEffect.pulse;
    case 0xe7fb: // Icons.warning_amber_rounded
      return AppIconEffect.colorLoop;
    case 0xef3e: // Icons.local_fire_department
      return AppIconEffect.colorLoop;
    case 0xe162: // Icons.flash_on
      return AppIconEffect.flash;
    default:
      if (status.toUpperCase() == "ACTIVE" ||
          status.toUpperCase() == "RUNNING" ||
          status.toUpperCase() == "MONITORING" ||
          status.toUpperCase() == "TRACKING") {
        return AppIconEffect.pulse;
      }
      return AppIconEffect.none;
  }
}
