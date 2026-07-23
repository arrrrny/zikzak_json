## 0.1.0

- Initial release.
- Dual-engine JSON parser: simdjson for speed, json5_plus for flexibility.
- Automatic fallback: standard JSON goes through simdjson; JSON5 with comments, unquoted keys, or trailing commas falls back to json5_plus.
- Fast-path heuristic detects JSON5 features early to avoid predictable simdjson failures.
- Recursive `toRaw()` conversion strips `Json5` wrapper objects into pure Dart `Map`/`List` types.
- `encode()`, `extractJson()`, typed convenience methods (`decodeMap`, `decodeList`, `decodeString`), and detection helpers (`isJson`, `isJson5`).
- Dot-notation path extraction via `get()` for safe nested access.
