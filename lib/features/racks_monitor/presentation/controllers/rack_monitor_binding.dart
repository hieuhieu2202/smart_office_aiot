import 'package:get/get.dart';

import '../../data/datasources/rack_monitor_remote_data_source.dart';
import '../../data/repositories/rack_monitor_repository_impl.dart';
import '../../domain/repositories/rack_monitor_repository.dart';
import '../../domain/usecases/get_rack_locations.dart';
import '../../domain/usecases/get_rack_monitoring_data.dart';
import '../controllers/rack_monitor_controller.dart';

/// Dependency injection binding for Rack Monitor feature
class RackMonitorBinding extends Bindings {
  final String? initialFactory;
  final String? initialFloor;
  final String? initialRoom;
  final String? initialGroup;
  final String? initialModel;
  final String? tag;

  RackMonitorBinding({
    this.initialFactory,
    this.initialFloor,
    this.initialRoom,
    this.initialGroup,
    this.initialModel,
    this.tag,
  });

  @override
  void dependencies() {
    // Data layer
    Get.lazyPut<RackMonitorRemoteDataSource>(
      () => RackMonitorRemoteDataSource(),
      tag: tag,
    );

    Get.lazyPut<RackMonitorRepository>(
      () => RackMonitorRepositoryImpl(
        remoteDataSource: Get.find<RackMonitorRemoteDataSource>(tag: tag),
      ),
      tag: tag,
    );

    // Domain layer (Use cases)
    Get.lazyPut<GetRackLocations>(
      () => GetRackLocations(Get.find<RackMonitorRepository>(tag: tag)),
      tag: tag,
    );

    Get.lazyPut<GetRackMonitoringData>(
      () => GetRackMonitoringData(Get.find<RackMonitorRepository>(tag: tag)),
      tag: tag,
    );

    // Presentation layer (Controller)
    Get.put<RackMonitorController>(
      RackMonitorController(
        getRackLocations: Get.find<GetRackLocations>(tag: tag),
        getRackMonitoringData: Get.find<GetRackMonitoringData>(tag: tag),
        initialFactory: initialFactory,
        initialFloor: initialFloor,
        initialRoom: initialRoom,
        initialGroup: initialGroup,
        initialModel: initialModel,
      ),
      tag: tag,
    );
  }
}

