import 'package:json5_plus/json5_plus.dart';
import 'package:json_path/json_path.dart';
import 'to_raw.dart';

dynamic decodeWithJson5(String source, {List<String>? extractPaths}) {
  final parsed = Json5.parseAny(source);
  final raw = toRaw(parsed);

  if (extractPaths != null && extractPaths.isNotEmpty) {
    if (extractPaths.length == 1) {
      return _extractJsonPath(raw, extractPaths.first);
    }

    final result = <String, dynamic>{};
    for (final path in extractPaths) {
      result[path] = _extractJsonPath(raw, path);
    }
    return result;
  }
  return raw;
}

dynamic _extractJsonPath(dynamic raw, String path) {
  // Convert simple dot notation to JSONPath syntax if needed
  String normalizedPath = path.startsWith(r'$') ? path : r'$.' + path;
  try {
    final jp = JsonPath(normalizedPath);
    final matches = jp.read(raw).toList();
    return matches.isNotEmpty ? matches.first.value : null;
  } catch (_) {
    return null;
  }
}
