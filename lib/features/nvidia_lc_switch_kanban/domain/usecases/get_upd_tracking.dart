import '../entities/kanban_entities.dart';
import '../repositories/nvidia_kanban_repository.dart';

class GetUpdTracking {
  const GetUpdTracking(this._repo);

  final NvidiaKanbanRepository _repo;

  Future<UpdTrackingEntity> call(KanbanRequest request) {
    return _repo.fetchUpdTracking(request);
  }
}
