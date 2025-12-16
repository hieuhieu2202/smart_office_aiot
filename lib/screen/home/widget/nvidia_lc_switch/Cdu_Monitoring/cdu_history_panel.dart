import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../../widget/animation/loading/eva_loading_view.dart';

class CduHistoryPanel extends StatelessWidget {
  final Map<String, dynamic>? history;
  final bool isLoading;
  final List<Map<String, dynamic>>? items;
  final bool isInitialLoading;
  final bool isRefreshing;

  const CduHistoryPanel({
    super.key,
    this.history,
    this.isLoading = false,
    this.items,
    this.isInitialLoading = false,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> list =
    (items != null) ? items! : _extractItems(history);

    final bool showBigSpinner = (items == null) ? isLoading : isInitialLoading;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: showBigSpinner
              ? const EvaLoadingView(size: 220)
              : (list.isEmpty
              ? const Center(child: Text('No history available'))
              : ListView.separated(
            key: const PageStorageKey('cdu-history-list'),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _HistoryTile(item: list[i]),
          )),
        ),

        // overlay cập nhật nhỏ (chỉ khi dùng cách mới và không phải lần đầu)
        if (items != null && !isInitialLoading && isRefreshing)
          Positioned(
            right: 14,
            top: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: EvaLoadingView(size: 140),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Ưu tiên kiểu JSON: { "Data": [ ... ] }
  List<Map<String, dynamic>> _extractItems(Map<String, dynamic>? root) {
    if (root == null) return const [];
    List<Map<String, dynamic>> list = const [];

    final data = root['Data'];
    if (data is List) {
      list = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      // Fallback các cấu trúc cũ hơn nếu có
      final candidates = [
        (root['Data'] is Map ? root['Data'] : null),
        (root['data'] is Map ? root['data'] : null),
        root,
      ];
      for (final c in candidates) {
        if (c is Map<String, dynamic>) {
          final v = c['Items'] ?? c['items'] ?? c['History'] ?? c['history'];
          if (v is List) {
            list = v.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            break;
          }
        }
      }
    }

    // ===== Sort theo yêu cầu:
    // - Nhóm theo ngày StartTime (YYYYMMDD) giảm dần
    // - Trong mỗi ngày: StartTime tăng dần
    int _startMs(Map<String, dynamic> m) {
      // Support both camelCase (new API) and PascalCase (old API)
      final raw = (m['startTime'] ?? m['StartTime'] ?? m['Starttime'] ?? m['Start'])?.toString() ?? '';
      final match = RegExp(r'\/Date\((\d+)\)\/').firstMatch(raw);
      if (match != null) {
        final g = match.group(1);
        final ms = g == null ? null : int.tryParse(g);
        if (ms != null) return ms;
      }
      return DateTime.tryParse(raw)?.millisecondsSinceEpoch ?? 0;
    }

    int _startYmd(Map<String, dynamic> m) {
      final ms = _startMs(m);
      if (ms == 0) return 0;
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return dt.year * 10000 + dt.month * 100 + dt.day; // ví dụ 20250911
    }

    int _cduOrder(Map<String, dynamic> m) {
      // Support both camelCase (new API) and PascalCase (old API)
      final id = (m['cduName'] ?? m['CDUName'] ?? m['Id'] ?? m['Name'] ?? '').toString();
      final mm = RegExp(r'(\d+)$').firstMatch(id);
      return mm != null ? int.tryParse(mm.group(1)!) ?? 0 : 0;
    }

    list.sort((a, b) {
      final dayCmp = _startYmd(b).compareTo(_startYmd(a)); // ngày DESC
      if (dayCmp != 0) return dayCmp;
      final timeCmp = _startMs(a).compareTo(_startMs(b));  // time ASC trong ngày
      if (timeCmp != 0) return timeCmp;
      return _cduOrder(a).compareTo(_cduOrder(b));         // ổn định
    });

    return list;
  }
}

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const _HistoryTile({required this.item});

  String _s(dynamic v) => v == null ? '' : v.toString();

  String _fmtDate(dynamic raw) {
    final s = _s(raw);
    if (s.isEmpty) return '-';

    final m = RegExp(r'\/Date\((\d+)\)\/').firstMatch(s);
    if (m != null) {
      final g = m.group(1);
      final ms = g == null ? null : int.tryParse(g);
      if (ms != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(ms);
        String two(int n) => n.toString().padLeft(2, '0');
        return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
            '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
      }
    }

    final dt = DateTime.tryParse(s);
    if (dt != null) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
          '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
    }
    return s;
  }

  /// - >=2: đỏ (abnormal)
  /// - 1: cam (đang warning)
  /// - 0: vàng (warning đã kết thúc)
  Color _severityColor() {
    final st = int.tryParse(_s(item['Status'])) ?? 0;
    if (st >= 2) return const Color(0xFFE53935); // red
    if (st == 1) return const Color(0xFFCD5607); // orange (web tone)
    return const Color(0xFFFFC107);              // yellow
  }

  @override
  Widget build(BuildContext context) {
    // Support both camelCase (new API) and PascalCase (old API)
    final id = _s(item['cduName'] ?? item['CDUName'] ?? item['Id'] ?? item['Name'] ?? 'Unknown');
    final host = _s(item['hostName'] ?? item['HostName'] ?? '');
    final ip = _s(item['ipAddress'] ?? item['IPAddress'] ?? '');
    final runStatus = _s(item['runStatus'] ?? item['RunStatus'] ?? '');
    final stInt = int.tryParse(_s(item['status'] ?? item['Status'])) ?? 0;

    const message = 'Warning about liquid storage.';

    final start = _fmtDate(item['startTime'] ?? item['StartTime'] ?? item['Starttime'] ?? item['Start']);
    final end   = (stInt == 1) ? 'is warning'
        : _fmtDate(item['endTime'] ?? item['EndTime'] ?? item['Endtime'] ?? item['End']);
    final total = _s(item['totalTime'] ?? item['TotalTime'] ?? item['Duration'] ?? '-');

    final barColor = _severityColor();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: barColor, width: 1.5), // viền theo màu
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: barColor.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dải màu trái
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
            // Nội dung
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // CDU + host
                    Row(
                      children: [
                        Text(
                          id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: barColor, // tiêu đề cùng màu
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (host.isNotEmpty)
                          Expanded(
                            child: Text(
                              host,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withOpacity(0.8),
                              ),
                            ),
                          ),
                      ],
                    ),

                    if (ip.isNotEmpty || runStatus.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          [ip, runStatus].where((e) => e.isNotEmpty).join('  •  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.6),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Thông điệp
                    const Text(
                      message,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),

                    const SizedBox(height: 8),

                    // Thời gian: 3 dòng như web
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _kv('Starttime:', start),
                        _kv('Endtime:', end),
                        _kv('Duration:', total),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(k, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              v.isEmpty ? '-' : v,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFeatures: [FontFeature.enable('tnum')]),
            ),
          ),
        ],
      ),
    );
  }
}
