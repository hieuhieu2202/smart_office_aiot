import '../entities/clean_room_config.dart';
import '../entities/sensor_data.dart';
import '../entities/sensor_overview.dart';
import '../repositories/clean_room_repository.dart';

class GetConfigMappingUseCase {
  const GetConfigMappingUseCase(this.repository);
  final CleanRoomRepository repository;

  Future<CleanRoomConfig?> call({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  }) {
    return repository.fetchConfig(
      customer: customer,
      factory: factory,
      floor: floor,
      room: room,
    );
  }
}

class GetSensorOverviewUseCase {
  const GetSensorOverviewUseCase(this.repository);
  final CleanRoomRepository repository;

  Future<SensorOverview?> call({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  }) {
    return repository.fetchSensorOverview(
      customer: customer,
      factory: factory,
      floor: floor,
      room: room,
    );
  }
}

class GetSensorDataOverviewUseCase {
  const GetSensorDataOverviewUseCase(this.repository);
  final CleanRoomRepository repository;

  Future<List<SensorDataResponse>> call({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  }) {
    return repository.fetchSensorDataOverview(
      customer: customer,
      factory: factory,
      floor: floor,
      room: room,
    );
  }
}

class GetSensorDataHistoriesUseCase {
  const GetSensorDataHistoriesUseCase(this.repository);
  final CleanRoomRepository repository;

  Future<List<SensorDataResponse>> call({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  }) {
    return repository.fetchSensorDataHistories(
      customer: customer,
      factory: factory,
      floor: floor,
      room: room,
    );
  }
}
