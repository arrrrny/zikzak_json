import 'dart:convert';
import 'package:simdjson_dart/simdjson_dart.dart';
import 'extract.dart';

dynamic decodeWithSimdjson(String source, {List<String>? extractPaths}) {
  final bytes = utf8.encode(source);

  if (extractPaths == null || extractPaths.isEmpty) {
    return simdJsonDecodeBytes(bytes);
  }

  // A JSONPath expression cannot be expressed as a pointer and needs a
  // materialised tree to run against. Selective materialisation only pays off
  // while *every* requested path is a plain pointer, so one JSONPath path
  // sends the whole batch down the JSONPath route and keeps the result
  // identical to what the json5 engine would have produced.
  if (extractPaths.any((path) => !isPlainPointerPath(path))) {
    return queryJsonPaths(simdJsonDecodeBytes(bytes), extractPaths);
  }

  final doc = SimdJsonDocument.parseBytes(bytes);
  try {
    if (extractPaths.length == 1) {
      return doc.at(_toPointer(extractPaths.first));
    }

    final result = <String, dynamic>{};
    for (final path in extractPaths) {
      result[path] = doc.at(_toPointer(path));
    }
    return result;
  } finally {
    doc.close();
  }
}

/// Converts a simple dot-notation path into an RFC 6901 JSON Pointer.
String _toPointer(String path) {
  if (path.startsWith('/')) return path;
  return '/${path.replaceAll(".", "/")}';
}
