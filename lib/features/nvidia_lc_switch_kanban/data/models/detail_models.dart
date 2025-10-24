import '../../domain/entities/kanban_entities.dart';
import 'parsing.dart';

class OutputTrackingDetailModel extends OutputTrackingDetailEntity {
  OutputTrackingDetailModel({
    required List<ErrorDetailEntity> errorDetails,
    required List<TesterDetailEntity> testerDetails,
  }) : super(errorDetails: errorDetails, testerDetails: testerDetails);

  factory OutputTrackingDetailModel.fromAny(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['value'] is Map<String, dynamic>) {
        return OutputTrackingDetailModel.fromJson(
          Map<String, dynamic>.from(raw['value'] as Map),
        );
      }
      if (raw['data'] is Map<String, dynamic>) {
        return OutputTrackingDetailModel.fromJson(
          Map<String, dynamic>.from(raw['data'] as Map),
        );
      }
      return OutputTrackingDetailModel.fromJson(raw);
    }
    throw Exception('GetOutputTrackingDataDetail: invalid payload');
  }

  factory OutputTrackingDetailModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> readList(String key) {
      final dynamic value = json[key];
      if (value is List) return value;
      if (value is Map<String, dynamic> && value['data'] is List) {
        return List<dynamic>.from(value['data'] as List);
      }
      return const <dynamic>[];
    }

    final List<Map<String, dynamic>> errors = readList('errorDetails')
        .whereType<Map<String, dynamic>>()
        .toList();
    final List<Map<String, dynamic>> testers = readList('testerDetails')
        .whereType<Map<String, dynamic>>()
        .toList();

    return OutputTrackingDetailModel(
      errorDetails: readErrorDetails(errors),
      testerDetails: readTesterDetails(testers),
    );
  }
}
