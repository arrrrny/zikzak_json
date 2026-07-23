enum ZikZakJsonEngine { auto, simdjson, json5 }

class ZikZakJsonOptions {
  /// Force a specific engine. Default: auto (try simdjson, fallback json5_plus).
  final ZikZakJsonEngine forceEngine;

  /// If true, never fall back — throw on first failure. Default: false.
  final bool strict;

  /// If true, log which engine was used and timing. Default: false.
  final bool verbose;

  /// Paths to extract via dot-notation, avoiding full parse. Default: empty.
  final List<String>? extractPaths;

  const ZikZakJsonOptions({
    this.forceEngine = ZikZakJsonEngine.auto,
    this.strict = false,
    this.verbose = false,
    this.extractPaths,
  });
}
