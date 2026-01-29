import '../entities/rack_entities.dart';

/// Repository interface for Rack Monitor data
/// This defines the contract that the data layer must implement
abstract class RackMonitorRepository {
  /// Get list of available locations for filtering
  Future<List<RackMonitorLocation>> getLocations();

  /// Get monitoring data based on filter criteria
  Future<RackMonitorData> getMonitoringData({
    required String factory,
    required String floor,
    required String room,
    required String group,
    required String model,
    String? nickName,
    String? dateRange,
  });

  /// Quick ping to check API availability
  Future<void> ping();

  /// Get available models for filtering
  Future<List<String>> getModels();
}

