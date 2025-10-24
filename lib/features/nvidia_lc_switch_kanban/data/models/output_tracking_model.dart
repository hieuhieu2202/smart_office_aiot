import '../../domain/entities/kanban_entities.dart';
import 'parsing.dart';

class OutputTrackingModel extends OutputTrackingEntity {
  OutputTrackingModel({
    required List<String> sections,
    required List<String> models,
    required List<OutputGroupModel> groups,
  }) : super(sections: sections, models: models, groups: groups);

  factory OutputTrackingModel.fromJson(Map<String, dynamic> json) {
    final List<String> sections =
        (json['section'] as List? ?? <dynamic>[]).map((dynamic e) => e.toString()).toList();
    final List<String> models =
        (json['model'] as List? ?? <dynamic>[]).map((dynamic e) => e.toString()).toList();
    final List<OutputGroupModel> groups =
        (json['data'] as List? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
            .map(OutputGroupModel.fromJson)
            .toList();
    return OutputTrackingModel(
      sections: sections,
      models: models,
      groups: groups,
    );
  }
}

class OutputGroupModel extends OutputGroupEntity {
  OutputGroupModel({
    required String groupName,
    required String modelName,
    required List<double> pass,
    required List<double> fail,
    required List<double> yr,
    required List<double> rr,
    required int wip,
  }) : super(
          groupName: groupName,
          modelName: modelName,
          pass: pass,
          fail: fail,
          yr: yr,
          rr: rr,
          wip: wip,
        );

  factory OutputGroupModel.fromJson(Map<String, dynamic> json) {
    return OutputGroupModel(
      groupName: readString(json, const ['grouP_NAME', 'group', 'groupName']),
      modelName: readString(json, const ['modelName', 'MODEL_NAME', 'model']),
      pass: readNumList(json, const ['pass']),
      fail: readNumList(json, const ['fail']),
      yr: readNumList(json, const ['yr', 'YR']),
      rr: readNumList(json, const ['rr', 'RR']),
      wip: readInt(json, const ['wip', 'WIP']),
    );
  }
}
