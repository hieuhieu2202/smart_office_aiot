import 'dart:convert';

import 'package:get/get.dart';

import '../../data/models/clean_room_config_model.dart';
import '../../domain/entities/clean_room_config.dart';
import '../../domain/entities/sensor_data.dart';
import '../../domain/entities/sensor_overview.dart';
import '../../domain/repositories/clean_room_repository.dart';
import '../../domain/usecases/get_clean_room_locations.dart';
import '../../domain/usecases/get_clean_room_overview.dart';
import '../../data/repositories/clean_room_repository_impl.dart';

class CleanRoomController extends GetxController {
  CleanRoomController({CleanRoomRepository? repository})
      : repository = repository ?? CleanRoomRepositoryImpl() {
    final repo = this.repository;
    getCustomers = GetCustomersUseCase(repo);
    getFactories = GetFactoriesUseCase(repo);
    getFloors = GetFloorsUseCase(repo);
    getRooms = GetRoomsUseCase(repo);
    getConfig = GetConfigMappingUseCase(repo);
    getSensorOverview = GetSensorOverviewUseCase(repo);
    getSensorDataOverview = GetSensorDataOverviewUseCase(repo);
    getSensorDataHistories = GetSensorDataHistoriesUseCase(repo);
  }

  final CleanRoomRepository repository;
  late final GetCustomersUseCase getCustomers;
  late final GetFactoriesUseCase getFactories;
  late final GetFloorsUseCase getFloors;
  late final GetRoomsUseCase getRooms;
  late final GetConfigMappingUseCase getConfig;
  late final GetSensorOverviewUseCase getSensorOverview;
  late final GetSensorDataOverviewUseCase getSensorDataOverview;
  late final GetSensorDataHistoriesUseCase getSensorDataHistories;

  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxnString error = RxnString();

  final RxList<String> customers = <String>[].obs;
  final RxList<String> factories = <String>[].obs;
  final RxList<String> floors = <String>[].obs;
  final RxList<String> rooms = <String>[].obs;

  final RxString selectedCustomer = 'NVIDIA'.obs;
  final RxString selectedFactory = ''.obs;
  final RxString selectedFloor = ''.obs;
  final RxString selectedRoom = ''.obs;

  final Rxn<CleanRoomConfig> configMapping = Rxn<CleanRoomConfig>();
  final Rxn<SensorOverview> sensorOverview = Rxn<SensorOverview>();
  final RxList<SensorDataResponse> sensorOverviewData = <SensorDataResponse>[].obs;
  final RxList<SensorDataResponse> sensorHistories = <SensorDataResponse>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    isLoading.value = true;
    error.value = null;
    try {
      customers.assignAll(await getCustomers());
      if (customers.isNotEmpty && !customers.contains(selectedCustomer.value)) {
        selectedCustomer.value = customers.first;
      }

      await _loadFactories();
      await _loadFloors();
      await _loadRooms();
      await refreshData();
    } catch (err) {
      error.value = err.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    isRefreshing.value = true;
    error.value = null;
    try {
      await Future.wait([
        _loadConfig(),
        _loadSensorOverview(),
        _loadOverviewData(),
        _loadHistories(),
      ]);
    } catch (err) {
      error.value = err.toString();
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> onCustomerChanged(String value) async {
    selectedCustomer.value = value;
    await _loadFactories();
    await _loadFloors();
    await _loadRooms();
    await refreshData();
  }

  Future<void> onFactoryChanged(String value) async {
    selectedFactory.value = value;
    await _loadFloors();
    await _loadRooms();
    await refreshData();
  }

  Future<void> onFloorChanged(String value) async {
    selectedFloor.value = value;
    await _loadRooms();
    await refreshData();
  }

  Future<void> onRoomChanged(String value) async {
    selectedRoom.value = value;
    await refreshData();
  }

  Future<void> _loadFactories() async {
    final list = await getFactories(selectedCustomer.value);
    factories.assignAll(list);
    if (list.isNotEmpty) {
      selectedFactory.value = list.contains(selectedFactory.value)
          ? selectedFactory.value
          : list.first;
    }
  }

  Future<void> _loadFloors() async {
    final list = await getFloors(selectedCustomer.value, selectedFactory.value);
    floors.assignAll(list);
    if (list.isNotEmpty) {
      selectedFloor.value = list.contains(selectedFloor.value)
          ? selectedFloor.value
          : list.first;
    }
  }

  Future<void> _loadRooms() async {
    final list = await getRooms(
      selectedCustomer.value,
      selectedFactory.value,
      selectedFloor.value,
    );
    rooms.assignAll(list);
    if (list.isNotEmpty) {
      selectedRoom.value = list.contains(selectedRoom.value)
          ? selectedRoom.value
          : list.first;
    }
  }

  Future<void> _loadConfig() async {
    configMapping.value = await getConfig(
      customer: selectedCustomer.value,
      factory: selectedFactory.value,
      floor: selectedFloor.value,
      room: selectedRoom.value,
    );
  }

  Future<void> _loadSensorOverview() async {
    sensorOverview.value = await getSensorOverview(
      customer: selectedCustomer.value,
      factory: selectedFactory.value,
      floor: selectedFloor.value,
      room: selectedRoom.value,
    );
  }

  Future<void> _loadOverviewData() async {
    final data = await getSensorDataOverview(
      customer: selectedCustomer.value,
      factory: selectedFactory.value,
      floor: selectedFloor.value,
      room: selectedRoom.value,
    );
    sensorOverviewData.assignAll(data);
  }

  Future<void> _loadHistories() async {
    final data = await getSensorDataHistories(
      customer: selectedCustomer.value,
      factory: selectedFactory.value,
      floor: selectedFloor.value,
      room: selectedRoom.value,
    );
    sensorHistories.assignAll(data);
  }

  List<PositionMapping> parsePositions() {
    final raw = configMapping.value?.data;
    if (raw == null || raw.isEmpty) return const <PositionMapping>[];
    try {
      final List<dynamic> decodedList = _decodePositions(raw);
      return decodedList
          .whereType<Map<String, dynamic>>()
          .map(PositionMappingModel.fromJson)
          .where((element) => element.sensorName.isNotEmpty)
          .toList();
    } catch (_) {
      return const <PositionMapping>[];
    }
  }

  List<dynamic> _decodePositions(String raw) {
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
    } catch (_) {
      // try base64 encoded JSON string
      try {
        final payload = utf8.decode(base64Decode(raw));
        final dynamic decoded = jsonDecode(payload);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return const <dynamic>[];
  }

  String statusFor(SensorDataResponse data) {
    if (data.data.any((p) => p.result.toUpperCase() == 'OFFLINE')) return 'OFFLINE';
    if (data.data.any((p) => p.result.toUpperCase() == 'WARNING')) return 'WARNING';
    return 'ONLINE';
  }
}
