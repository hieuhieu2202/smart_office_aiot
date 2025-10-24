import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../../../../service/http_helper.dart';
import '../../domain/entities/kanban_entities.dart';
import '../models/detail_models.dart';
import '../models/output_tracking_model.dart';
import '../models/uph_tracking_model.dart';

class NvidiaKanbanLogger {
  NvidiaKanbanLogger._();

  static void net(String Function() _) {}
}

class NvidiaKanbanRemoteDataSource {
  NvidiaKanbanRemoteDataSource({HttpHelper? httpHelper})
      : _http = httpHelper ?? HttpHelper();

  final HttpHelper _http;

  static const String _base =
      'https://10.220.130.117/newweb/api/nvidia/kanban';
  static const Duration _timeout = Duration(seconds: 45);

  Future<List<String>> fetchGroups({required KanbanRequest request}) async {
    final uri = Uri.parse('$_base/Sfis/GetGroupsByShift');
    final body = request.copyWith(
      date: request.date.replaceAll('-', ''),
      groups: const <String>[],
    ).toBody();

    NvidiaKanbanLogger.net(() => '[NvidiaKanban] POST $uri');
    NvidiaKanbanLogger.net(() => '[NvidiaKanban] body => ${_safeBody(body)}');

    final http.Response res = await _http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
      timeout: _timeout,
    );
    _ensure200(res, 'GetGroupsByShift');
    return _parseStringList(res.body);
  }

  Future<OutputTrackingModel> fetchOutputTracking({
    required KanbanRequest request,
  }) async {
    final uri = Uri.parse('$_base/OutputTracking/GetOutputTrackingData');
    final body = request.toBody();

    NvidiaKanbanLogger.net(() => '[NvidiaKanban] POST $uri');
    NvidiaKanbanLogger.net(() => '[NvidiaKanban] body => ${_safeBody(body)}');

    final http.Response res = await _http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
      timeout: _timeout,
    );
    _ensure200(res, 'GetOutputTrackingData');

    final dynamic data = jsonDecode(res.body);
    if (data is Map<String, dynamic>) {
      return OutputTrackingModel.fromJson(data);
    }
    throw Exception('GetOutputTrackingData: invalid payload');
  }

  Future<UphTrackingModel> fetchUphTracking({
    required KanbanRequest request,
  }) async {
    final uri = Uri.parse('$_base/UphTracking/GetUphTrackingData');
    final body = request.toBody();

    NvidiaKanbanLogger.net(() => '[NvidiaKanban] POST $uri');
    NvidiaKanbanLogger.net(() => '[NvidiaKanban] body => ${_safeBody(body)}');

    final http.Response res = await _http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
      timeout: _timeout,
    );
    _ensure200(res, 'GetUphTrackingData');

    final dynamic data = jsonDecode(res.body);
    if (data is Map<String, dynamic>) {
      return UphTrackingModel.fromJson(data);
    }
    throw Exception('GetUphTrackingData: invalid payload');
  }

  Future<OutputTrackingDetailModel> fetchOutputTrackingDetail({
    required OutputTrackingDetailParams params,
  }) async {
    final sanitizedGroups = params.groups
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (sanitizedGroups.isEmpty) {
      throw Exception('GetOutputTrackingDataDetail: groups is empty');
    }

    final uri = Uri.parse('$_base/OutputTracking/GetOutputTrackingDataDetail');
    final body = <String, dynamic>{
      'modelSerial': params.modelSerial,
      'date': params.date,
      'shift': params.shift,
      'groups': sanitizedGroups,
      'section': params.section,
      'station': params.station,
      'dateRange': 'string',
      'line': 'string',
      'customer': 'string',
      'nickName': 'string',
      'modelName': 'string',
    };

    NvidiaKanbanLogger.net(() => '[NvidiaKanban] POST $uri');
    NvidiaKanbanLogger.net(() {
      final previewCount = math.min(5, sanitizedGroups.length);
      final preview = sanitizedGroups.take(previewCount).join(', ');
      return '[NvidiaKanban] body => ${_safeBody(body)} | groups='
          '${sanitizedGroups.length} | sample=[$preview]';
    });

    final http.Response res = await _http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
      timeout: _timeout,
    );
    _ensure200(res, 'GetOutputTrackingDataDetail');

    final dynamic data = jsonDecode(res.body);
    final detail = OutputTrackingDetailModel.fromAny(data);
    NvidiaKanbanLogger.net(() {
      final errSample = detail.errorDetails
          .take(5)
          .map((e) => '${e.code}:${e.failQty}')
          .join(', ');
      final testerSample = detail.testerDetails
          .take(5)
          .map((e) => '${e.stationName}:${e.failQty}')
          .join(', ');
      return '[NvidiaKanban] detail response -> errors='
          '${detail.errorDetails.length} testers=${detail.testerDetails.length} '
          '| errorSample=[$errSample] | testerSample=[$testerSample]';
    });
    return detail;
  }

  Map<String, String> _headers() => const <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
      };
}

void _ensure200(http.Response res, String apiName) {
  if (res.statusCode != 200) {
    throw Exception('$apiName failed: ${res.statusCode} ${res.body}');
  }
}

List<String> _parseStringList(String body) {
  final dynamic raw = jsonDecode(body);
  final out = <String>[];
  if (raw is List) {
    for (final dynamic e in raw) {
      final value = e.toString().trim();
      if (value.isNotEmpty) out.add(value);
    }
  } else if (raw is Map && raw['data'] is List) {
    for (final dynamic e in (raw['data'] as List)) {
      final value = e.toString().trim();
      if (value.isNotEmpty) out.add(value);
    }
  }
  final uniq = out.toSet().toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  NvidiaKanbanLogger.net(
    () => '[NvidiaKanban] GetGroupsByShift OK -> ${uniq.length} items',
  );
  return uniq;
}

String _safeBody(Map<String, dynamic> body) {
  final preview = <String, dynamic>{};

  String truncate(String value, {int max = 160}) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}…';
  }

  body.forEach((key, value) {
    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('token')) return;

    if (value is List) {
      final sample = value.take(5).map((e) => e.toString()).toList();
      final suffix = value.length > sample.length ? ', …' : '';
      preview[key] = '[${value.length} items] ${sample.join(', ')}$suffix';
      return;
    }

    if (value is String) {
      preview[key] = truncate(value);
      return;
    }

    preview[key] = value;
  });

  return preview.toString();
}
