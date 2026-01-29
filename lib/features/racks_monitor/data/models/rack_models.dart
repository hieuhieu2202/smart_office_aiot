import '../../domain/entities/rack_entities.dart';

/// Data models that map to API responses
/// These extend entities and add fromJson/toJson methods

class RackMonitorLocationModel extends RackMonitorLocation {
  const RackMonitorLocationModel({
    required super.factory,
    required super.floor,
    required super.room,
    required super.group,
    required super.model,
  });

  factory RackMonitorLocationModel.fromJson(Map<String, dynamic> json) {
    return RackMonitorLocationModel(
      factory: json['factory']?.toString() ?? '',
      floor: json['floor']?.toString() ?? '',
      room: json['room']?.toString() ?? '',
      group: json['group']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'factory': factory,
      'floor': floor,
      'room': room,
      'group': group,
      'model': model,
    };
  }
}

class RackMonitorDataModel extends RackMonitorData {
  const RackMonitorDataModel({
    required super.quantitySummary,
    required super.modelDetails,
    required super.rackDetails,
    required super.slotStatic,
  });

  factory RackMonitorDataModel.fromJson(Map<String, dynamic> json) {
    return RackMonitorDataModel(
      quantitySummary: QuantitySummaryModel.fromJson(
        json['quantitySummary'] ?? {},
      ),
      modelDetails: (json['modelDetails'] as List<dynamic>?)
              ?.map((e) => ModelDetailModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rackDetails: (json['rackDetails'] as List<dynamic>?)
              ?.map((e) => RackDetailModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      slotStatic: (json['slotStatic'] as List<dynamic>?)
              ?.map((e) => SlotStaticItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class QuantitySummaryModel extends QuantitySummary {
  const QuantitySummaryModel({
    required double ut,
    required int wip,
    required int input,
    required int firstPass,
    required int secondPass,
    required int pass,
    required int rePass,
    required int totalPass,
    required int firstFail,
    required int secondFail,
    required int fail,
    required int repair,
    required int repairPass,
    required int repairFail,
    required int totalFail,
    required double fpr,
    required double spr,
    required double rr,
    required double yr,
  }) : super(
    ut: ut,
    wip: wip,
    input: input,
    firstPass: firstPass,
    secondPass: secondPass,
    pass: pass,
    rePass: rePass,
    totalPass: totalPass,
    firstFail: firstFail,
    secondFail: secondFail,
    fail: fail,
    repair: repair,
    repairPass: repairPass,
    repairFail: repairFail,
    totalFail: totalFail,
    fpr: fpr,
    spr: spr,
    rr: rr,
    yr: yr,
  );

  factory QuantitySummaryModel.fromJson(Map<String, dynamic> json) {
    return QuantitySummaryModel(
      ut: (json['ut'] as num?)?.toDouble() ?? 0.0,
      wip: json['wip'] as int? ?? 0,
      input: json['input'] as int? ?? 0,
      firstPass: (json['firstPass'] ?? json['first_Pass']) as int? ?? 0,
      secondPass: (json['secondPass'] ?? json['second_Pass']) as int? ?? 0,
      pass: json['pass'] as int? ?? 0,
      rePass: (json['rePass'] ?? json['re_Pass']) as int? ?? 0,
      totalPass: (json['totalPass'] ?? json['total_Pass']) as int? ?? 0,
      firstFail: (json['firstFail'] ?? json['first_Fail']) as int? ?? 0,
      secondFail: (json['secondFail'] ?? json['second_Fail']) as int? ?? 0,
      fail: json['fail'] as int? ?? 0,
      repair: json['repair'] as int? ?? 0,
      repairPass: (json['repairPass'] ?? json['repair_Pass']) as int? ?? 0,
      repairFail: (json['repairFail'] ?? json['repair_Fail']) as int? ?? 0,
      totalFail: (json['totalFail'] ?? json['total_Fail']) as int? ?? 0,
      fpr: (json['fpr'] as num?)?.toDouble() ?? 0.0,
      spr: (json['spr'] as num?)?.toDouble() ?? 0.0,
      rr: (json['rr'] as num?)?.toDouble() ?? 0.0,
      yr: (json['yr'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ModelDetailModel extends ModelDetail {
  const ModelDetailModel({
    required super.modelName,
    required super.pass,
    required super.totalPass,
  });

  factory ModelDetailModel.fromJson(Map<String, dynamic> json) {
    return ModelDetailModel(
      modelName: json['modelName']?.toString() ?? '',
      pass: json['pass'] as int? ?? 0,
      totalPass: json['totalPass'] as int? ?? 0,
    );
  }
}

class RackDetailModel extends RackDetail {
  const RackDetailModel({
    required super.rackId,
    required super.rackName,
    required super.nickName,
    required super.groupName,
    required super.modelName,
    required super.status,
    required super.ut,
    required super.input,
    required super.firstPass,
    required super.secondPass,
    required super.pass,
    required super.rePass,
    required super.totalPass,
    required super.firstFail,
    required super.fail,
    required super.fpr,
    required super.yr,
    required super.runtime,
    required super.totalTime,
    required super.slotDetails,
  });

  factory RackDetailModel.fromJson(Map<String, dynamic> json) {
    return RackDetailModel(
      rackId: json['rackId']?.toString() ?? json['rackName']?.toString() ?? '',
      rackName: json['rackName']?.toString() ?? json['rack']?.toString() ?? '',
      nickName: json['nickName']?.toString() ?? json['nickname']?.toString() ?? '',
      groupName: json['groupName']?.toString() ?? json['GroupName']?.toString() ?? '',
      modelName: json['modelName']?.toString() ?? json['model']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      ut: (json['ut'] ?? json['UT'])?.toDouble() ?? 0.0,
      input: json['input'] as int? ?? 0,
      firstPass: (json['firstPass'] ?? json['first_Pass']) as int? ?? 0,
      secondPass: (json['secondPass'] ?? json['second_Pass']) as int? ?? 0,
      pass: json['pass'] as int? ?? 0,
      rePass: (json['rePass'] ?? json['re_Pass']) as int? ?? 0,
      totalPass: (json['totalPass'] ?? json['total_Pass']) as int? ?? 0,
      firstFail: (json['firstFail'] ?? json['first_Fail']) as int? ?? 0,
      fail: json['fail'] as int? ?? 0,
      fpr: (json['fpr'] ?? json['FPR'])?.toDouble() ?? 0.0,
      yr: (json['yr'] ?? json['YR'])?.toDouble() ?? 0.0,
      runtime: (json['runtime'])?.toDouble() ?? 0.0,
      totalTime: (json['totalTime'] ?? json['total_Time'])?.toDouble() ?? 0.0,
      slotDetails: (json['slotDetails'] as List<dynamic>?)
              ?.map((e) => SlotDetailModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SlotDetailModel extends SlotDetail {
  const SlotDetailModel({
    required super.slotId,
    required super.nickName,
    required super.slotNumber,
    required super.slotName,
    required super.modelName,
    required super.status,
    required super.input,
    required super.firstPass,
    required super.secondPass,
    required super.pass,
    required super.rePass,
    required super.totalPass,
    required super.firstFail,
    required super.fail,
    required super.fpr,
    required super.yr,
    required super.runtime,
    required super.totalTime,
  });

  factory SlotDetailModel.fromJson(Map<String, dynamic> json) {
    return SlotDetailModel(
      slotId: json['slotId']?.toString() ?? json['slotNumber']?.toString() ?? '',
      nickName: json['nickName']?.toString() ?? json['nickname']?.toString() ?? '',
      slotNumber: json['slotNumber']?.toString() ?? json['slotNo']?.toString() ?? '',
      slotName: json['slotName']?.toString() ?? json['slot_name']?.toString() ?? '',
      modelName: json['modelName']?.toString() ?? json['model']?.toString() ?? '',
      status: json['status']?.toString() ?? json['slotStatus']?.toString() ?? '',
      input: json['input'] as int? ?? 0,
      firstPass: (json['firstPass'] ?? json['first_Pass']) as int? ?? 0,
      secondPass: (json['secondPass'] ?? json['second_Pass']) as int? ?? 0,
      pass: json['pass'] as int? ?? 0,
      rePass: (json['rePass'] ?? json['re_Pass']) as int? ?? 0,
      totalPass: (json['totalPass'] ?? json['total_Pass']) as int? ?? 0,
      firstFail: (json['firstFail'] ?? json['first_Fail']) as int? ?? 0,
      fail: json['fail'] as int? ?? 0,
      fpr: (json['fpr'] ?? json['FPR'])?.toDouble() ?? 0.0,
      yr: (json['yr'] ?? json['YR'])?.toDouble() ?? 0.0,
      runtime: (json['runtime'])?.toDouble() ?? 0.0,
      totalTime: (json['totalTime'] ?? json['total_Time'])?.toDouble() ?? 0.0,
    );
  }
}

class SlotStaticItemModel extends SlotStaticItem {
  const SlotStaticItemModel({
    required super.status,
    required super.value,
  });

  factory SlotStaticItemModel.fromJson(Map<String, dynamic> json) {
    return SlotStaticItemModel(
      status: json['status']?.toString() ?? '',
      value: json['value'] as int? ?? 0,
    );
  }
}

