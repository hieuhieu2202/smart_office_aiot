import '../../domain/entities/rack_entities.dart';
import '../../domain/repositories/rack_monitor_repository.dart';
import '../datasources/rack_monitor_remote_data_source.dart';

/// Implementation of RackMonitorRepository
/// This bridges the domain layer with the data layer
class RackMonitorRepositoryImpl implements RackMonitorRepository {
  final RackMonitorRemoteDataSource remoteDataSource;

  RackMonitorRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<RackMonitorLocation>> getLocations() async {
    return await remoteDataSource.getLocations();
  }

  @override
  Future<RackMonitorData> getMonitoringData({
    required String factory,
    required String floor,
    required String room,
    required String group,
    required String model,
    String? nickName,
    String? dateRange,
  }) async {
    // Generate dateRange if not provided (current day 7:30 - 19:30)
    if (dateRange == null || dateRange.isEmpty) {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      dateRange = '$dateStr 07:30 - $dateStr 19:30';
    }

    // Get all available models to send if "ALL" is selected
    List<String> productNames;

    if (model == 'ALL' || model.isEmpty) {
      // Get all models from locations matching the filters
      try {
        final locations = await remoteDataSource.getLocations();
        final modelSet = locations
            .where((loc) =>
                (factory.isEmpty || factory == 'ALL' || loc.factory == factory) &&
                (floor.isEmpty || floor == 'ALL' || loc.floor == floor) &&
                (room == 'ALL' || room == 'N/A' || loc.room == room || loc.room == 'N/A') &&
                (group.isEmpty || group == 'ALL' || loc.group == group))
            .map((loc) => loc.model)
            .where((m) => m.isNotEmpty)
            .toSet();
        productNames = modelSet.toList();

        // If still empty after filtering, get all available products
        if (productNames.isEmpty) {
          productNames = locations
              .map((loc) => loc.model)
              .where((m) => m.isNotEmpty)
              .toSet()
              .toList();
        }
      } catch (e) {
        print('[RackMonitor] Failed to fetch locations: $e');
        productNames = [];
      }
    } else {
      productNames = [model];
    }

    final body = {
      'factory': factory.isEmpty ? 'ALL' : factory,
      'floor': floor.isEmpty ? 'ALL' : floor,
      'room': room.isEmpty || room == 'ALL' ? 'ALL' : room,
      'productNames': productNames,
      'productName': '', // Empty string as per API spec
      'groupName': group.isEmpty ? 'ALL' : group,
      'dateRange': dateRange,
      'detailType': '', // Empty string as per API spec
      'slotName': '', // Empty string as per API spec
    };

    print('[RackMonitor] Request body: $body');

    return await remoteDataSource.getMonitoringData(body: body);
  }

  @override
  Future<void> ping() async {
    await remoteDataSource.ping();
  }

  @override
  Future<List<String>> getModels() async {
    return await remoteDataSource.getModels();
  }
}

