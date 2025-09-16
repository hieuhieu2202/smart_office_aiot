import '../screen/home/widget/nvidia_lc_switch/Cdu_Monitoring/cdu_layout_loader.dart';
/// Auto-generated CDU layout config for F16-3F and F17-3F
const Map<String, Map<String, dynamic>> cduLayoutConfigData = {
  "f16_3f": {
    "nodes": [
      {"id": "CDU#1", "x": 0.04977, "y": 0.52786, "w": 0.05, "h": 0.05},
      {"id": "CDU#2", "x": 0.07889, "y": 0.36748, "w": 0.05, "h": 0.05},
      {"id": "CDU#3", "x": 0.10478, "y": 0.24484, "w": 0.05, "h": 0.05},
      {"id": "CDU#4", "x": 0.88924, "y": 0.54041, "w": 0.05, "h": 0.05},
      {"id": "CDU#5", "x": 0.30608, "y": 0.37063, "w": 0.05, "h": 0.05},
      {"id": "CDU#6", "x": 0.31579, "y": 0.24012, "w": 0.05, "h": 0.05},
      {"id": "CDU#17", "x": 0.12291, "y": 0.14421, "w": 0.05, "h": 0.05},
      {"id": "CDU#9", "x": 0.36498, "y": 0.53572, "w": 0.05, "h": 0.05},
      {"id": "CDU#10", "x": 0.3721, "y": 0.37063, "w": 0.05, "h": 0.05}
    ]
  },
  "f17_3f": {
    "nodes": [
      {"id": "CDU#19", "x": 0.48924, "y": 0.0357, "w": 0.05, "h": 0.05},
      {"id": "CDU#7", "x": 0.46981, "y": 0.36274, "w": 0.05, "h": 0.05},
      {"id": "CDU#30", "x": 0.51773, "y": 0.58604, "w": 0.05, "h": 0.05},
      {"id": "CDU#37", "x": 0.49571, "y": 0.66148, "w": 0.05, "h": 0.05},
      {"id": "CDU#33", "x": 0.38375, "y": 0.3596, "w": 0.05, "h": 0.05},
      {"id": "CDU#36", "x": 0.2271, "y": 0.57658, "w": 0.05, "h": 0.05},
      {"id": "CDU#31", "x": 0.2025, "y": 0.65881, "w": 0.05, "h": 0.05},
      {"id": "CDU#32", "x": 0.32873, "y": 0.0357, "w": 0.05, "h": 0.05},
      {"id": "CDU#34", "x": 0.21092, "y": 0.36006, "w": 0.05, "h": 0.05},
      {"id": "CDU#29", "x": 0.25307, "y": 0.03727, "w": 0.05, "h": 0.05}
    ]
  }
};

/// Load layout config theo factory/floor
Future<CduLayoutConfig> loadLayoutConfig(String factory, String floor) async {
  final key = '${factory.toLowerCase()}_${floor.toLowerCase()}';
  final data = cduLayoutConfigData[key];
  if (data == null) throw Exception("No layout config for $key");

  return CduLayoutConfig(
    background: data['background'] as String,
    nodes: (data['nodes'] as List).cast<Map<String, dynamic>>(),
  );
}
