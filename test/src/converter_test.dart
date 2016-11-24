// Copyright (c) 2015, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

library xml_rpc.src.converter.test;

import 'package:test/test.dart';
import 'package:xml/xml.dart';
import 'package:xml_rpc/src/converter.dart';
import 'package:xml_rpc/src/common.dart';

main() {
  group('IntEncoder', () {
    test('encode 1', () {
      expect(new IntEncoder().convert(1).toXmlString(), equals('<int>1</int>'));
    });

    test('throws if not a four-byte signed integer', () {
      final enc = new IntEncoder();
      expect(enc
          .convert(2147483647)
          .toXmlString(), equals('<int>2147483647</int>'));
      expect(() => enc.convert(2147483647 + 1), throwsArgumentError);
      expect(enc.convert(-2147483648).toXmlString(),
          equals('<int>-2147483648</int>'));
      expect(() => enc.convert(-2147483648 - 1), throwsArgumentError);
    });
  });

  group('IntDecoder', () {
    test('decode <int>1</int>', () {
      final elt = parse('<int>1</int>').firstChild;
      expect(new IntDecoder().convert(elt), equals(1));
    });

    test('decode <i4>1</i4>', () {
      final elt = parse('<i4>1</i4>').firstChild;
      expect(new IntDecoder().convert(elt), equals(1));
    });

    test('throws for <string>1</string>', () {
      final elt = parse('<string>1</string>').firstChild;
      expect(() => new IntDecoder().convert(elt), throwsArgumentError);
    });
  });

  group('BoolEncoder', () {
    test('encode true to 1', () {
      expect(new BoolEncoder().convert(true).toXmlString(),
          equals('<boolean>1</boolean>'));
    });

    test('encode false to 0', () {
      expect(new BoolEncoder().convert(false).toXmlString(),
          equals('<boolean>0</boolean>'));
    });
  });

  group('BoolDecoder', () {
    test('decode <boolean>1</boolean>', () {
      final elt = parse('<boolean>1</boolean>').firstChild;
      expect(new BoolDecoder().convert(elt), equals(true));
    });

    test('decode <boolean>0</boolean>', () {
      final elt = parse('<boolean>0</boolean>').firstChild;
      expect(new BoolDecoder().convert(elt), equals(false));
    });

    test('throws for <boolean>a</boolean>', () {
      final elt = parse('<boolean>a</boolean>').firstChild;
      expect(() => new BoolDecoder().convert(elt), throwsArgumentError);
    });

    test('throws for <string>1</string>', () {
      final elt = parse('<string>1</string>').firstChild;
      expect(() => new BoolDecoder().convert(elt), throwsArgumentError);
    });
  });

  group('StringEncoder', () {
    test('encode "a"', () {
      expect(new StringEncoder().convert('a').toXmlString(),
          equals('<string>a</string>'));
    });
  });

  group('StringDecoder', () {
    test('decode <string>a</string>', () {
      final elt = parse('<string>a</string>').firstChild;
      expect(new StringDecoder().convert(elt), equals('a'));
    });

    test('decode <string>abcde</string>', () {
      final elt = parse('<string>abcde</string>').firstChild;
      expect(new StringDecoder().convert(elt), equals('abcde'));
    });

    test('decode simple text', () {
      final elt = new XmlDocument([new XmlText('abcde')]).firstChild;
      expect(new StringDecoder().convert(elt), equals('abcde'));
    });

    test('throws for <int>1</int>', () {
      final elt = parse('<boolean>a</boolean>').firstChild;
      expect(() => new StringDecoder().convert(elt), throwsArgumentError);
    });
  });

  group('DoubleEncoder', () {
    test('encode 1.234', () {
      expect(new DoubleEncoder().convert(1.234).toXmlString(),
          equals('<double>1.234</double>'));
    });
  });

  group('DoubleDecoder', () {
    test('decode <double>1.234</double>', () {
      final elt = parse('<double>1.234</double>').firstChild;
      expect(new DoubleDecoder().convert(elt), equals(1.234));
    });

    test('decode <double>1</double>', () {
      final elt = parse('<double>1</double>').firstChild;
      expect(new DoubleDecoder().convert(elt), equals(1));
    });

    test('throws for <string>1</string>', () {
      final elt = parse('<string>1</string>').firstChild;
      expect(() => new DoubleDecoder().convert(elt), throwsArgumentError);
    });
  });

  group('DateTimeEncoder', () {
    test('encode correctly', () {
      expect(new DateTimeEncoder()
          .convert(new DateTime.utc(2015, 1, 22, 8, 13, 42))
          .toXmlString(), equals(
              '<dateTime.iso8601>2015-01-22T08:13:42.000Z</dateTime.iso8601>'));
    });
  });

  group('DateTimeDecoder', () {
    test('decode 2015-01-22T08:13:42.000Z', () {
      final elt = parse(
          '<dateTime.iso8601>2015-01-22T08:13:42.000Z</dateTime.iso8601>').firstChild;
      expect(new DateTimeDecoder().convert(elt),
          equals(new DateTime.utc(2015, 1, 22, 8, 13, 42)));
    });
    test('decode 19980717T14:08:55', () {
      final elt = parse(
          '<dateTime.iso8601>19980717T14:08:55</dateTime.iso8601>').firstChild;
      expect(new DateTimeDecoder().convert(elt),
          equals(new DateTime(1998, 7, 17, 14, 8, 55)));
    });

    test('throws for <string>1</string>', () {
      final elt = parse('<string>1</string>').firstChild;
      expect(() => new DateTimeDecoder().convert(elt), throwsArgumentError);
    });
  });

  group('Base64Encoder', () {
    test('encode correctly', () {
      expect(
          new Base64Encoder().convert(new Base64Value([1, 2, 3])).toXmlString(),
          equals('<base64>AQID</base64>'));
    });
  });

  group('Base64Decoder', () {
    test('decode AQID', () {
      final elt = parse('<base64>AQID</base64>').firstChild;
      expect(new Base64Decoder().convert(elt).base64String, equals('AQID'));
      expect(new Base64Decoder().convert(elt).bytes, equals([1, 2, 3]));
    });

    test('throws for <string>1</string>', () {
      final elt = parse('<string>1</string>').firstChild;
      expect(() => new Base64Decoder().convert(elt), throwsArgumentError);
    });
  });

  group('StructEncoder', () {
    test('encode correctly', () {
      expect(new StructEncoder()
          .convert({'a': 1, 'b': 'c'})
          .toXmlString(pretty: true), equals('''
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
      expect(
          new StructEncoder().convert({}).toXmlString(), equals('<struct />'));
    });
  });

  group('StructDecoder', () {
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
      expect(new StructDecoder().convert(elt), equals({'a': 1, 'b': 'c'}));
    });

    test('decode empty struct', () {
      final elt = parse('<struct></struct>').firstChild;
      expect(new StructDecoder().convert(elt), equals({}));
    });

    test('throws for <string>1</string>', () {
      final elt = parse('<string>1</string>').firstChild;
      expect(() => new StructDecoder().convert(elt), throwsArgumentError);
    });
  });

  group('ArrayEncoder', () {
    test('encode correctly', () {
      expect(new ArrayEncoder().convert(['a', 1]).toXmlString(pretty: true),
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
      expect(new ArrayEncoder().convert([]).toXmlString(),
          equals('<array><data /></array>'));
    });
  });

  group('ArrayDecoder', () {
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
      expect(new ArrayDecoder().convert(elt), equals(['a', 1]));
    });

    test('decode empty array', () {
      final elt = parse('<array><data /></array>').firstChild;
      expect(new ArrayDecoder().convert(elt), equals([]));
    });

    test('throws for <string>1</string>', () {
      final elt = parse('<string>1</string>').firstChild;
      expect(() => new ArrayDecoder().convert(elt), throwsArgumentError);
    });
  });

  group('decode method', () {
    test('should accept <int>', () {
      final elt = parse('<int>123</int>').firstChild;
      expect(decode(elt), equals(123));
    });

    test('should accept <i4>', () {
      final elt = parse('<i4>4567</i4>').firstChild;
      expect(decode(elt), equals(4567));
    });

    test('should accept <boolean>', () {
      final elt = parse('<boolean>1</boolean>').firstChild;
      expect(decode(elt), equals(true));
    });

    test('should accept <double>', () {
      final elt = parse('<double>1.45</double>').firstChild;
      expect(decode(elt), equals(1.45));
    });

    test('should accept <dateTime.iso8601>', () {
      final elt = parse(
          '<dateTime.iso8601>19980717T14:08:55</dateTime.iso8601>').firstChild;
      expect(decode(elt), equals(new DateTime(1998, 7, 17, 14, 8, 55)));
    });

    test('should accept <base64>', () {
      final elt = parse('<base64>AQID</base64>').firstChild;
      expect(decode(elt), new isInstanceOf<Base64Value>());
      expect((decode(elt) as Base64Value).base64String, equals('AQID'));
      expect((decode(elt) as Base64Value).bytes, equals([1, 2, 3]));
    });

    test('should accept <struct>', () {
      final elt = parse('<struct></struct>').firstChild;
      expect(decode(elt), equals({}));
    });

    test('should accept <array>', () {
      final elt = parse('<array><data></data></array>').firstChild;
      expect(decode(elt), equals([]));
    });

    test('throws on <unknown>', () {
      final elt = parse('<unknown>1</unknown>').firstChild;
      expect(() => decode(elt), throws);
    });
  });

  group('encode method', () {
    test('should accept int', () {
      expect(encode(123).toXmlString(), equals('<int>123</int>'));
    });

    test('should accept bool', () {
      expect(encode(true).toXmlString(), equals('<boolean>1</boolean>'));
    });

    test('should accept double', () {
      expect(encode(1.45).toXmlString(), equals('<double>1.45</double>'));
    });

    test('should accept DateTime', () {
      expect(encode(new DateTime(1998, 7, 17, 14, 8, 55)).toXmlString(), equals(
          '<dateTime.iso8601>1998-07-17T14:08:55.000</dateTime.iso8601>'));
    });

    test('should accept Base64Value', () {
      expect(encode(new Base64Value([1, 2, 3])).toXmlString(),
          equals('<base64>AQID</base64>'));
    });

    test('should accept Map<String, dynamic>', () {
      expect(encode({}).toXmlString(), equals('<struct />'));
    });

    test('should throw on Map<int, dynamic>', () {
      expect(() => encode(<int, dynamic>{1: 2}), throws);
    });

    test('should accept List', () {
      expect(encode([]).toXmlString(), equals('<array><data /></array>'));
    });

    test('throws on Object', () {
      expect(() => encode(new Object()), throws);
    });
  });
}
