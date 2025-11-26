import '../entities/clean_room_config.dart';
import '../entities/sensor_data.dart';
import '../entities/sensor_overview.dart';

abstract class CleanRoomRepository {
  Future<List<String>> fetchCustomers();
  Future<List<String>> fetchFactories({required String customer});
  Future<List<String>> fetchFloors({required String customer, required String factory});
  Future<List<String>> fetchRooms({
    required String customer,
    required String factory,
    required String floor,
  });
  Future<CleanRoomConfig?> fetchConfig({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  });
  Future<SensorOverview?> fetchSensorOverview({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  });
  Future<List<SensorDataResponse>> fetchSensorDataOverview({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  });
  Future<List<SensorDataResponse>> fetchSensorDataHistories({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  });
}
