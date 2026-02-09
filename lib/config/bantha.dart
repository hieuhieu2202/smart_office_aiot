import 'package:smart_factory/features/camera_test/model/error_item.dart';


class BanthaConfig {
  //  FACTORY -> FLOOR
  static const Map<String, List<String>> factoryFloors = {
    "F16": ["1F", "2F", "3F"],
    "F17": ["1F", "2F", "3F"],
  };

  // FACTORY -> FLOOR -> STATION
  static const Map<String, Map<String, List<String>>> stations = {
    "F16": {
      "1F": ["VI"],
      "2F": ["VI"],
      "3F": ["VI"],
    },
    "F17": {
      "1F": ["VI"],
      "2F": ["VI"],
      "3F": ["VI"],
    },
  };

  //  ERROR CODE
  static const List<ErrorItem> errorCodes = [
    ErrorItem(code: "BTS", name: "Bantha scratch"),
    ErrorItem(code: "BTD", name: "Bantha damage"),
    ErrorItem(code: "BTC25", name: "Bantha contamination 25%"),
    ErrorItem(code: "BTC10", name: "Bantha contamination 10%"),
    ErrorItem(code: "BRG", name: "Best regards"),
    ErrorItem(code: "Tee Nb", name: ""),
    ErrorItem(code: "MBD-QA", name: ""),
  ];

  // HELPERS
  static List<String> get factories =>
      factoryFloors.keys.toList();

  static List<String> floorsOf(String factory) =>
      factoryFloors[factory] ?? [];

  static List<String> stationsOf(String factory, String floor) =>
      stations[factory]?[floor] ?? [];

  /// Helper: tìm ErrorItem theo code (dùng khi load data cũ )
  static ErrorItem? errorByCode(String code) {
    try {
      return errorCodes.firstWhere((e) => e.code == code);
    } catch (_) {
      return null;
    }
  }
}
