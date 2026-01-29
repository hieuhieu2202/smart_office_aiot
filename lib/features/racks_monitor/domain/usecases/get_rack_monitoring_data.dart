import '../entities/rack_entities.dart';
import '../repositories/rack_monitor_repository.dart';

/// Use case for fetching rack monitoring data
class GetRackMonitoringData {
  final RackMonitorRepository repository;

  GetRackMonitoringData(this.repository);

  Future<RackMonitorData> call({
    required String factory,
    required String floor,
    required String room,
    required String group,
    required String model,
    String? nickName,
    String? dateRange,
  }) async {
    return await repository.getMonitoringData(
      factory: factory,
      floor: floor,
      room: room,
      group: group,
      model: model,
      nickName: nickName,
      dateRange: dateRange,
    );
  }
}

