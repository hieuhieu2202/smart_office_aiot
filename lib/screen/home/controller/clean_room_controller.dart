import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../service/clean_room_api.dart';

class CleanRoomController extends GetxController {
  final CleanRoomApi apiService = CleanRoomApi();

  // Danh sách từ API
  var customers = <String>[].obs;
  var factories = <String>[].obs;
  var floors = <String>[].obs;
  var rooms = <String>[].obs;

  // Giá trị được chọn
  var selectedCustomer = ''.obs;
  var selectedFactory = ''.obs;
  var selectedFloor = ''.obs;
  var selectedRoom = ''.obs;
  var selectedStartDate = DateTime.now().subtract(Duration(days: 1)).obs;
  var selectedEndDate = DateTime.now().obs;

  // Trạng thái panel lọc
  var showFilterPanel = false.obs;

  // Dữ liệu từ API
  var configData = <String, dynamic>{}.obs;
  var sensorOverview = {}.obs;
  var sensorData = <Map<String, dynamic>>[].obs;
  var sensorHistories = <Map<String, dynamic>>[].obs;
  var sensorDataList = <Map<String, dynamic>>[].obs;
  var areaData = {}.obs;
  var barData = {}.obs;
  var roomImage = Rxn<ImageProvider>();

  @override
  void onInit() {
    super.onInit();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    try {
      customers.value = await CleanRoomApi.getCustomers();
      if (customers.isNotEmpty) {
        selectedCustomer.value = customers[0];
        fetchFactories();
      }
    } catch (e) {
      print('[ERROR] Fetch customers: $e');
    }
  }

  Future<void> fetchFactories() async {
    try {
      factories.value = await CleanRoomApi.getFactories(selectedCustomer.value);
      if (factories.isNotEmpty) {
        selectedFactory.value = factories[0];
        fetchFloors();
      } else {
        floors.clear();
        rooms.clear();
        selectedFactory.value = '';
        selectedFloor.value = '';
        selectedRoom.value = '';
      }
    } catch (e) {
      print('[ERROR] Fetch factories: $e');
    }
  }

  Future<void> fetchFloors() async {
    try {
      floors.value = await CleanRoomApi.getFloors(selectedCustomer.value, selectedFactory.value);
      if (floors.isNotEmpty) {
        selectedFloor.value = floors[0];
        fetchRooms();
      } else {
        rooms.clear();
        selectedFloor.value = '';
        selectedRoom.value = '';
      }
    } catch (e) {
      print('[ERROR] Fetch floors: $e');
    }
  }

  Future<void> fetchRooms() async {
    try {
      rooms.value = await CleanRoomApi.getRooms(selectedCustomer.value, selectedFactory.value, selectedFloor.value);
      if (rooms.isNotEmpty) {
        selectedRoom.value = rooms[0];
        fetchData();
      } else {
        selectedRoom.value = '';
      }
    } catch (e) {
      print('[ERROR] Fetch rooms: $e');
    }
  }

  Future<void> fetchData() async {
    if (selectedCustomer.isEmpty || selectedFactory.isEmpty || selectedFloor.isEmpty || selectedRoom.isEmpty) {
      return;
    }
    try {
      final format = DateFormat('yyyy-MM-dd HH:mm');
      final DateTime endTime = selectedEndDate.value;
      final DateTime startTime = selectedStartDate.value;
      final thirtyMinutesAgo = endTime.subtract(const Duration(minutes: 30));
      final twelveHoursAgo = endTime.subtract(const Duration(hours: 12));

      final rangeDateTime = '${format.format(startTime)} - ${format.format(endTime)}';
      final range30Minutes = '${format.format(thirtyMinutesAgo)} - ${format.format(endTime)}';
      final range12Hours = '${format.format(twelveHoursAgo)} - ${format.format(endTime)}';

      var params = {
        'customer': selectedCustomer.value,
        'factory': selectedFactory.value,
        'floor': selectedFloor.value,
        'room': selectedRoom.value,
        'rangeDateTime': rangeDateTime,
        'range30Minutes': range30Minutes,
        'range12Hours': range12Hours,
      };

      configData.value = await CleanRoomApi.getConfigMapping(
        customer: params['customer']!,
        factory: params['factory']!,
        floor: params['floor']!,
        room: params['room']!,
      );
      sensorOverview.value = await CleanRoomApi.getSensorOverview(
        customer: params['customer']!,
        factory: params['factory']!,
        floor: params['floor']!,
        room: params['room']!,
        rangeDateTime: params['range30Minutes']!,
      );
      sensorData.value = await CleanRoomApi.getSensorDataOverview(
        customer: params['customer']!,
        factory: params['factory']!,
        floor: params['floor']!,
        room: params['room']!,
        rangeDateTime: params['range30Minutes']!,
      );
      sensorHistories.value = await CleanRoomApi.getSensorDataHistories(
        customer: params['customer']!,
        factory: params['factory']!,
        floor: params['floor']!,
        room: params['room']!,
        rangeDateTime: params['range12Hours']!,
      );
      sensorDataList.value = await CleanRoomApi.getSensorData(
        customer: params['customer']!,
        factory: params['factory']!,
        floor: params['floor']!,
        room: params['room']!,
        rangeDateTime: params['rangeDateTime']!,
      );
      areaData.value = await CleanRoomApi.getAreaData(
        customer: params['customer']!,
        factory: params['factory']!,
        floor: params['floor']!,
        room: params['room']!,
        rangeDateTime: params['rangeDateTime']!,
      );
      barData.value = await CleanRoomApi.getBarData(
        customer: params['customer']!,
        factory: params['factory']!,
        floor: params['floor']!,
        room: params['room']!,
        rangeDateTime: params['rangeDateTime']!,
      );
      roomImage.value = await CleanRoomApi.fetchRoomImage(
        customer: params['customer']!,
        factory: params['factory']!,
        floor: params['floor']!,
        room: params['room']!,
      );
    } catch (e) {
      print('[ERROR] Fetch data: $e');
    }
  }

  void toggleFilterPanel() {
    showFilterPanel.value = !showFilterPanel.value;
  }

  void applyFilter(DateTime start, DateTime end, String? customer, String? factory, String? floor, String? room) {
    selectedStartDate.value = start;
    selectedEndDate.value = end;
    if (customer != null) selectedCustomer.value = customer;
    if (factory != null) selectedFactory.value = factory;
    if (floor != null) selectedFloor.value = floor;
    if (room != null) selectedRoom.value = room;
    fetchData();
    showFilterPanel.value = false;
  }
}