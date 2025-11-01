import '../entities/resistor_machine_entities.dart';

abstract class ResistorMachineRepository {
  Future<List<String>> getMachineNames();

  Future<ResistorMachineTrackingData> getTrackingData(
    ResistorMachineRequest request,
  );

  Future<List<ResistorMachineStatus>> getStatusData(
    ResistorMachineRequest request,
  );

  Future<ResistorMachineRecord?> getRecordById(int id);

  Future<ResistorMachineRecord?> getRecordBySerial(String serialNumber);

  Future<List<ResistorMachineSerialMatch>> searchSerialNumbers(
    String query, {
    int take = 12,
  });

  Future<List<ResistorMachineTestResult>> getTestResults(int id);
}
