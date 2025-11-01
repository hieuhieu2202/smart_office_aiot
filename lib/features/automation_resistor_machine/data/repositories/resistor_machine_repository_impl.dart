import '../../domain/entities/resistor_machine_entities.dart';
import '../../domain/repositories/resistor_machine_repository.dart';
import '../datasources/resistor_machine_remote_data_source.dart';

class ResistorMachineRepositoryImpl implements ResistorMachineRepository {
  ResistorMachineRepositoryImpl({
    ResistorMachineRemoteDataSource? remoteDataSource,
  }) : _remote = remoteDataSource ?? ResistorMachineRemoteDataSource();

  final ResistorMachineRemoteDataSource _remote;

  @override
  Future<List<String>> getMachineNames() {
    return _remote.fetchMachineNames();
  }

  @override
  Future<ResistorMachineTrackingData> getTrackingData(
    ResistorMachineRequest request,
  ) {
    return _remote.fetchTrackingData(request);
  }

  @override
  Future<List<ResistorMachineStatus>> getStatusData(
    ResistorMachineRequest request,
  ) {
    return _remote.fetchStatusData(request);
  }

  @override
  Future<ResistorMachineRecord?> getRecordById(int id) {
    return _remote.fetchRecordById(id);
  }

  @override
  Future<ResistorMachineRecord?> getRecordBySerial(String serialNumber) {
    return _remote.fetchRecordBySerial(serialNumber);
  }

  @override
  Future<List<ResistorMachineSerialMatch>> searchSerialNumbers(
    String query, {
    int take = 12,
  }) {
    return _remote.searchSerialNumbers(query, take: take);
  }

  @override
  Future<List<ResistorMachineTestResult>> getTestResults(int id) {
    return _remote.fetchTestResults(id);
  }
}
