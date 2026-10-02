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

    test(
      '16. extractJson on a bare token string returns null, never throws',
      () {
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
      },
    );

    test('17. json_path_plus is re-exported by the single entry point', () {
      // No `import 'package:json_path_plus/...'` in this file on purpose:
      // consumers must get JSONPath through zikzak_json alone.
      final json = ZikZakJson.decode('{"itemList":[{"brand":"Master Lock"}]}');
      final values = JSONPath.query(r'$.itemList[*].brand', json, wrap: false);
      expect(values, ['Master Lock']);
    });
  });

  group('extractPaths:', () {
    // Same document twice: once standard JSON (simdjson engine), once JSON5
    // (json5_plus engine). Every path must resolve identically on both.
    const std =
        '{"items":[{"name":"alpha","price":5},'
        '{"name":"beta","price":50}],"meta":{"total":2}}';
    const json5 =
        '{items:[{name:"alpha",price:5},'
        '{name:"beta",price:50}],meta:{total:2}}';

    Object? extract(
      String source,
      List<String> paths, {
      ZikZakJsonEngine force = ZikZakJsonEngine.auto,
    }) => ZikZakJson.decode(
      source,
      options: ZikZakJsonOptions(extractPaths: paths, forceEngine: force),
    );

    test('18. dot-notation path resolves on both engines', () {
      expect(extract(std, ['items.0.name']), 'alpha');
      expect(extract(json5, ['items.0.name']), 'alpha');
      expect(extract(std, ['meta.total']), 2);
    });

    test('19. explicit RFC 6901 pointer still takes the fast path', () {
      expect(extract(std, ['/items/1/name']), 'beta');
      expect(extract(std, ['/meta/total']), 2);
    });

    test('20. JSONPath filters resolve identically on both engines', () {
      // The regression this guards: the simdjson engine used to hand filters to
      // the JSON Pointer fast path, where they silently matched nothing.
      for (final source in [std, json5]) {
        expect(extract(source, [r'$.items[?@.price > 10].name']), 'beta');
        expect(extract(source, [r'$.items[?( @.price > 10 )].name']), 'beta');
        expect(extract(source, [r'$.items[?search(@.name, /^b/)].price']), 50);
      }
    });

    test('21. a wildcard path resolves identically on both engines', () {
      // extractPaths yields the first match, not the whole result list.
      expect(extract(std, [r'$.meta[*]']), 2);
      expect(extract(json5, [r'$.meta[*]']), 2);
    });

    test('22. multiple paths return a map keyed by the original paths', () {
      final stdResult = extract(std, ['items.0.name', 'meta.total']);
      expect(stdResult, {'items.0.name': 'alpha', 'meta.total': 2});
      expect(extract(json5, ['items.0.name', 'meta.total']), {
        'items.0.name': 'alpha',
        'meta.total': 2,
      });
    });

    test('23. mixed plain and JSONPath paths in one call', () {
      expect(extract(std, ['meta.total', r'$.items[?@.price > 10].name']), {
        'meta.total': 2,
        r'$.items[?@.price > 10].name': 'beta',
      });
    });

    test(
      '24. missing paths and malformed expressions yield null, never throw',
      () {
        for (final source in [std, json5]) {
          expect(extract(source, ['items.9.name']), isNull);
          expect(extract(source, ['nope.nope']), isNull);
          expect(extract(source, [r'$.items[?(@.price ===)].name']), isNull);
          // SafeEval's nesting limit rejects this rather than overflowing.
          final opens = '(' * 200;
          final closes = ')' * 200;
          expect(
            extract(source, ['\$.items[?($opens@.price$closes)]']),
            isNull,
          );
        }
      },
    );

    test('25. forced engines agree with the auto-selected one', () {
      const paths = [r'$.items[?@.price > 10].name'];
      expect(extract(std, paths), 'beta');
      expect(extract(std, paths, force: ZikZakJsonEngine.simdjson), 'beta');
      expect(extract(json5, paths, force: ZikZakJsonEngine.json5), 'beta');
    });

    // Keys holding characters that are structural in JSONPath or in a pointer.
    // Dot notation cannot address a key containing a literal `.`; every other
    // case here must resolve, and must resolve the same on both engines.
    group('26. unusual keys resolve identically on both engines', () {
      const stdOdd =
          r'{"a":{"b/c":7,"d.e":8,"f g":9,"h-i":10,'
          r'"jé":11,"":12,"k$l":13,"m(n)":14,"o*p":15}}';
      const json5Odd =
          // Same document as JSON5. Unquoted `a` routes it to the json5 engine;
          // the exotic keys stay quoted because they are not identifiers.
          r'{a:{"b/c":7,"d.e":8,"f g":9,"h-i":10,'
          r'"jé":11,"":12,"k$l":13,"m(n)":14,"o*p":15}}';

      // (path, expected value) — dot notation wherever it can address the key.
      const cases = <(String, Object?)>[
        ('a.b/c', 7),
        (r'$.a["d.e"]', 8),
        ('a.f g', 9),
        ('a.h-i', 10),
        ('a.jé', 11),
        (r'$.a[]', 12),
        (r'a.k$l', 13),
        ('a.m(n)', 14),
        ('a.o*p', 15),
      ];

      for (final (path, expected) in cases) {
        test('"$path" -> $expected', () {
          for (final source in [stdOdd, json5Odd]) {
            expect(extract(source, [path]), expected);
          }
        });
      }

      test('a key holding a literal dot needs bracket quoting', () {
        // `a.d.e` cannot address the key `d.e` — dot notation reads it as a
        // nested step. Bracket quoting is the only spelling that works, and it
        // works identically on both engines.
        for (final source in [stdOdd, json5Odd]) {
          expect(extract(source, ['a.d.e']), isNull);
          expect(extract(source, [r'$.a["d.e"]']), 8);
        }
      });
    });
  });
}
