import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../service/http_helper.dart';
import '../../domain/entities/station_overview_entities.dart';
import '../models/station_overview_models.dart';

class StationOverviewRemoteDataSource {
  StationOverviewRemoteDataSource({HttpHelper? httpHelper})
      : _http = httpHelper ?? HttpHelper();

  final HttpHelper _http;

  static const String _base =
      'https://10.220.130.117/newweb/api/nvidia/dashboard/StationOverview';
  static const Duration _timeout = Duration(seconds: 40);

  Map<String, String> _headers() {
    return const <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<List<StationProduct>> fetchProducts({
    required String modelSerial,
  }) async {
    final uri = Uri.parse('$_base/GetSfcProductAndModelNames');
    final http.Response res = await _http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode(<String, dynamic>{'MODEL_SERIAL': modelSerial}),
          timeout: _timeout,
        )
        .catchError((error) => throw Exception('GetSfcProductAndModelNames: $error'));

    _ensureSuccess(res, 'GetSfcProductAndModelNames');

    final dynamic body = jsonDecode(res.body);
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(StationProductModel.fromJson)
          .toList();
    }

    throw Exception('GetSfcProductAndModelNames: unexpected payload');
  }

  Future<List<StationOverviewData>> fetchOverview({
    required StationOverviewFilter filter,
  }) async {
    final uri = Uri.parse('$_base/GetStationOverviewDatas');
    final http.Response res = await _http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode(filter.toBody()),
          timeout: _timeout,
        )
        .catchError((error) => throw Exception('GetStationOverviewDatas: $error'));

    _ensureSuccess(res, 'GetStationOverviewDatas');

    final dynamic body = jsonDecode(res.body);
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(StationOverviewDataModel.fromJson)
          .toList();
    }

    throw Exception('GetStationOverviewDatas: unexpected payload');
  }

  Future<List<StationAnalysisData>> fetchStationAnalysis({
    required StationOverviewFilter filter,
  }) async {
    final uri = Uri.parse('$_base/GetStationAnalysisDatas');
    final http.Response res = await _http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode(filter.toBody()),
          timeout: _timeout,
        )
        .catchError((error) => throw Exception('GetStationAnalysisDatas: $error'));

    _ensureSuccess(res, 'GetStationAnalysisDatas');

    final dynamic body = jsonDecode(res.body);
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(StationAnalysisDataModel.fromJson)
          .toList();
    }

    throw Exception('GetStationAnalysisDatas: unexpected payload');
  }

  Future<List<StationDetailData>> fetchStationDetails({
    required StationOverviewFilter filter,
  }) async {
    final uri = Uri.parse('$_base/GetStationDetailDatas');
    final http.Response res = await _http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode(filter.toBody()),
          timeout: _timeout,
        )
        .catchError((error) => throw Exception('GetStationDetailDatas: $error'));

    _ensureSuccess(res, 'GetStationDetailDatas');

    final dynamic body = jsonDecode(res.body);
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(StationDetailDataModel.fromJson)
          .toList();
    }

    throw Exception('GetStationDetailDatas: unexpected payload');
  }

  void _ensureSuccess(http.Response res, String endpoint) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$endpoint failed (${res.statusCode}): ${res.body}');
    }
  }
}
