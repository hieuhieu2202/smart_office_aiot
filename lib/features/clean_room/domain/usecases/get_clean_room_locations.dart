import '../repositories/clean_room_repository.dart';

class GetCustomersUseCase {
  const GetCustomersUseCase(this.repository);
  final CleanRoomRepository repository;
  Future<List<String>> call() => repository.fetchCustomers();
}

class GetFactoriesUseCase {
  const GetFactoriesUseCase(this.repository);
  final CleanRoomRepository repository;
  Future<List<String>> call(String customer) =>
      repository.fetchFactories(customer: customer);
}

class GetFloorsUseCase {
  const GetFloorsUseCase(this.repository);
  final CleanRoomRepository repository;
  Future<List<String>> call(String customer, String factory) =>
      repository.fetchFloors(customer: customer, factory: factory);
}

class GetRoomsUseCase {
  const GetRoomsUseCase(this.repository);
  final CleanRoomRepository repository;
  Future<List<String>> call(String customer, String factory, String floor) =>
      repository.fetchRooms(customer: customer, factory: factory, floor: floor);
}
