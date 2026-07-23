library zikzak_json;

/// Core: decode, encode, toRaw, extractJson, typed convenience, helpers.
export 'src/zikzak_json.dart';

/// Engine options for fine-grained control.
export 'src/engine.dart' show ZikZakJsonEngine, ZikZakJsonOptions;

/// Low-level Json5→Map converter (also accessible via ZikZakJson.toRaw).
export 'src/to_raw.dart' show toRaw;
