import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth/auth_config.dart';
import '../model/smt/stencil_detail.dart';

class StencilMonitorApi {
  static const String _url =
      'https://10.220.130.117/newweb/api/smt/dashboard/StencilMonitor';

  static Future<List<StencilDetail>> fetchStencilDetails() async {
    final stopwatch = Stopwatch()..start();
    print('>> [StencilMonitorApi] GET $_url');

    final res = await http.get(
      Uri.parse(_url),
      headers: AuthConfig.getAuthorizedHeaders(),
    );
    stopwatch.stop();

    print(
      '>> [StencilMonitorApi] Response status=${res.statusCode} ''elapsed=${stopwatch.elapsedMilliseconds}ms length=${res.body.length}',
    );

    if (res.statusCode == 200) {
      if (res.body.isEmpty) return const [];
      final List<dynamic> raw = json.decode(res.body) as List<dynamic>;
      return raw
          .whereType<Map<String, dynamic>>()
          .map(StencilDetail.fromJson)
          .toList(growable: false);
    }

    if (res.statusCode == 204) {
      return const [];
    }

    throw Exception(
      'Failed to load stencil monitor data (${res.statusCode})',
    );
  }
}
