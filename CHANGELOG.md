## 0.3.0

### Features

- **Re-exported `json_path_plus` from `zikzak_json`** — `import 'package:zikzak_json/zikzak_json.dart';` is now the single entry point for JSON decoding and JSONPath querying (closes #1). `JSONPath`, `JsonPathMatch`, `JsonPathOptions` and `SafeEval` join the public API, making `json_path_plus` part of the public contract.
- **`extractPaths` accepts full JSONPath, not just dot notation.** Paths may be dot notation (`itemList.0.brand`), an explicit RFC 6901 pointer (`/itemList/0/brand`) or a JSONPath expression (`$.itemList[?@.price > 10].brand`). A single path resolves to its value; several resolve to a map keyed by the original path strings.
- **New from `json_path_plus` 2.0.0, reachable through `extractPaths` as well as `JSONPath.query`:** RFC 9535 bare filter selectors (`[?@.price > 10]`, no parentheses needed), the `match()` / `search()` / `key()` built-ins, `/regex/` literals disambiguated from division, `String.match()`, and a `@root` that is actually bound — it previously threw `Bad state: _$_root is not defined` on every filter that used it.

### Breaking

- **`json_path_plus` 2.0.0 removed the public `JSONPath.cache` map.** zikzak_json re-exports the engine, so this is a breaking change for anyone who reached through `package:zikzak_json` to poke the compiled-path memo. The memo is still there — it is now a private LRU bounded at `JSONPath.cacheCapacity` (512). Reach it through `JSONPath.cacheSize`, `JSONPath.isCached(path)` and `JSONPath.clearCache()`.
- **Comparison operators follow RFC 9535** — `<`, `>`, `<=`, `>=` between incomparable types now yield `false` instead of degrading to `0 <op> 0`, so `$.items[?(@.name <= 5)]` no longer selects string-valued nodes, and `true >= false` is `false`. Queries relying on the old loose behaviour will match less. `==` / `===` / `!=` / `!==` are unchanged.

### Fixed

- **`extractPaths` no longer depends on which engine decoded the document.** Paths were routed to simdjson's RFC 6901 pointer reader on the standard-JSON path but to JSONPath on the JSON5 path, so the same string meant two different things: `$.items[?@.price > 10].name` returned `beta` for a JSON5 payload and `null` for the identical document written as standard JSON. Every path now goes through JSONPath on both engines, so filters, wildcards, slices and script expressions work on standard JSON — the default and fast path — where before they silently matched nothing.
- **The pointer fast path is preserved for the paths that can use it.** A path made only of dot-notation segments or an explicit `/`-pointer is still served straight off the simdjson document without materialising the rest of the tree. Only a genuine JSONPath expression forces a full walk, since a pointer cannot express one.
- **A key containing `/` is no longer mistaken for a pointer segment.** `extractPaths` on `{"a":{"b/c":7}}` returned `null` for `a.b/c` on standard JSON, because the path was rewritten to the pointer `/a/b/c`, while the JSON5 engine resolved it correctly. Any path holding a character that is structural in either grammar now routes to JSONPath, which reads it literally, so both engines agree.
- **Filter expressions are bounded** — expressions over 64 KiB or nested deeper than `SafeEval.maxNestingDepth` are rejected with a `FormatException` instead of overflowing the stack. `extractPaths` swallows this as `null`, consistent with its best-effort contract.
- **Re-entrant queries are safe** — the engine's mutable state is now per-evaluation instead of six static fields, so a `JSONPath.query` started from inside a callback no longer corrupts the in-flight walk.
- Also inherited: a bound (LRU-capped) path cache, correct extraction of `)]` inside string literals, literal `#N` property names no longer clobbered by filter placeholders, and quote-escaped round-tripping in `toPathString` / `toPathArray`.

### Known limitation

- Dot notation cannot address a key containing a literal `.`, because the dot reads as a nesting step. This is inherent to the notation rather than to the routing. Bracket quoting resolves such keys on both engines: `$.meta["a.b"]`, and `$.meta[]` for an empty key.

### Dependencies

- `json_path_plus` `^1.1.0` → `^2.0.0` (the re-exported engine is part of the public API, so its breaking change is ours too).
- Dev-only: `lints ^3.0.0` → `^6.1.0`, `test ^1.24.0` → `^1.32.0`.
- `json5_plus ^0.1.8` and `simdjson_dart ^1.6.1` were already at their latest releases.

### Maintenance

- Added coverage for `extractPaths`, which previously had none: dot notation, explicit pointers, filters and wildcards, multi-path maps, mixed plain/JSONPath batches, missing paths and malformed expressions, and keys holding characters that are structural in JSONPath or in a pointer (`/`, `.`, space, `-`, non-ASCII, empty, `$`, `(`, `*`) — each asserted to agree across both engines. 35 tests total.
- Shared extraction logic between the two engines moved into `lib/src/extract.dart`.
- Analyzer-clean under `lints 6.1.0`; dropped the redundant `library zikzak_json;` name that the newer lint flagged.

## 0.2.3

- **`extractJson` no longer throws on undecodable strings** — a bare token, ID, or page fragment (neither JSON nor JSON5) now yields `null` instead of the engines' `FormatException`. Extraction is best-effort by contract; `decode` keeps throwing for callers that want strictness.
- **Raised dependency floors** — `json5_plus ^0.1.8`, `simdjson_dart ^1.6.1` (both already allowed by the previous caret ranges; now required).

## 0.2.2

- **Pinned `json_path_plus` to `^1.1.0`** — ensures consumers get the latest fixes (reverse slices, backtick properties, `!@` negation).

## 0.2.1

- **Updated `json_path_plus` to `^1.1.0`** — picks up the 1.1.0 fixes (reverse slices, backtick properties, `!@` negation, `typeof null`). Zero new dependencies.

## 0.2.0

- **JSONPath now uses `json_path_plus`** — replaces the old `json_path` 0.9.0 dependency with the in-house `json_path_plus: ^1.0.0`. This brings native `@property`, `@.indexOf()`, `===`, type operators, and zero transitive dependencies. No custom function registration needed for filter expressions.
- **Updated `simdjson_dart` to `^1.1.0`** — picks up the latest performance improvements and fixes from the upstream PR.
- Removed vendored `json_path_plus` source in favor of the published pub.dev package.

## 0.1.0

- Initial release.
- Dual-engine JSON parser: simdjson for speed, json5_plus for flexibility.
- Automatic fallback: standard JSON goes through simdjson; JSON5 with comments, unquoted keys, or trailing commas falls back to json5_plus.
- Fast-path heuristic detects JSON5 features early to avoid predictable simdjson failures.
- Recursive `toRaw()` conversion strips `Json5` wrapper objects into pure Dart `Map`/`List` types.
- `encode()`, `extractJson()`, typed convenience methods (`decodeMap`, `decodeList`, `decodeString`), and detection helpers (`isJson`, `isJson5`).
- Dot-notation path extraction via `get()` for safe nested access.
