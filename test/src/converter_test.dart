// Copyright (c) 2015, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

library xml_rpc.src.converter.test;

import 'package:unittest/unittest.dart';
import 'package:xml/xml.dart' show parse;
import 'package:xml_rpc/src/converter.dart';

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
      expect(new IntDecoder()
          .convert(parse('<int>1</int>').findElements('int').first), equals(1));
    });
    test('decode <i4>1</i4>', () {
      expect(new IntDecoder()
          .convert(parse('<i4>1</i4>').findElements('i4').first), equals(1));
    });
    test('throws for <string>1</string>', () {
      expect(() => new IntDecoder().convert(
              parse('<string>1</string>').findElements('string').first),
          throwsArgumentError);
    });
  });
}
