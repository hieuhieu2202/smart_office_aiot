import 'package:flutter/material.dart';
import 'package:smart_factory/generated/l10n.dart';

/// Hàm lấy label đa ngôn ngữ cho tên module (project.name)
String getModuleLabel(BuildContext context, String key) {
  final S text = S.of(context);
  switch (key.toUpperCase()) {
    case "AUTOMATION":
      return text.dashboard_module_automation;
    case "ARLO":
      return text.dashboard_module_arlo;
    case "NETGEAR":
      return text.dashboard_module_netgear;
    case "SMT":
      return text.dashboard_module_smt;
    case "PTH":
      return text.dashboard_module_pth;
    case "ESD":
      return text.dashboard_module_esd;
    default:
      return key;
  }
}

/// Hàm lấy label đa ngôn ngữ cho từng sub-card (subProject.name)
String getCardLabel(BuildContext context, String key) {
  final S text = S.of(context);
  switch (key.toUpperCase()) {
    case "TE REPORT":
      return text.dashboard_card_te_report;
    case "TOP ERROR":
      return text.dashboard_card_top_error;
    case "TESTER TRACKING":
      return text.dashboard_card_tester_tracking;
    case "STATION RETEST RATE":
      return text.dashboard_card_station_retest_rate;
    case "MODEL RETEST RATE":
      return text.dashboard_card_model_retest_rate;
    case "STATION YEILD RATE":
      return text.dashboard_card_station_yield_rate;
    case "MODEL YIELD RATE":
      return text.dashboard_card_model_yield_rate;
    case "KANBAN TRACKING":
      return text.dashboard_card_kanban_tracking;
    case "STATUS MONITOR":
      return text.dashboard_card_status_monitor;
    case "PRINTER ONLINE":
      return text.dashboard_card_printer_online;
    case "PRINTER MACHINE":
      return text.dashboard_card_printer_machine;
    case "SPI MACHINE":
      return text.dashboard_card_spi_machine;
    case "MOUTER MACHINE":
      return text.dashboard_card_mouter_machine;
    case "OUTPUT TRACKING":
      return text.dashboard_card_output_tracking;
    case "REFLOW MACHINE":
      return text.dashboard_card_reflow_machine;
    case "AOI MACHINE":
      return text.dashboard_card_aoi_machine;
    case "SMT YIELD RATE":
      return text.dashboard_card_smt_yield_rate;
    case "PRODUCT STATUS":
      return text.dashboard_card_product_status;
    case "DASHBOARD":
      return text.dashboard_card_dashboard;
    case "DAILY REPORT":
      return text.dashboard_card_daily_report;
    case "INSP STATION":
      return text.dashboard_card_insp_station;
    case "PRESSFIT MACHINE":
      return text.dashboard_card_pressfit_machine;
    case "BURNIN STATUS":
      return text.dashboard_card_burnin_status;
    case "FO6-1F":
      return text.dashboard_card_fo6_1f;
    case "FO6-2F":
      return text.dashboard_card_fo6_2f;
    case "FO6-3F":
      return text.dashboard_card_fo6_3f;
    default:
      return key;
  }
}

/// Hàm trả về status đa ngôn ngữ (nếu bạn có dịch trong arb)
String getStatusText(BuildContext context, String status) {
  final S text = S.of(context);
  switch (status.toUpperCase()) {
    case "ACTIVE":
      return text.status_active;
    case "RUNNING":
      return text.status_running ;
    case "READY":
      return text.status_ready;
    case "WARNING":
      return text.status_warning;
    case "REPORTING":
      return text.status_reporting;
    case "STABLE":
      return text.status_stable ;
    case "TRACKING":
      return text.status_tracking;
    case "ONLINE":
      return text.status_online ;
    case "DASHBOARD":
      return text.status_dashboard ;
    case "MONITORING":
      return text.status_monitoring;
    case "BURNING":
      return text.status_burning;
    default:
      return status;
  }
}

/// Lấy welcome đa ngôn ngữ
String getWelcomeText(BuildContext context) {
  final S text = S.of(context);
  return text.welcome;
}
