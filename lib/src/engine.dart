enum ZikZakJsonEngine { auto, simdjson, json5 }

class ZikZakJsonOptions {
  /// Force a specific engine. Default: auto (try simdjson, fallback json5_plus).
  final ZikZakJsonEngine forceEngine;

  /// If true, never fall back — throw on first failure. Default: false.
  final bool strict;

  /// If true, log which engine was used and timing. Default: false.
  final bool verbose;

  /// Paths to extract instead of returning the whole document. Default: empty.
  ///
  /// Each path may be plain dot notation (`itemList.0.brand`), an explicit
  /// RFC 6901 pointer (`/itemList/0/brand`), or a full JSONPath expression
  /// (`$.itemList[?@.price > 10].brand`). The same path resolves identically
  /// whether the document was decoded by simdjson or by json5_plus.
  ///
  /// A single path resolves to its value; several resolve to a map keyed by the
  /// original path strings. Paths that select nothing — or that fail to
  /// evaluate — yield `null` rather than throwing.
  ///
  /// Dot notation cannot address a key containing a literal `.`; use bracket
  /// quoting (`$.meta["a.b"]`, `$.meta[]`) for those.
  ///
  /// Plain pointer paths avoid materialising the rest of the document; a
  /// JSONPath expression has to walk the whole tree, so mixing the two in one
  /// call gives up that optimisation.
  final List<String>? extractPaths;

  const ZikZakJsonOptions({
    this.forceEngine = ZikZakJsonEngine.auto,
    this.strict = false,
    this.verbose = false,
    this.extractPaths,
  });
}
