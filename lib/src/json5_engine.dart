import 'package:json5_plus/json5_plus.dart';
import 'extract.dart';
import 'to_raw.dart';

dynamic decodeWithJson5(String source, {List<String>? extractPaths}) {
  final parsed = Json5.parseAny(source);
  final raw = toRaw(parsed);

  if (extractPaths != null && extractPaths.isNotEmpty) {
    return queryJsonPaths(raw, extractPaths);
  }
  return raw;
}
