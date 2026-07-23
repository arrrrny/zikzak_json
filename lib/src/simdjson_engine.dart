import 'dart:convert';
import 'package:simdjson_dart/simdjson_dart.dart';

dynamic decodeWithSimdjson(String source, {List<String>? extractPaths}) {
  final bytes = utf8.encode(source);

  if (extractPaths != null && extractPaths.isNotEmpty) {
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

  return simdJsonDecodeBytes(bytes);
}

/// Converts a simple dot-notation path into an RFC 6901 JSON Pointer.
String _toPointer(String path) {
  if (path.startsWith('/')) return path;
  return '/${path.replaceAll(".", "/")}';
}
