import '../../domain/entities/kanban_entities.dart';
import 'parsing.dart';

class UpdTrackingModel extends UpdTrackingEntity {
  UpdTrackingModel({
    required List<String> dates,
    required List<String> models,
    required List<UpdGroupModel> groups,
  }) : super(dates: dates, models: models, groups: groups);

  factory UpdTrackingModel.fromJson(Map<String, dynamic> json) {
    final List<String> dates =
        (json['date'] as List? ?? <dynamic>[]).map((dynamic e) => e.toString()).toList();
    final List<String> models =
        (json['model'] as List? ?? <dynamic>[]).map((dynamic e) => e.toString()).toList();
    final List<UpdGroupModel> groups =
        (json['data'] as List? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(UpdGroupModel.fromJson)
            .toList();
    return UpdTrackingModel(
      dates: dates,
      models: models,
      groups: groups,
    );
  }
}

class UpdGroupModel extends UpdGroupEntity {
  UpdGroupModel({
    required String groupName,
    required List<double> pass,
    required List<double> pr,
    required int wip,
    required double upd,
  }) : super(
          groupName: groupName,
          pass: pass,
          pr: pr,
          wip: wip,
          upd: upd,
        );

  factory UpdGroupModel.fromJson(Map<String, dynamic> json) {
    return UpdGroupModel(
      groupName: readString(json, const ['grouP_NAME', 'group', 'groupName']),
      pass: readNumList(json, const ['pass', 'PASS']),
      pr: readNumList(json, const ['pr', 'PR']),
      wip: readInt(json, const ['wip', 'WIP']),
      upd: readDouble(json, const ['upd', 'UPD']),
    );
  }
}
