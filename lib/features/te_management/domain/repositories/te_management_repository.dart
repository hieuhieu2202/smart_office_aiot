import '../entities/te_report.dart';

abstract class TEManagementRepository {
  Future<List<TEReportGroupEntity>> fetchReport({
    required String modelSerial,
    required String range,
    String model,
  });

  Future<List<String>> fetchModelNames({required String modelSerial});

  Future<TEErrorDetailEntity?> fetchErrorDetail({
    required String range,
    required String model,
    required String group,
  });
}
