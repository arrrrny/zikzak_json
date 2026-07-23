import 'dart:convert';
import 'package:json5_plus/json5_plus.dart';
import 'engine.dart';
import 'fast_path.dart';
import 'simdjson_engine.dart';
import 'json5_engine.dart';
import 'to_raw.dart' as raw;

class ZikZakJson {
  // ═══════════════════════════════════════════════════════
  // Decode — primary entry point
  // ═══════════════════════════════════════════════════════

  /// Decodes a JSON/JSON5 string into raw Dart types.
  /// Uses simdjson for speed on standard JSON, falls back to
  /// json5_plus for comments, trailing commas, unquoted keys.
  static dynamic decode(String source, {ZikZakJsonOptions? options}) {
    options ??= const ZikZakJsonOptions();
    final stopwatch = Stopwatch()..start();

    dynamic executeSimdjson() {
      try {
        final start = stopwatch.elapsedMicroseconds;
        final res = decodeWithSimdjson(
          source,
          extractPaths: options!.extractPaths,
        );
        if (options.verbose) {
          print(
            '[ZikZakJson] simdjson: ${(stopwatch.elapsedMicroseconds - start) / 1000}ms -> SUCCESS',
          );
        }
        return res;
      } catch (e) {
        if (options!.verbose) {
          print(
            '[ZikZakJson] simdjson: ${stopwatch.elapsedMicroseconds / 1000}ms -> FAIL ($e)',
          );
        }
        rethrow;
      }
    }

    dynamic executeJson5([bool isFallback = false]) {
      final start = stopwatch.elapsedMicroseconds;
      final res = decodeWithJson5(source, extractPaths: options!.extractPaths);
      if (options.verbose) {
        print(
          '[ZikZakJson] json5_plus: ${(stopwatch.elapsedMicroseconds - start) / 1000}ms -> SUCCESS',
        );
      }
      return res;
    }

    if (options.forceEngine == ZikZakJsonEngine.simdjson) {
      return executeSimdjson();
    } else if (options.forceEngine == ZikZakJsonEngine.json5) {
      return executeJson5();
    }

    // Auto mode
    final trimmed = source.trimLeft();
    if (trimmed.isEmpty) return null;

    // Check fast heuristics if the document structure is object/array
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      if (hasJson5Indicators(source) && !options.strict) {
        if (options.verbose) {
          print('[ZikZakJson] fast-path: detected JSON5 -> skipped simdjson');
        }
        return executeJson5();
      }
    }

    // Default to simdjson
    try {
      return executeSimdjson();
    } catch (e) {
      if (options.strict) rethrow;
      return executeJson5(true);
    }
  }

  // ═══════════════════════════════════════════════════════
  // Encode — serialization
  // ═══════════════════════════════════════════════════════

  /// Encodes a Dart object to a JSON string.
  ///
  /// If [pretty] is true, formats with 2-space indentation.
  static String encode(dynamic obj, {bool pretty = false}) {
    if (pretty) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(obj);
    }
    return jsonEncode(obj);
  }

  // ═══════════════════════════════════════════════════════
  // toRaw — strip Json5 wrappers
  // ═══════════════════════════════════════════════════════

  /// Recursively converts Json5 wrapper objects into raw Dart
  /// types (Map, List, primitives). Passthrough for everything else.
  static dynamic toRaw(dynamic obj) => raw.toRaw(obj);

  // ═══════════════════════════════════════════════════════
  // extractJson — extract JSON from any container
  // ═══════════════════════════════════════════════════════

  /// Extracts a JSON-compatible object (Map, List, or primitive)
  /// from any input.
  ///
  /// Handles:
  /// - `Json5` objects → recursively converts to raw Map
  /// - `Map` / `List` → returned as-is (already raw)
  /// - `String` → decoded via [decode] (supports JSON + JSON5)
  /// - Everything else → returned as-is (passthrough)
  static Object? extractJson(Object? obj) {
    if (obj is Json5) return toRaw(obj);
    if (obj is Map || obj is List) return obj;
    if (obj is String) return decode(obj);
    return obj;
  }

  // ═══════════════════════════════════════════════════════
  // Typed convenience
  // ═══════════════════════════════════════════════════════

  static String decodeString(String source) {
    final res = decode(source);
    if (res is! String) throw FormatException('Expected top-level string');
    return res;
  }

  static Map<String, dynamic> decodeMap(String source) {
    final res = decode(source);
    if (res is! Map) throw FormatException('Expected top-level object');
    return Map<String, dynamic>.from(res);
  }

  static List<dynamic> decodeList(String source) {
    final res = decode(source);
    if (res is! List) throw FormatException('Expected top-level array');
    return res;
  }

  // ═══════════════════════════════════════════════════════
  // Detection helpers
  // ═══════════════════════════════════════════════════════

  /// Returns true if the trimmed input starts with `{` or `[`.
  static bool isJson(String source) {
    final trimmed = source.trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }

  /// Returns true if the input is valid JSON5 but NOT valid strict JSON.
  static bool isJson5(String source) {
    try {
      decode(
        source,
        options: const ZikZakJsonOptions(
          forceEngine: ZikZakJsonEngine.simdjson,
          strict: true,
        ),
      );
      return false; // valid standard JSON
    } catch (_) {
      try {
        decode(
          source,
          options: const ZikZakJsonOptions(
            forceEngine: ZikZakJsonEngine.json5,
            strict: true,
          ),
        );
        return true; // invalid standard JSON, valid JSON5
      } catch (_) {
        return false; // invalid both
      }
    }
  }

  // ═══════════════════════════════════════════════════════
  // jsonLike — type inspection & safe access for JSON values
  // ═══════════════════════════════════════════════════════

  /// Returns true if [value] is a non-null Map _or_ a String that
  /// looks like JSON (starts with `{` or `[` after trimming).
  static bool jsonLike(Object? value) {
    if (value is Map) return true;
    if (value is List) return true;
    if (value is String) {
      final t = value.trimLeft();
      return t.startsWith('{') || t.startsWith('[');
    }
    return false;
  }

  // Type checks
  static bool isMap(Object? v) => v is Map;
  static bool isList(Object? v) => v is List;
  static bool isString(Object? v) => v is String;
  static bool isNum(Object? v) => v is num;
  static bool isInt(Object? v) => v is int;
  static bool isDouble(Object? v) => v is double;
  static bool isBool(Object? v) => v is bool;
  static bool isNull(Object? v) => v == null;

  // Safe type accessors (return null instead of throwing)
  static Map<String, dynamic>? asMap(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : null;
  static List? asList(Object? v) => v is List ? v : null;
  static String? asString(Object? v) => v is String ? v : null;
  static int? asInt(Object? v) => v is int ? v : null;
  static double? asDouble(Object? v) => v is double ? v : null;
  static bool? asBool(Object? v) => v is bool ? v : null;

  /// Safely reads a nested value from a JSON tree using dot notation.
  /// Returns `null` if any segment is missing or the path doesn't exist.
  ///
  /// Example: `ZikZakJson.get(json, 'itemList.0.product.brand')` → `"Master Lock"`
  static dynamic get(Object? json, String path) {
    if (json == null || path.isEmpty) return null;
    final parts = path.split('.');
    dynamic current = json;
    for (final part in parts) {
      if (current is Map) {
        current = current[part];
      } else if (current is List) {
        final index = int.tryParse(part);
        if (index == null || index < 0 || index >= current.length) return null;
        current = current[index];
      } else {
        return null;
      }
    }
    return current;
  }
}
