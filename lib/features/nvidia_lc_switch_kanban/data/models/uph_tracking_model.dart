import '../../domain/entities/kanban_entities.dart';
import 'parsing.dart';

class UphTrackingModel extends UphTrackingEntity {
  UphTrackingModel({
    required List<String> sections,
    required List<String> models,
    required List<UphGroupModel> groups,
  }) : super(sections: sections, models: models, groups: groups);

  factory UphTrackingModel.fromJson(Map<String, dynamic> json) {
    final List<String> sections =
        (json['section'] as List? ?? <dynamic>[]).map((dynamic e) => e.toString()).toList();
    final List<String> models =
        (json['model'] as List? ?? <dynamic>[]).map((dynamic e) => e.toString()).toList();
    final List<UphGroupModel> groups =
        (json['data'] as List? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(UphGroupModel.fromJson)
            .toList();
    return UphTrackingModel(
      sections: sections,
      models: models,
      groups: groups,
    );
  }
}

class UphGroupModel extends UphGroupEntity {
  UphGroupModel({
    required String groupName,
    required List<double> pass,
    required List<double> pr,
    required int wip,
    required double uph,
  }) : super(
          groupName: groupName,
          pass: pass,
          pr: pr,
          wip: wip,
          uph: uph,
        );

  factory UphGroupModel.fromJson(Map<String, dynamic> json) {
    return UphGroupModel(
      groupName: readString(json, const ['grouP_NAME', 'group', 'groupName']),
      pass: readNumList(json, const ['pass']),
      pr: readNumList(json, const ['pr', 'PR']),
      wip: readInt(json, const ['wip', 'WIP']),
      uph: readDouble(json, const ['uph', 'UPH']),
    );
  }
}
