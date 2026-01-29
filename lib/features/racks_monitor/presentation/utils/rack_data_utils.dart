import '../../domain/entities/rack_entities.dart';

/// Utility class for processing rack monitor data
class RackDataUtils {
  RackDataUtils._();

  static final RegExp _saRe =
      RegExp(r'(SA0+\d+|SA\d{6,})', caseSensitive: false);

  /// Extract SA code from model name
  static String extractSA(String? s) {
    if (s == null) return '';
    final m = _saRe.firstMatch(s);
    return (m?.group(0) ?? '').toUpperCase();
  }

  /// Check if two codes differ by at most one character
  static bool diffAtMostOneChar(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        diff++;
        if (diff > 1) return false;
      }
    }
    return diff == 1;
  }

  /// Aggregate model pass data from model details or rack details
  static List<ModelPassSummary> aggregateModelPass(
    List<ModelDetail> directModels,
    List<RackDetail> racks,
  ) {
    // If we have direct model details, use those
    if (directModels.isNotEmpty) {
      final byModel = <String, _Agg>{};
      for (final detail in directModels) {
        final raw = detail.modelName.trim();
        if (raw.isEmpty) continue;
        final sa = extractSA(raw);
        final model = sa.isNotEmpty ? sa : raw.toUpperCase();
        final pass = detail.pass != 0 ? detail.pass : detail.totalPass;
        final total = detail.totalPass != 0 ? detail.totalPass : pass;
        final bucket = byModel.putIfAbsent(model, () => _Agg());
        bucket.pass += pass;
        bucket.totalPass += total;
      }

      return byModel.entries
          .map((e) => ModelPassSummary(
                model: e.key,
                pass: e.value.pass,
                totalPass: e.value.totalPass,
              ))
          .toList()
        ..sort((a, b) => b.totalPass.compareTo(a.totalPass));
    }

    // Otherwise aggregate from rack details
    final agg = <String, _Agg>{};
    final rackSAs = <String>{};

    for (final r in racks) {
      final rackSA = extractSA(r.modelName);
      if (rackSA.isNotEmpty) rackSAs.add(rackSA);

      if (r.slotDetails.isEmpty) {
        if (rackSA.isEmpty) continue;
        final a = agg.putIfAbsent(rackSA, () => _Agg());
        a.pass += r.pass;
        a.totalPass += r.totalPass;
        continue;
      }

      for (final s in r.slotDetails) {
        String slotSA = extractSA(s.modelName);

        if (slotSA.isEmpty && rackSA.isNotEmpty) slotSA = rackSA;

        if (slotSA.isNotEmpty &&
            rackSA.isNotEmpty &&
            slotSA != rackSA &&
            diffAtMostOneChar(slotSA, rackSA)) {
          slotSA = rackSA;
        }

        if (slotSA.isEmpty) continue;

        final a = agg.putIfAbsent(slotSA, () => _Agg());
        a.pass += s.pass;
        a.totalPass += s.totalPass;
      }
    }

    final merged = _mergeNearCodes(agg, rackSAs);
    final list = merged.entries
        .map((e) => ModelPassSummary(
              model: e.key,
              pass: e.value.pass,
              totalPass: e.value.totalPass,
            ))
        .toList()
      ..sort((a, b) => b.totalPass.compareTo(a.totalPass));
    return list;
  }

  static Map<String, _Agg> _mergeNearCodes(
    Map<String, _Agg> src,
    Set<String> rackSAs,
  ) {
    final m = Map<String, _Agg>.from(src);
    final keys = m.keys.toList()..sort();
    final visited = <String>{};

    for (var i = 0; i < keys.length; i++) {
      final a = keys[i];
      if (!m.containsKey(a) || visited.contains(a)) continue;

      for (var j = i + 1; j < keys.length; j++) {
        final b = keys[j];
        if (!m.containsKey(b) || visited.contains(b)) continue;
        if (!diffAtMostOneChar(a, b)) continue;

        String canon;
        final aRack = rackSAs.contains(a), bRack = rackSAs.contains(b);
        if (aRack && !bRack) {
          canon = a;
        } else if (bRack && !aRack) {
          canon = b;
        } else {
          canon = (m[a]!.pass >= m[b]!.pass) ? a : b;
        }

        final other = (canon == a) ? b : a;
        m[canon]!.pass += m[other]!.pass;
        m[canon]!.totalPass += m[other]!.totalPass;
        m.remove(other);
        visited
          ..add(canon)
          ..add(other);
      }
    }
    return m;
  }
}

class _Agg {
  int pass = 0;
  int totalPass = 0;
}

