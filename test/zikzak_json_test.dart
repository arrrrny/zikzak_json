import 'package:test/test.dart';
import 'package:zikzak_json/zikzak_json.dart';

void main() {
  group('ZikZakJson Tests:', () {
    test('1. Standard JSON (simdjson)', () {
      final result = ZikZakJson.decode('{"a": 1, "b": "hello"}');
      expect(result, isA<Map<String, dynamic>>());
      expect(result['a'], 1);
      expect(result['b'], 'hello');
    });

    test('2. Trailing comma (simdjson fails -> json5_plus)', () {
      final result = ZikZakJson.decode('{"a": 1,}');
      expect(result['a'], 1);
    });

    test('3. Comments (simdjson fails -> json5_plus)', () {
      final result = ZikZakJson.decode('{"a": 1 /* comment */}');
      expect(result['a'], 1);
    });

    test('4. Unquoted keys (fast-path -> json5_plus)', () {
      final result = ZikZakJson.decode('{a: 1}');
      expect(result['a'], 1);
    });

    test('5. Numeric keys (fast-path -> json5_plus)', () {
      final result = ZikZakJson.decode('{102717: "value"}');
      expect(result['102717'], 'value');
    });

    test('6. Nested Json5 (fast-path -> json5_plus)', () {
      final result = ZikZakJson.decode('{a: {b: {c: 1}}}');
      expect(result['a']['b']['c'], 1);

      // Ensure recursive toRaw successfully converted everything
      expect(result, isA<Map<String, dynamic>>());
      expect(result['a'], isA<Map<String, dynamic>>());
      expect(result['a']['b'], isA<Map<String, dynamic>>());
    });

    test('7. Array of objects (fast-path -> json5_plus)', () {
      final result = ZikZakJson.decode('[{a: 1}, {b: 2}]');
      expect(result, isA<List<dynamic>>());
      expect(result[0]['a'], 1);
      expect(result[1]['b'], 2);
    });

    test('8. Large payload (simdjson)', () {
      final json = '{"data": [${List.filled(10000, '{"a": 1}').join(',')}]}';
      final result = ZikZakJson.decode(json);
      expect(result['data'].length, 10000);
    });

    test('9. Force json5 engine', () {
      final result = ZikZakJson.decode(
        '{"a": 1}',
        options: const ZikZakJsonOptions(forceEngine: ZikZakJsonEngine.json5),
      );
      expect(result['a'], 1);
    });

    test('10. Strict mode fails', () {
      expect(
        () => ZikZakJson.decode(
          '{a: 1}',
          options: const ZikZakJsonOptions(strict: true),
        ),
        throwsException,
      );
    });

    test('11. decodeString', () {
      final result = ZikZakJson.decodeString('"hello"');
      expect(result, 'hello');
    });

    test('12. decodeMap on array throws FormatException', () {
      expect(
        () => ZikZakJson.decodeMap('[1, 2, 3]'),
        throwsA(isA<FormatException>()),
      );
    });

    test('13. isJson', () {
      expect(ZikZakJson.isJson("  {  }"), isTrue);
      expect(ZikZakJson.isJson("  [  }"), isTrue);
      expect(ZikZakJson.isJson("hello"), isFalse);
    });

    test('14. isJson5', () {
      expect(ZikZakJson.isJson5('{a: 1}'), isTrue);
      expect(ZikZakJson.isJson5('{"a": 1}'), isFalse);
      expect(ZikZakJson.isJson5('completely invalid []}'), isFalse);
    });

    test('15. Null input edge case', () {
      final result = ZikZakJson.decode("null");
      expect(result, isNull);
    });

    test('16. extractJson on a bare token string returns null, never throws', () {
      // A plain identifier is neither JSON nor JSON5 — extraction is
      // best-effort, so undecodable strings yield null instead of the
      // FormatException the engines raise.
      expect(ZikZakJson.extractJson('Eg0I0bZlGQAAAAAAABBA'), isNull);
      expect(ZikZakJson.extractJson('not json at all'), isNull);
      // Decodable strings still decode.
      expect(ZikZakJson.extractJson('{"a": 1}'), isA<Map>());
      expect(ZikZakJson.extractJson('[1, 2]'), isA<List>());
      // Passthrough shapes are untouched.
      expect(ZikZakJson.extractJson(42), 42);
    });
  });
}
