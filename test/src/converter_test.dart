// Copyright (c) 2015, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

library xml_rpc.src.converter.test;

import 'package:test/test.dart';
import 'package:xml/xml.dart';
import 'package:xml_rpc/src/common.dart';
import 'package:xml_rpc/src/converter.dart';

void main() {
  group('intCodec', () {
    test('encode 1', () {
      expect(intCodec.encode(1, null).toXmlString(), equals('<int>1</int>'));
    });

    test('throws if not a four-byte signed integer', () {
      expect(intCodec.encode(2147483647, null).toXmlString(),
          equals('<int>2147483647</int>'));
      expect(() => intCodec.encode(2147483647 + 1, null), throwsArgumentError);
      expect(intCodec.encode(-2147483648, null).toXmlString(),
          equals('<int>-2147483648</int>'));
      expect(() => intCodec.encode(-2147483648 - 1, null), throwsArgumentError);
    });

    test('decode <int>1</int>', () {
      final elt = parse('<int>1</int>').firstChild;
      expect(intCodec.decode(elt, null), equals(1));
    });

    test('decode <i4>1</i4>', () {
      final elt = parse('<i4>1</i4>').firstChild;
      expect(intCodec.decode(elt, null), equals(1));
    });

    test('throws for <string>1</string>', () {
      final elt = parse('<string>1</string>').firstChild;
      expect(() => intCodec.decode(elt, null), throwsArgumentError);
    });
  });

  group('boolCodec', () {
    test('encode true to 1', () {
      expect(boolCodec.encode(true, null).toXmlString(),
          equals('<boolean>1</boolean>'));
    });

    test('encode false to 0', () {
      expect(boolCodec.encode(false, null).toXmlString(),
          equals('<boolean>0</boolean>'));
    });

    test('decode <boolean>1</boolean>', () {
      final elt = parse('<boolean>1</boolean>').firstChild;
      expect(boolCodec.decode(elt, null), equals(true));
    });

    test('decode <boolean>0</boolean>', () {
      final elt = parse('<boolean>0</boolean>').firstChild;
      expect(boolCodec.decode(elt, null), equals(false));
    });

    test('throws for <boolean>a</boolean>', () {
      final elt = parse('<boolean>a</boolean>').firstChild;
      expect(() => boolCodec.decode(elt, null), throwsStateError);
    });

    test('throws for <string>1</string>', () {
      final elt = parse('<string>1</string>').firstChild;
      expect(() => boolCodec.decode(elt, null), throwsArgumentError);
    });
  });

  group('stringCodec', () {
    test('encode "a"', () {
      expect(stringCodec.encode('a', null).toXmlString(),
          equals('<string>a</string>'));
    });

    test('decode <string>a</string>', () {
      final elt = parse('<string>a</string>').firstChild;
      expect(stringCodec.decode(elt, null), equals('a'));
    });

    test('decode <string>abcde</string>', () {
      final elt = parse('<string>abcde</string>').firstChild;
      expect(stringCodec.decode(elt, null), equals('abcde'));
    });

    test('decode simple text', () {
      final elt = XmlDocument([XmlText('abcde')]).firstChild;
      expect(stringCodec.decode(elt, null), equals('abcde'));
    });

    test('throws for <int>1</int>', () {
      final elt = parse('<boolean>a</boolean>').firstChild;
      expect(() => stringCodec.decode(elt, null), throwsArgumentError);
    });
  });

  group('doubleCodec', () {
    test('encode 1.234', () {
      expect(doubleCodec.encode(1.234, null).toXmlString(),
          equals('<double>1.234</double>'));
    });

    test('decode <double>1.234</double>', () {
      final elt = parse('<double>1.234</double>').firstChild;
      expect(doubleCodec.decode(elt, null), equals(1.234));
    });

    test('decode <double>1</double>', () {
      final elt = parse('<double>1</double>').firstChild;
      expect(doubleCodec.decode(elt, null), equals(1));
    });

    test('throws for <string>1</string>', () {
      final elt = parse('<string>1</string>').firstChild;
      expect(() => doubleCodec.decode(elt, null), throwsArgumentError);
    });
  });

  group('dateTimeCodec', () {
    test('encode correctly', () {
      expect(
          dateTimeCodec
              .encode(DateTime.utc(2015, 1, 22, 8, 13, 42), null)
              .toXmlString(),
          equals(
              '<dateTime.iso8601>2015-01-22T08:13:42.000Z</dateTime.iso8601>'));
    });

    test('decode 2015-01-22T08:13:42.000Z', () {
      final elt =
          parse('<dateTime.iso8601>2015-01-22T08:13:42.000Z</dateTime.iso8601>')
              .firstChild;
      expect(dateTimeCodec.decode(elt, null),
          equals(DateTime.utc(2015, 1, 22, 8, 13, 42)));
    });
    test('decode 19980717T14:08:55', () {
      final elt =
          parse('<dateTime.iso8601>19980717T14:08:55</dateTime.iso8601>')
              .firstChild;
      expect(dateTimeCodec.decode(elt, null),
          equals(DateTime(1998, 7, 17, 14, 8, 55)));
    });

    test('throws for <string>1</string>', () {
      final elt = parse('<string>1</string>').firstChild;
      expect(() => dateTimeCodec.decode(elt, null), throwsArgumentError);
    });
  });

  group('base64Codec', () {
    test('encode correctly', () {
      expect(base64Codec.encode(Base64Value([1, 2, 3]), null).toXmlString(),
          equals('<base64>AQID</base64>'));
    });

    test('decode AQID', () {
      final elt = parse('<base64>AQID</base64>').firstChild;
      expect(base64Codec.decode(elt, null).base64String, equals('AQID'));
      expect(base64Codec.decode(elt, null).bytes, equals([1, 2, 3]));
    });

    test('throws for <string>1</string>', () {
      final elt = parse('<string>1</string>').firstChild;
      expect(() => base64Codec.decode(elt, null), throwsArgumentError);
    });
  });

  group('structCodec', () {
    test('encode correctly', () {
      expect(
          structCodec.encode({'a': 1, 'b': 'c'},
              (n) => encode(n, standardCodecs)).toXmlString(pretty: true),
          equals('''
<struct>
  <member>
    <name>a</name>
    <value>
      <int>1</int>
    </value>
  </member>
  <member>
    <name>b</name>
    <value>
      <string>c</string>
    </value>
  </member>
</struct>'''));
    });

    test('encode empty map correctly', () {
      expect(structCodec.encode(<String, dynamic>{}, null).toXmlString(),
          equals('<struct/>'));
    });

    test('decode struct', () {
      final elt = parse('''
<struct>
  <member>
    <name>a</name>
    <value>
      <int>1</int>
    </value>
  </member>
  <member>
    <name>b</name>
    <value>
      <string>c</string>
    </value>
  </member>
</struct>''').firstChild;
      expect(structCodec.decode(elt, (n) => decode(n, standardCodecs)),
          equals({'a': 1, 'b': 'c'}));
    });

    test('decode empty struct', () {
      final elt = parse('<struct></struct>').firstChild;
      expect(structCodec.decode(elt, null), equals({}));
    });

    test('decode struct with empty string value', () {
      final elt = parse('''
<struct>
  <member>
    <name />
    <value>
      <int>1</int>
    </value>
  </member>
  <member>
    <name>b</name>
    <value />
  </member>
</struct>''').firstChild;
      expect(structCodec.decode(elt, (n) => decode(n, standardCodecs)),
          equals({'': 1, 'b': ''}));
    });

    test('throws for <string>1</string>', () {
      final elt = parse('<string>1</string>').firstChild;
      expect(() => structCodec.decode(elt, null), throwsArgumentError);
    });
  });

  group('arrayCodec', () {
    test('encode correctly', () {
      expect(
          arrayCodec
              .encode(['a', 1], (n) => encode(n, standardCodecs)).toXmlString(
                  pretty: true),
          equals('''
<array>
  <data>
    <value>
      <string>a</string>
    </value>
    <value>
      <int>1</int>
    </value>
  </data>
</array>'''));
    });

    test('encode empty list correctly', () {
      expect(arrayCodec.encode([], null).toXmlString(),
          equals('<array><data/></array>'));
    });

    test('decode array', () {
      final elt = parse('''
<array>
  <data>
    <value>
      <string>a</string>
    </value>
    <value>
      <int>1</int>
    </value>
  </data>
</array>''').firstChild;
      expect(arrayCodec.decode(elt, (n) => decode(n, standardCodecs)),
          equals(['a', 1]));
    });

    test('decode empty array', () {
      final elt = parse('<array><data /></array>').firstChild;
      expect(arrayCodec.decode(elt, null), equals([]));
    });

    test('throws for <string>1</string>', () {
      final elt = parse('<string>1</string>').firstChild;
      expect(() => arrayCodec.decode(elt, null), throwsArgumentError);
    });
  });

  group('decode method', () {
    test('should accept <int>', () {
      final elt = parse('<int>123</int>').firstChild;
      expect(decode(elt, standardCodecs), equals(123));
    });

    test('should accept <i4>', () {
      final elt = parse('<i4>4567</i4>').firstChild;
      expect(decode(elt, standardCodecs), equals(4567));
    });

    test('should accept <boolean>', () {
      final elt = parse('<boolean>1</boolean>').firstChild;
      expect(decode(elt, standardCodecs), equals(true));
    });

    test('should accept <double>', () {
      final elt = parse('<double>1.45</double>').firstChild;
      expect(decode(elt, standardCodecs), equals(1.45));
    });

    test('should accept <dateTime.iso8601>', () {
      final elt =
          parse('<dateTime.iso8601>19980717T14:08:55</dateTime.iso8601>')
              .firstChild;
      expect(decode(elt, standardCodecs),
          equals(DateTime(1998, 7, 17, 14, 8, 55)));
    });

    test('should accept <base64>', () {
      final elt = parse('<base64>AQID</base64>').firstChild;
      expect(decode(elt, standardCodecs), const TypeMatcher<Base64Value>());
      expect((decode(elt, standardCodecs) as Base64Value).base64String,
          equals('AQID'));
      expect((decode(elt, standardCodecs) as Base64Value).bytes,
          equals([1, 2, 3]));
    });

    test('should accept <struct>', () {
      final elt = parse('<struct></struct>').firstChild;
      expect(decode(elt, standardCodecs), equals({}));
    });

    test('should accept <array>', () {
      final elt = parse('<array><data></data></array>').firstChild;
      expect(decode(elt, standardCodecs), equals([]));
    });

    test('throws on <unknown>', () {
      final elt = parse('<unknown>1</unknown>').firstChild;
      expect(() => decode(elt, standardCodecs), throwsArgumentError);
    });
  });

  group('encode method', () {
    test('should accept int', () {
      expect(
          encode(123, standardCodecs).toXmlString(), equals('<int>123</int>'));
    });

    test('should accept bool', () {
      expect(encode(true, standardCodecs).toXmlString(),
          equals('<boolean>1</boolean>'));
    });

    test('should accept double', () {
      expect(encode(1.45, standardCodecs).toXmlString(),
          equals('<double>1.45</double>'));
    });

    test('should accept DateTime', () {
      expect(
          encode(DateTime(1998, 7, 17, 14, 8, 55), standardCodecs)
              .toXmlString(),
          equals(
              '<dateTime.iso8601>1998-07-17T14:08:55.000</dateTime.iso8601>'));
    });

    test('should accept Base64Value', () {
      expect(encode(Base64Value([1, 2, 3]), standardCodecs).toXmlString(),
          equals('<base64>AQID</base64>'));
    });

    test('should accept Map<String, dynamic>', () {
      expect(encode(<String, dynamic>{}, standardCodecs).toXmlString(),
          equals('<struct/>'));
    });

    test('should throw on Map<int, dynamic>', () {
      expect(() => encode(<int, dynamic>{1: 2}, standardCodecs),
          throwsArgumentError);
    });

    test('should accept List', () {
      expect(encode([], standardCodecs).toXmlString(),
          equals('<array><data/></array>'));
    });

    test('throws on Object', () {
      expect(() => encode(Object(), standardCodecs), throwsArgumentError);
    });
  });
}
