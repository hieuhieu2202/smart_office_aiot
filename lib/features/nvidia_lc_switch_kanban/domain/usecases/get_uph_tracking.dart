import '../entities/kanban_entities.dart';
import '../repositories/nvidia_kanban_repository.dart';

class GetUphTracking {
  GetUphTracking(this._repository);

  final NvidiaKanbanRepository _repository;

  Future<UphTrackingEntity> call(KanbanRequest request) {
    return _repository.fetchUphTracking(request);
  }
}
