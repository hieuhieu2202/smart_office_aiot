import '../entities/rack_entities.dart';
import '../repositories/rack_monitor_repository.dart';

/// Use case for fetching available locations
class GetRackLocations {
  final RackMonitorRepository repository;

  GetRackLocations(this.repository);

  Future<List<RackMonitorLocation>> call() async {
    return await repository.getLocations();
  }
}

