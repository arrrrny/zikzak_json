/// Fast heuristic to determine if the string contains obvious JSON5 elements.
bool hasJson5Indicators(String source) {
  final trimmed = source.trimLeft();
  if (trimmed.isEmpty) return false;

  // Limit scan to first 4KB to avoid performance hits on massive valid payloads.
  final scanLimit = source.length > 4096 ? 4096 : source.length;
  final chunk = source.substring(0, scanLimit);

  if (chunk.contains('//') || chunk.contains('/*')) return true;
  if (chunk.contains("'")) return true;

  // Trailing commas
  if (RegExp(r',\s*\}').hasMatch(chunk)) return true;
  if (RegExp(r',\s*\]').hasMatch(chunk)) return true;

  // Unquoted/Numeric keys: { key: or { 102717:
  if (RegExp(r'[{,]\s*[a-zA-Z_$][a-zA-Z0-9_$]*\s*:').hasMatch(chunk)) {
    return true;
  }
  if (RegExp(r'[{,]\s*\d+\s*:').hasMatch(chunk)) return true;

  return false;
}
