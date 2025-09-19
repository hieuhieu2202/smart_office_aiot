class CduLayoutConfig {
  final String? background; // có thể null; bạn sẽ dùng ảnh từ API ở Controller
  final List<Map<String, dynamic>> nodes;

  CduLayoutConfig({this.background, required this.nodes});

  factory CduLayoutConfig.fromJson(Map<String, dynamic> json) {
    return CduLayoutConfig(
      background: json['background'] as String?,
      nodes: (json['nodes'] as List).cast<Map<String, dynamic>>(),
    );
  }
}

/// Dữ liệu layout tĩnh cho F16-3F và F17-3F (chỉ toạ độ + ID; ảnh lấy từ API)
const Map<String, Map<String, dynamic>> _layoutData = {
  'f16_3f': {
    "nodes": [
      {"id": "CDU#1", "x": 0.04977, "y": 0.52786},
      {"id": "CDU#2", "x": 0.07889, "y": 0.36748},
      {"id": "CDU#3", "x": 0.10478, "y": 0.24484},
      {"id": "CDU#4", "x": 0.88924, "y": 0.54041},
      {"id": "CDU#5", "x": 0.30608, "y": 0.37063},
      {"id": "CDU#6", "x": 0.31579, "y": 0.24012},
      {"id": "CDU#17", "x": 0.12291, "y": 0.14421},
      {"id": "CDU#9", "x": 0.36498, "y": 0.53572},
      {"id": "CDU#10", "x": 0.37210, "y": 0.37063},
    ],
  },
  'f17_3f': {
    "nodes": [
      {"id": "CDU#19", "x": 0.48924, "y": 0.03570},
      {"id": "CDU#7", "x": 0.46981, "y": 0.36274},
      {"id": "CDU#30", "x": 0.51773, "y": 0.58604},
      {"id": "CDU#37", "x": 0.49571, "y": 0.66148},
      {"id": "CDU#33", "x": 0.38375, "y": 0.35960},
      {"id": "CDU#36", "x": 0.22710, "y": 0.57658},
      {"id": "CDU#31", "x": 0.20250, "y": 0.65881},
      {"id": "CDU#32", "x": 0.32873, "y": 0.03570},
      {"id": "CDU#34", "x": 0.21092, "y": 0.36006},
      {"id": "CDU#29", "x": 0.25307, "y": 0.03727},
    ],
  },
};

final _layoutCache = <String, CduLayoutConfig>{};

/// Trả về cấu hình layout từ nội bộ (không load file/asset)
Future<CduLayoutConfig> loadLayoutConfig(String factory, String floor) async {
  final key = '${factory.toLowerCase()}_${floor.toLowerCase()}';
  if (_layoutCache.containsKey(key)) return _layoutCache[key]!;

  final raw = _layoutData[key];
  if (raw == null) throw Exception('Layout config not found for $key');

  final config = CduLayoutConfig.fromJson(raw);
  _layoutCache[key] = config;
  return config;
}
