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
