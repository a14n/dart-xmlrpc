// Copyright (c) 2015, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

library xml_rpc.src.converter.test;

import 'package:test/test.dart';
import 'package:xml/xml.dart';
import 'package:xml_rpc/src/converter_extension.dart';

main() {
  group('nilCodec', () {
    test('encode null', () {
      expect(nilCodec.encode(null, null).toXmlString(), equals('<nil />'));
    });

    test('decode <nil></nil>', () {
      final elt = parse('<nil></nil>').firstChild;
      expect(nilCodec.decode(elt, null), equals(null));
    });

    test('decode <nil />', () {
      final elt = parse('<nil />').firstChild;
      expect(nilCodec.decode(elt, null), equals(null));
    });
  });

  group('i8Codec', () {
    test('encode 1', () {
      expect(i8Codec.encode(1, null).toXmlString(), equals('<i8>1</i8>'));
    });

    test('encode greater than four-byte signed integer', () {
      expect(i8Codec.encode(2147483647, null).toXmlString(),
          equals('<i8>2147483647</i8>'));
      expect(i8Codec.encode(2147483647 + 1, null).toXmlString(),
          equals('<i8>2147483648</i8>'));
      expect(i8Codec.encode(-2147483648, null).toXmlString(),
          equals('<i8>-2147483648</i8>'));
      expect(i8Codec.encode(-2147483648 - 1, null).toXmlString(),
          equals('<i8>-2147483649</i8>'));
    });

    test('decode <i8>1</i8>', () {
      final elt = parse('<i8>1</i8>').firstChild;
      expect(i8Codec.decode(elt, null), equals(1));
    });

    test('decode <i8>2147483648</i8>', () {
      final elt = parse('<i8>2147483648</i8>').firstChild;
      expect(i8Codec.decode(elt, null), equals(2147483648));
    });
  });
}
