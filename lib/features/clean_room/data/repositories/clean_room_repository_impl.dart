import '../../domain/entities/clean_room_config.dart';
import '../../domain/entities/sensor_data.dart';
import '../../domain/entities/sensor_overview.dart';
import '../../domain/repositories/clean_room_repository.dart';
import '../datasources/clean_room_remote_data_source.dart';
import '../models/clean_room_config_model.dart';
import '../models/sensor_models.dart';

class CleanRoomRepositoryImpl implements CleanRoomRepository {
  CleanRoomRepositoryImpl({CleanRoomRemoteDataSource? remote})
      : _remote = remote ?? CleanRoomRemoteDataSource();

  final CleanRoomRemoteDataSource _remote;

  @override
  Future<List<String>> fetchCustomers() => _remote.fetchCustomers();

  @override
  Future<CleanRoomConfig?> fetchConfig({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  }) =>
      _remote.fetchConfig(
        customer: customer,
        factory: factory,
        floor: floor,
        room: room,
      );

  @override
  Future<List<String>> fetchFactories({required String customer}) =>
      _remote.fetchFactories(customer: customer);

  @override
  Future<List<String>> fetchFloors({
    required String customer,
    required String factory,
  }) =>
      _remote.fetchFloors(customer: customer, factory: factory);

  @override
  Future<List<String>> fetchRooms({
    required String customer,
    required String factory,
    required String floor,
  }) =>
      _remote.fetchRooms(customer: customer, factory: factory, floor: floor);

  @override
  Future<List<SensorDataResponse>> fetchSensorDataHistories({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  }) async {
    final List<SensorDataResponseModel> res = await _remote
        .fetchSensorDataHistories(
      customer: customer,
      factory: factory,
      floor: floor,
      room: room,
    );
    return res;
  }

  @override
  Future<List<SensorDataResponse>> fetchSensorDataOverview({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  }) async {
    final List<SensorDataResponseModel> res = await _remote.fetchSensorDataOverview(
      customer: customer,
      factory: factory,
      floor: floor,
      room: room,
    );
    return res;
  }

  @override
  Future<SensorOverview?> fetchSensorOverview({
    required String customer,
    required String factory,
    required String floor,
    required String room,
  }) =>
      _remote.fetchSensorOverview(
        customer: customer,
        factory: factory,
        floor: floor,
        room: room,
      );
}
