// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Login`
  String get login {
    return Intl.message('Login', name: 'login', desc: '', args: []);
  }

  /// `Username`
  String get username {
    return Intl.message('Username', name: 'username', desc: '', args: []);
  }

  /// `Password`
  String get password {
    return Intl.message('Password', name: 'password', desc: '', args: []);
  }

  /// `Please enter both username and password!`
  String get please_enter_username_password {
    return Intl.message(
      'Please enter both username and password!',
      name: 'please_enter_username_password',
      desc: '',
      args: [],
    );
  }

  /// `Logout Confirmation`
  String get logout_confirmation {
    return Intl.message(
      'Logout Confirmation',
      name: 'logout_confirmation',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to logout?`
  String get logout_question {
    return Intl.message(
      'Are you sure you want to logout?',
      name: 'logout_question',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Logout`
  String get confirm_logout {
    return Intl.message('Logout', name: 'confirm_logout', desc: '', args: []);
  }

  /// `Version`
  String get version {
    return Intl.message('Version', name: 'version', desc: '', args: []);
  }

  /// `Logout`
  String get logout {
    return Intl.message('Logout', name: 'logout', desc: '', args: []);
  }

  /// `Language`
  String get language {
    return Intl.message('Language', name: 'language', desc: '', args: []);
  }

  /// `Personal information`
  String get personal_info {
    return Intl.message(
      'Personal information',
      name: 'personal_info',
      desc: '',
      args: [],
    );
  }

  /// `Dark mode`
  String get dark_mode {
    return Intl.message('Dark mode', name: 'dark_mode', desc: '', args: []);
  }

  /// `Setting`
  String get settings {
    return Intl.message('Setting', name: 'settings', desc: '', args: []);
  }

  /// `No ID`
  String get no_id {
    return Intl.message('No ID', name: 'no_id', desc: '', args: []);
  }

  /// `Select language`
  String get select_language {
    return Intl.message(
      'Select language',
      name: 'select_language',
      desc: '',
      args: [],
    );
  }

  /// `Active`
  String get status_active {
    return Intl.message('Active', name: 'status_active', desc: '', args: []);
  }

  /// `Running`
  String get status_running {
    return Intl.message('Running', name: 'status_running', desc: '', args: []);
  }

  /// `Ready`
  String get status_ready {
    return Intl.message('Ready', name: 'status_ready', desc: '', args: []);
  }

  /// `Warning`
  String get status_warning {
    return Intl.message('Warning', name: 'status_warning', desc: '', args: []);
  }

  /// `Reporting`
  String get status_reporting {
    return Intl.message(
      'Reporting',
      name: 'status_reporting',
      desc: '',
      args: [],
    );
  }

  /// `Stable`
  String get status_stable {
    return Intl.message('Stable', name: 'status_stable', desc: '', args: []);
  }

  /// `Tracking`
  String get status_tracking {
    return Intl.message(
      'Tracking',
      name: 'status_tracking',
      desc: '',
      args: [],
    );
  }

  /// `Online`
  String get status_online {
    return Intl.message('Online', name: 'status_online', desc: '', args: []);
  }

  /// `Dashboard`
  String get status_dashboard {
    return Intl.message(
      'Dashboard',
      name: 'status_dashboard',
      desc: '',
      args: [],
    );
  }

  /// `Monitoring`
  String get status_monitoring {
    return Intl.message(
      'Monitoring',
      name: 'status_monitoring',
      desc: '',
      args: [],
    );
  }

  /// `Burning`
  String get status_burning {
    return Intl.message('Burning', name: 'status_burning', desc: '', args: []);
  }

  /// `TE REPORT`
  String get dashboard_card_te_report {
    return Intl.message(
      'TE REPORT',
      name: 'dashboard_card_te_report',
      desc: '',
      args: [],
    );
  }

  /// `TOP ERROR`
  String get dashboard_card_top_error {
    return Intl.message(
      'TOP ERROR',
      name: 'dashboard_card_top_error',
      desc: '',
      args: [],
    );
  }

  /// `TESTER TRACKING`
  String get dashboard_card_tester_tracking {
    return Intl.message(
      'TESTER TRACKING',
      name: 'dashboard_card_tester_tracking',
      desc: '',
      args: [],
    );
  }

  /// `STATION RETEST RATE`
  String get dashboard_card_station_retest_rate {
    return Intl.message(
      'STATION RETEST RATE',
      name: 'dashboard_card_station_retest_rate',
      desc: '',
      args: [],
    );
  }

  /// `MODEL RETEST RATE`
  String get dashboard_card_model_retest_rate {
    return Intl.message(
      'MODEL RETEST RATE',
      name: 'dashboard_card_model_retest_rate',
      desc: '',
      args: [],
    );
  }

  /// `STATION YEILD RATE`
  String get dashboard_card_station_yield_rate {
    return Intl.message(
      'STATION YEILD RATE',
      name: 'dashboard_card_station_yield_rate',
      desc: '',
      args: [],
    );
  }

  /// `MODEL YIELD RATE`
  String get dashboard_card_model_yield_rate {
    return Intl.message(
      'MODEL YIELD RATE',
      name: 'dashboard_card_model_yield_rate',
      desc: '',
      args: [],
    );
  }

  /// `KANBAN TRACKING`
  String get dashboard_card_kanban_tracking {
    return Intl.message(
      'KANBAN TRACKING',
      name: 'dashboard_card_kanban_tracking',
      desc: '',
      args: [],
    );
  }

  /// `Welcome`
  String get welcome {
    return Intl.message('Welcome', name: 'welcome', desc: '', args: []);
  }

  /// `STATUS MONITOR`
  String get dashboard_card_status_monitor {
    return Intl.message(
      'STATUS MONITOR',
      name: 'dashboard_card_status_monitor',
      desc: '',
      args: [],
    );
  }

  /// `PRINTER ONLINE`
  String get dashboard_card_printer_online {
    return Intl.message(
      'PRINTER ONLINE',
      name: 'dashboard_card_printer_online',
      desc: '',
      args: [],
    );
  }

  /// `PRINTER MACHINE`
  String get dashboard_card_printer_machine {
    return Intl.message(
      'PRINTER MACHINE',
      name: 'dashboard_card_printer_machine',
      desc: '',
      args: [],
    );
  }

  /// `SPI MACHINE`
  String get dashboard_card_spi_machine {
    return Intl.message(
      'SPI MACHINE',
      name: 'dashboard_card_spi_machine',
      desc: '',
      args: [],
    );
  }

  /// `MOUTER MACHINE`
  String get dashboard_card_mouter_machine {
    return Intl.message(
      'MOUTER MACHINE',
      name: 'dashboard_card_mouter_machine',
      desc: '',
      args: [],
    );
  }

  /// `OUTPUT TRACKING`
  String get dashboard_card_output_tracking {
    return Intl.message(
      'OUTPUT TRACKING',
      name: 'dashboard_card_output_tracking',
      desc: '',
      args: [],
    );
  }

  /// `REFLOW MACHINE`
  String get dashboard_card_reflow_machine {
    return Intl.message(
      'REFLOW MACHINE',
      name: 'dashboard_card_reflow_machine',
      desc: '',
      args: [],
    );
  }

  /// `AOI MACHINE`
  String get dashboard_card_aoi_machine {
    return Intl.message(
      'AOI MACHINE',
      name: 'dashboard_card_aoi_machine',
      desc: '',
      args: [],
    );
  }

  /// `SMT YIELD RATE`
  String get dashboard_card_smt_yield_rate {
    return Intl.message(
      'SMT YIELD RATE',
      name: 'dashboard_card_smt_yield_rate',
      desc: '',
      args: [],
    );
  }

  /// `PRODUCT STATUS`
  String get dashboard_card_product_status {
    return Intl.message(
      'PRODUCT STATUS',
      name: 'dashboard_card_product_status',
      desc: '',
      args: [],
    );
  }

  /// `DASHBOARD`
  String get dashboard_card_dashboard {
    return Intl.message(
      'DASHBOARD',
      name: 'dashboard_card_dashboard',
      desc: '',
      args: [],
    );
  }

  /// `DAILY REPORT`
  String get dashboard_card_daily_report {
    return Intl.message(
      'DAILY REPORT',
      name: 'dashboard_card_daily_report',
      desc: '',
      args: [],
    );
  }

  /// `INSP STATION`
  String get dashboard_card_insp_station {
    return Intl.message(
      'INSP STATION',
      name: 'dashboard_card_insp_station',
      desc: '',
      args: [],
    );
  }

  /// `PRESSFIT MACHINE`
  String get dashboard_card_pressfit_machine {
    return Intl.message(
      'PRESSFIT MACHINE',
      name: 'dashboard_card_pressfit_machine',
      desc: '',
      args: [],
    );
  }

  /// `BURNIN STATUS`
  String get dashboard_card_burnin_status {
    return Intl.message(
      'BURNIN STATUS',
      name: 'dashboard_card_burnin_status',
      desc: '',
      args: [],
    );
  }

  /// `F06-1F`
  String get dashboard_card_fo6_1f {
    return Intl.message(
      'F06-1F',
      name: 'dashboard_card_fo6_1f',
      desc: '',
      args: [],
    );
  }

  /// `F06-2F`
  String get dashboard_card_fo6_2f {
    return Intl.message(
      'F06-2F',
      name: 'dashboard_card_fo6_2f',
      desc: '',
      args: [],
    );
  }

  /// `F06-3F`
  String get dashboard_card_fo6_3f {
    return Intl.message(
      'F06-3F',
      name: 'dashboard_card_fo6_3f',
      desc: '',
      args: [],
    );
  }

  /// `Automation`
  String get dashboard_module_automation {
    return Intl.message(
      'Automation',
      name: 'dashboard_module_automation',
      desc: '',
      args: [],
    );
  }

  /// `ARLO`
  String get dashboard_module_arlo {
    return Intl.message(
      'ARLO',
      name: 'dashboard_module_arlo',
      desc: '',
      args: [],
    );
  }

  /// `NETGEAR`
  String get dashboard_module_netgear {
    return Intl.message(
      'NETGEAR',
      name: 'dashboard_module_netgear',
      desc: '',
      args: [],
    );
  }

  /// `SMT`
  String get dashboard_module_smt {
    return Intl.message(
      'SMT',
      name: 'dashboard_module_smt',
      desc: '',
      args: [],
    );
  }

  /// `PTH`
  String get dashboard_module_pth {
    return Intl.message(
      'PTH',
      name: 'dashboard_module_pth',
      desc: '',
      args: [],
    );
  }

  /// `ESD`
  String get dashboard_module_esd {
    return Intl.message(
      'ESD',
      name: 'dashboard_module_esd',
      desc: '',
      args: [],
    );
  }

  /// `Full name`
  String get fullname {
    return Intl.message('Full name', name: 'fullname', desc: '', args: []);
  }

  /// `Job title`
  String get job_title {
    return Intl.message('Job title', name: 'job_title', desc: '', args: []);
  }

  /// `Department`
  String get department {
    return Intl.message('Department', name: 'department', desc: '', args: []);
  }

  /// `Department Detail`
  String get department_detail {
    return Intl.message(
      'Department Detail',
      name: 'department_detail',
      desc: '',
      args: [],
    );
  }

  /// `Location`
  String get location {
    return Intl.message('Location', name: 'location', desc: '', args: []);
  }

  /// `Managers`
  String get managers {
    return Intl.message('Managers', name: 'managers', desc: '', args: []);
  }

  /// `Hire Date`
  String get hire_date {
    return Intl.message('Hire Date', name: 'hire_date', desc: '', args: []);
  }

  /// `Email`
  String get email {
    return Intl.message('Email', name: 'email', desc: '', args: []);
  }

  /// `Not updated`
  String get not_updated {
    return Intl.message('Not updated', name: 'not_updated', desc: '', args: []);
  }

  /// `Home`
  String get home {
    return Intl.message('Home', name: 'home', desc: '', args: []);
  }

  /// `History`
  String get history {
    return Intl.message('History', name: 'history', desc: '', args: []);
  }

  /// `Notification`
  String get notification {
    return Intl.message(
      'Notification',
      name: 'notification',
      desc: '',
      args: [],
    );
  }

  /// `Quick login (FaceID/Fingerprint)`
  String get quick_login_faceid {
    return Intl.message(
      'Quick login (FaceID/Fingerprint)',
      name: 'quick_login_faceid',
      desc: '',
      args: [],
    );
  }

  /// `Activate FaceID/Fingerprint in Settings after login`
  String get activate_faceid_note {
    return Intl.message(
      'Activate FaceID/Fingerprint in Settings after login',
      name: 'activate_faceid_note',
      desc: '',
      args: [],
    );
  }

  /// `You need to log in first to activate quick login with face recognition!`
  String get need_login_first_to_activate_faceid {
    return Intl.message(
      'You need to log in first to activate quick login with face recognition!',
      name: 'need_login_first_to_activate_faceid',
      desc: '',
      args: [],
    );
  }

  /// `Login with another account`
  String get login_with_another_account {
    return Intl.message(
      'Login with another account',
      name: 'login_with_another_account',
      desc: '',
      args: [],
    );
  }

  /// `Welcome to MBD-Factory`
  String get welcome_factory {
    return Intl.message(
      'Welcome to MBD-Factory',
      name: 'welcome_factory',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'vi'),
      Locale.fromSubtags(languageCode: 'zh'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
