// Rack Monitor Domain Entities
// These are the business entities that represent the core domain

class RackMonitorLocation {
  final String factory;
  final String floor;
  final String room;
  final String group;
  final String model; // Keep as 'model' for internal use, maps from 'product' in API

  const RackMonitorLocation({
    required this.factory,
    required this.floor,
    required this.room,
    required this.group,
    required this.model,
  });
}

class RackMonitorData {
  final QuantitySummary quantitySummary;
  final List<ModelDetail> modelDetails;
  final List<RackDetail> rackDetails;
  final List<SlotStaticItem> slotStatic;

  const RackMonitorData({
    required this.quantitySummary,
    required this.modelDetails,
    required this.rackDetails,
    required this.slotStatic,
  });
}

class QuantitySummary {
  final double ut;
  final int wip;
  final int input;
  final int firstPass;
  final int secondPass;
  final int pass;
  final int rePass;
  final int totalPass;
  final int firstFail;
  final int secondFail;
  final int fail;
  final int repair;
  final int repairPass;
  final int repairFail;
  final int totalFail;
  final double fpr;
  final double spr;
  final double rr;
  final double yr;

  const QuantitySummary({
    required this.ut,
    required this.wip,
    required this.input,
    required this.firstPass,
    required this.secondPass,
    required this.pass,
    required this.rePass,
    required this.totalPass,
    required this.firstFail,
    required this.secondFail,
    required this.fail,
    required this.repair,
    required this.repairPass,
    required this.repairFail,
    required this.totalFail,
    required this.fpr,
    required this.spr,
    required this.rr,
    required this.yr,
  });
}

class ModelDetail {
  final String modelName;
  final int pass;
  final int totalPass;

  const ModelDetail({
    required this.modelName,
    required this.pass,
    required this.totalPass,
  });
}

class RackDetail {
  final String rackId;
  final String rackName;
  final String nickName;
  final String groupName;
  final String modelName;
  final String status;
  final double ut;
  final int input;
  final int firstPass;
  final int secondPass;
  final int pass;
  final int rePass;
  final int totalPass;
  final int firstFail;
  final int fail;
  final double fpr;
  final double yr;
  final double runtime;
  final double totalTime;
  final List<SlotDetail> slotDetails;

  const RackDetail({
    required this.rackId,
    required this.rackName,
    required this.nickName,
    required this.groupName,
    required this.modelName,
    required this.status,
    required this.ut,
    required this.input,
    required this.firstPass,
    required this.secondPass,
    required this.pass,
    required this.rePass,
    required this.totalPass,
    required this.firstFail,
    required this.fail,
    required this.fpr,
    required this.yr,
    required this.runtime,
    required this.totalTime,
    required this.slotDetails,
  });
}

class SlotDetail {
  final String slotId;
  final String nickName;
  final String slotNumber;
  final String slotName;
  final String modelName;
  final String status;
  final int input;
  final int firstPass;
  final int secondPass;
  final int pass;
  final int rePass;
  final int totalPass;
  final int firstFail;
  final int fail;
  final double fpr;
  final double yr;
  final double runtime;
  final double totalTime;

  const SlotDetail({
    required this.slotId,
    required this.nickName,
    required this.slotNumber,
    required this.slotName,
    required this.modelName,
    required this.status,
    required this.input,
    required this.firstPass,
    required this.secondPass,
    required this.pass,
    required this.rePass,
    required this.totalPass,
    required this.firstFail,
    required this.fail,
    required this.fpr,
    required this.yr,
    required this.runtime,
    required this.totalTime,
  });
}

class SlotStaticItem {
  final String status;
  final int value;

  const SlotStaticItem({
    required this.status,
    required this.value,
  });
}

class ModelPassSummary {
  final String model;
  final int pass;
  final int totalPass;

  const ModelPassSummary({
    required this.model,
    required this.pass,
    required this.totalPass,
  });
}

