/// Vendored copy of `json5_plus` 0.1.8 — see `LICENSE` in this directory.
///
/// Upstream: https://github.com/AndyKing42/json5_plus (Apache-2.0).
///
/// Vendored rather than depended on for one reason: upstream 0.1.8 spins
/// forever on a bare `/` outside a string or comment
/// (`_skipWhitespaceAndRegisterComments` never advances `_pos`), which hangs
/// every caller that feeds it a malformed JSON candidate — the deterministic
/// hang behind arrrrny/scraper_configs#53. The fix is a single `else` arm in
/// `json5_parser.dart` that rejects the token with a `FormatException`.
///
/// `zikzak_json` is the only consumer, so the patch lives here instead of
/// being pushed on every downstream project as a `dependency_overrides`
/// entry. Drop this directory and restore the `json5_plus` dependency once
/// https://github.com/AndyKing42/json5_plus/issues/1 ships.
library;

export 'src/json5.dart';
export 'src/json5_extensions.dart';
export 'src/json5_util.dart';
export 'src/typed_accessor_mixin.dart';
