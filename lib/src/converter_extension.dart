// Copyright (c) 2018, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

import 'package:xml/xml.dart';

import 'converter.dart';

final i8Codec = SimpleCodec<int>(
  nodeLocalName: 'i8',
  encodeValue: (value) => value.toString(),
  decodeValue: int.parse,
);

final nilCodec = _NilCodec();

class _NilCodec implements Codec<Null> {
  @override
  XmlNode encode(value, XmlNode Function(dynamic) encode) {
    if (value != null) throw ArgumentError();

    return XmlElement(XmlName('nil'));
  }

  @override
  Null decode(XmlNode node, Function(XmlNode) decode) {
    if (!(node is XmlElement && node.name.local == 'nil')) {
      throw ArgumentError();
    }

    return null;
  }
}
