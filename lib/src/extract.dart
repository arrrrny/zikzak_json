import 'package:json_path_plus/json_path_plus.dart';

/// Characters that are structural in JSONPath *or* in an RFC 6901 pointer, and
/// so can never appear literally in a dot-notation path.
///
/// `/` and `~` separate and escape pointer segments; `[?*()@'"` + backtick
/// introduce filters, wildcards, slices, script expressions and quoted keys;
/// `,` separates union keys; `~ ^ $` are the property-name, parent and root
/// operators.
const _ambiguousPathChars = r'''[?*()@'"`,~^$/]''';

/// True when [path] can be served by the RFC 6901 JSON Pointer fast path.
///
/// Dot-notation paths (`itemList.0.brand`) and explicit pointers
/// (`/itemList/0/brand`) qualify. Anything carrying an ambiguous character goes
/// to JSONPath instead, so a key containing e.g. `/` is resolved by
/// json_path_plus — which reads it literally — rather than being silently
/// mistaken for a pointer segment.
bool isPlainPointerPath(String path) {
  if (path.isEmpty) return false;
  if (path.startsWith('/')) return true;
  for (var i = 0; i < _ambiguousPathChars.length; i++) {
    if (path.contains(_ambiguousPathChars[i])) return false;
  }
  return true;
}

/// Resolves a single [path] against an already-materialised [doc].
///
/// Accepts both dot notation and full JSONPath, so the same string means the
/// same thing whichever engine decoded the document. Best-effort by contract: a
/// malformed path, a rejected expression or a missing node all yield `null`
/// rather than throwing. Returns the first match when the path selects many.
///
/// Dot notation cannot address a key that contains a literal `.` — it reads the
/// dot as a nesting step. Use bracket quoting (`$.meta["a.b"]`) for those; it
/// is also the spelling to use for an empty key (`$.meta[]`).
Object? queryJsonPath(dynamic doc, String path) {
  final normalized = path.startsWith(r'$') ? path : r'$.' + path;
  try {
    final values = JSONPath.query(normalized, doc, wrap: false);
    return values.isNotEmpty ? values.first : null;
  } catch (_) {
    return null;
  }
}

/// Resolves [paths] against [doc], keyed by the original path string.
///
/// A single path resolves to the bare value; several resolve to a map, matching
/// how `extractPaths` behaves across both engines.
Object? queryJsonPaths(dynamic doc, List<String> paths) {
  if (paths.length == 1) return queryJsonPath(doc, paths.first);
  final result = <String, dynamic>{};
  for (final path in paths) {
    result[path] = queryJsonPath(doc, path);
  }
  return result;
}
