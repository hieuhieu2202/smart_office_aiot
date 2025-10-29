import '../entities/te_report.dart';
import '../entities/te_retest_rate.dart';

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

  Future<TEErrorDetailEntity?> fetchRetestRateErrorDetail({
    required String date,
    required String shift,
    required String model,
    required String group,
  });

  Future<TERetestDetailEntity> fetchRetestRateReport({
    required String modelSerial,
    required String range,
    String model,
  });
}
