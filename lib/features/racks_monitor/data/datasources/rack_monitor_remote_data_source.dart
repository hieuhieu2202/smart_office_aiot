import '../../../../service/lc_switch_rack_api.dart';
import '../models/rack_models.dart';

/// Remote data source for Rack Monitor
/// Communicates with the API
class RackMonitorRemoteDataSource {
  Future<List<RackMonitorLocationModel>> getLocations() async {
    final locations = await RackMonitorApi.getLocations();
    return locations
        .map(
          (loc) => RackMonitorLocationModel(
            factory: loc.factory,
            floor: loc.floor,
            room: loc.room,
            group: loc.group,
            model: loc.model,
          ),
        )
        .toList();
  }

  Future<RackMonitorDataModel> getMonitoringData({
    required Map<String, dynamic> body,
  }) async {
    final data = await RackMonitorApi.getDataMonitoring(body: body);

    return RackMonitorDataModel(
      quantitySummary: QuantitySummaryModel(
        ut: data.quantitySummary.ut,
        wip: data.quantitySummary.wip,
        input: data.quantitySummary.input,
        firstPass: data.quantitySummary.firstPass,
        secondPass: data.quantitySummary.secondPass,
        pass: data.quantitySummary.pass,
        rePass: data.quantitySummary.rePass,
        totalPass: data.quantitySummary.totalPass,
        firstFail: data.quantitySummary.firstFail,
        secondFail: data.quantitySummary.secondFail,
        fail: data.quantitySummary.fail,
        repair: data.quantitySummary.repair,
        repairPass: data.quantitySummary.repairPass,
        repairFail: data.quantitySummary.repairFail,
        totalFail: data.quantitySummary.totalFail,
        fpr: data.quantitySummary.fpr,
        spr: data.quantitySummary.spr,
        rr: data.quantitySummary.rr,
        yr: data.quantitySummary.yr,
      ),
      modelDetails: data.modelDetails
          .map(
            (m) => ModelDetailModel(
              modelName: m.modelName,
              pass: m.pass,
              totalPass: m.totalPass,
            ),
          )
          .toList(),
      rackDetails: data.rackDetails
          .map(
            (r) => RackDetailModel(
              rackId: r.rackName,
              rackName: r.rackName,
              nickName: r.nickName,
              groupName: r.groupName,
              modelName: r.modelName,
              status: r.slotDetails.isEmpty ? 'IDLE' : 'ACTIVE',
              ut: r.ut,
              input: r.input,
              firstPass: r.firstPass,
              secondPass: r.secondPass,
              pass: r.pass,
              rePass: r.rePass,
              totalPass: r.totalPass,
              firstFail: r.firstFail,
              fail: r.fail,
              fpr: r.fpr,
              yr: r.yr,
              runtime: r.runtime,
              totalTime: r.totalTime,
              slotDetails: r.slotDetails
                  .map(
                    (s) => SlotDetailModel(
                      slotId: s.slotNumber,
                      nickName: s.nickName,
                      slotNumber: s.slotNumber,
                      slotName: s.slotName,
                      modelName: s.modelName,
                      status: s.status,
                      input: s.input,
                      firstPass: s.firstPass,
                      secondPass: s.secondPass,
                      pass: s.pass,
                      rePass: s.rePass,
                      totalPass: s.totalPass,
                      firstFail: s.firstFail,
                      fail: s.fail,
                      fpr: s.fpr,
                      yr: s.yr,
                      runtime: s.runtime,
                      totalTime: s.totalTime,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
      slotStatic: data.slotStatic
          .map(
            (s) => SlotStaticItemModel(
              status: s.status,
              value: s.value,
            ),
          )
          .toList(),
    );
  }

  Future<void> ping() async {
    await RackMonitorApi.quickPing();
  }

  Future<List<String>> getModels() async {
    return await RackMonitorApi.getModels();
  }
}

