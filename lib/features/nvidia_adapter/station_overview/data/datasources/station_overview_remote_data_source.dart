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
    final Map<String, dynamic> payload = <String, dynamic>{
      'MODEL_SERIAL': modelSerial,
    };
    final http.Response res = await _http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode(payload),
          timeout: _timeout,
        )
        .catchError((error) => throw Exception('GetSfcProductAndModelNames: $error'));

    _ensureSuccess(res, 'GetSfcProductAndModelNames');

    final dynamic decoded = jsonDecode(res.body);
    if (decoded is List) {
      final Iterable<Map<String, dynamic>> items = decoded
          .where((element) => element is Map<String, dynamic>)
          .cast<Map<String, dynamic>>();
      return items.map(StationProductModel.fromJson).toList();
    }

    throw Exception('GetSfcProductAndModelNames: unexpected payload');
  }

  Future<List<StationOverviewData>> fetchOverview({
    required StationOverviewFilter filter,
  }) async {
    final uri = Uri.parse('$_base/GetStationOverviewDatas');
    final Map<String, dynamic> payload = <String, dynamic>{
      'DateRange': (filter.dateRange == null || filter.dateRange!.isEmpty)
          ? ''
          : filter.dateRange!,
      'MODEL_SERIAL': filter.modelSerial,
      'PRODUCT_NAME':
          (filter.productName == null || filter.productName!.isEmpty)
              ? 'ALL'
              : filter.productName!,
      'MODEL_NAME': (filter.modelName == null || filter.modelName!.isEmpty)
          ? 'ALL'
          : filter.modelName!,
      'GROUP_NAMES': filter.groupNames,
    };
    final http.Response res = await _http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode(payload),
          timeout: _timeout,
        )
        .catchError((error) => throw Exception('GetStationOverviewDatas: $error'));

    _ensureSuccess(res, 'GetStationOverviewDatas');

    final dynamic decoded = jsonDecode(res.body);
    if (decoded is List) {
      final Iterable<Map<String, dynamic>> items = decoded
          .where((element) => element is Map<String, dynamic>)
          .cast<Map<String, dynamic>>();
      return items.map(StationOverviewDataModel.fromJson).toList();
    }

    throw Exception('GetStationOverviewDatas: unexpected payload');
  }

  Future<List<StationAnalysisData>> fetchStationAnalysis({
    required StationOverviewFilter filter,
  }) async {
    final uri = Uri.parse('$_base/GetStationAnalysisDatas');
    final Map<String, dynamic> payload = <String, dynamic>{
      'DateRange': (filter.dateRange == null || filter.dateRange!.isEmpty)
          ? ''
          : filter.dateRange!,
      'MODEL_SERIAL': filter.modelSerial,
      'PRODUCT_NAME': filter.productName ?? '',
      'GROUP_NAMES': filter.groupNames,
      'STATION_NAME': filter.stationName ?? '',
    };
    final http.Response res = await _http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode(payload),
          timeout: _timeout,
        )
        .catchError((error) => throw Exception('GetStationAnalysisDatas: $error'));

    _ensureSuccess(res, 'GetStationAnalysisDatas');

    final dynamic decoded = jsonDecode(res.body);
    if (decoded is List) {
      final Iterable<Map<String, dynamic>> items = decoded
          .where((element) => element is Map<String, dynamic>)
          .cast<Map<String, dynamic>>();
      return items.map(StationAnalysisDataModel.fromJson).toList();
    }

    throw Exception('GetStationAnalysisDatas: unexpected payload');
  }

  Future<List<StationDetailData>> fetchStationDetails({
    required StationOverviewFilter filter,
  }) async {
    final uri = Uri.parse('$_base/GetStationDetailDatas');
    final Map<String, dynamic> payload = <String, dynamic>{
      'DateRange': (filter.dateRange == null || filter.dateRange!.isEmpty)
          ? ''
          : filter.dateRange!,
      'MODEL_SERIAL': filter.modelSerial,
      'PRODUCT_NAME': filter.productName ?? '',
      'GROUP_NAMES': filter.groupNames,
      'STATION_NAME': filter.stationName ?? '',
    };
    if (filter.detailType != null) {
      payload['DETAIL_TYPE'] = filter.detailType!.apiKey;
    }
    final http.Response res = await _http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode(payload),
          timeout: _timeout,
        )
        .catchError((error) => throw Exception('GetStationDetailDatas: $error'));

    _ensureSuccess(res, 'GetStationDetailDatas');

    final dynamic decoded = jsonDecode(res.body);
    if (decoded is List) {
      final Iterable<Map<String, dynamic>> items = decoded
          .where((element) => element is Map<String, dynamic>)
          .cast<Map<String, dynamic>>();
      return items.map(StationDetailDataModel.fromJson).toList();
    }

    throw Exception('GetStationDetailDatas: unexpected payload');
  }

  void _ensureSuccess(http.Response res, String endpoint) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$endpoint failed (${res.statusCode}): ${res.body}');
    }
  }
}
