import 'package:json5_plus/json5_plus.dart';

/// Recursively un-wraps `Json5` wrapper objects into pure Dart types.
dynamic toRaw(dynamic obj) {
  if (obj is Json5) {
    final map = <String, dynamic>{};
    for (final entry in obj.entries) {
      map[entry.key] = toRaw(entry.value);
    }
    return map;
  }
  if (obj is List) {
    // Iteratively strip lists
    return obj.map(toRaw).toList();
  }
  return obj;
}
