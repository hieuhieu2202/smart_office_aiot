import '../entities/te_report.dart';
import '../entities/te_retest_rate.dart';
import '../entities/te_top_error.dart';
import '../entities/te_yield_rate.dart';

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

  Future<TEYieldDetailEntity> fetchYieldRateReport({
    required String modelSerial,
    required String range,
    String model,
  });

  Future<List<TETopErrorEntity>> fetchTopErrorCodes({
    required String modelSerial,
    required String range,
    String type,
  });

  Future<List<TETopErrorTrendPointEntity>> fetchTopErrorTrendByErrorCode({
    required String modelSerial,
    required String range,
    required String errorCode,
    String type,
  });

  Future<List<TETopErrorTrendPointEntity>> fetchTopErrorTrendByModelStation({
    required String range,
    required String errorCode,
    required String model,
    required String station,
  });
}
