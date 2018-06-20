// Copyright (c) 2015, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

import 'package:meta/meta.dart';
import 'package:xml/xml.dart';

import 'common.dart';

final standardCodecs = new List<Codec>.unmodifiable(<Codec>[
  doubleCodec,
  intCodec,
  boolCodec,
  stringCodec,
  dateTimeCodec,
  base64Codec,
  structCodec,
  arrayCodec,
]);

abstract class Codec<T> {
  T decode(XmlNode node, dynamic Function(XmlNode) decode);
  XmlNode encode(value, XmlNode Function(dynamic) encode);
}

class SimpleCodec<T> implements Codec<T> {
  SimpleCodec({
    @required this.nodeLocalName,
    @required this.encodeValue,
    @required this.decodeValue,
  });

  final String nodeLocalName;
  final String Function(T value) encodeValue;
  final T Function(String text) decodeValue;

  @override
  XmlNode encode(value, XmlNode Function(dynamic) encode) {
    if (value is! T) throw new ArgumentError();

    return new XmlElement(
      new XmlName(nodeLocalName),
      [],
      [new XmlText(encodeValue(value as T))],
    );
  }

  @override
  T decode(XmlNode node, dynamic Function(XmlNode) decode) {
    if (!(node is XmlElement && node.name.local == nodeLocalName))
      throw new ArgumentError();

    return decodeValue(node.text);
  }
}

final intCodec = new _IntCodec();

class _IntCodec implements Codec<int> {
  @override
  XmlNode encode(value, XmlNode Function(dynamic) encode) {
    if (!(value is int && value >= -2147483648 && value <= 2147483647))
      throw new ArgumentError();

    return new XmlElement(
      new XmlName('int'),
      [],
      [new XmlText(value.toString())],
    );
  }

  @override
  int decode(XmlNode node, Function(XmlNode) decode) {
    if (!(node is XmlElement && ['int', 'i4'].contains(node.name.local)))
      throw new ArgumentError();

    return int.parse(node.text);
  }
}

final boolCodec = new SimpleCodec<bool>(
  nodeLocalName: 'boolean',
  encodeValue: (value) => value ? '1' : '0',
  decodeValue: (text) {
    if (text != '0' && text != '1') {
      throw new StateError(
          'The element <boolean> must contain 0 or 1. Not "$text"');
    }
    return text == '1';
  },
);

final stringCodec = new _StringCodec();

class _StringCodec extends SimpleCodec<String> {
  _StringCodec()
      : super(
          nodeLocalName: 'string',
          encodeValue: (value) => value,
          decodeValue: null,
        );

  @override
  String decode(XmlNode node, Function(XmlNode) decode) {
    if (!(node == null || // with empty String that leads to "<value />"
        node is XmlText ||
        node is XmlElement && node.name.local == 'string'))
      throw new ArgumentError();

    return node == null ? '' : node.text;
  }
}

final doubleCodec = new SimpleCodec<double>(
  nodeLocalName: 'double',
  encodeValue: (value) => value.toString(),
  decodeValue: double.parse,
);

final dateTimeCodec = new SimpleCodec<DateTime>(
  nodeLocalName: 'dateTime.iso8601',
  encodeValue: (value) => value.toIso8601String(),
  decodeValue: DateTime.parse,
);

final base64Codec = new SimpleCodec<Base64Value>(
  nodeLocalName: 'base64',
  encodeValue: (value) => value.base64String,
  decodeValue: (text) => new Base64Value.fromBase64String(text),
);

final structCodec = new _StructCodec();

class _StructCodec implements Codec<Map<String, dynamic>> {
  @override
  XmlNode encode(value, XmlNode Function(dynamic) encode) {
    if (value is! Map<String, dynamic>) throw new ArgumentError();

    final members = <XmlNode>[];
    (value as Map<String, dynamic>).forEach((k, v) {
      members.add(new XmlElement(new XmlName('member'), [], [
        new XmlElement(new XmlName('name'), [], [new XmlText(k)]),
        new XmlElement(new XmlName('value'), [], [encode(v)])
      ]));
    });
    return new XmlElement(new XmlName('struct'), [], members);
  }

  @override
  Map<String, dynamic> decode(XmlNode node, Function(XmlNode) decode) {
    if (!(node is XmlElement && node.name.local == 'struct'))
      throw new ArgumentError();

    final struct = <String, dynamic>{};
    for (final member in (node as XmlElement).findElements('member')) {
      final name = member.findElements('name').first.text;
      final valueElt = member.findElements('value').first;
      final elt = getValueContent(valueElt);
      struct[name] = decode(elt);
    }
    return struct;
  }
}

final arrayCodec = new _ArrayCodec();

class _ArrayCodec implements Codec<List> {
  @override
  XmlNode encode(value, XmlNode Function(dynamic) encode) {
    if (value is! List) throw new ArgumentError();

    final values = <XmlNode>[];
    value.forEach((e) {
      values.add(new XmlElement(new XmlName('value'), [], [encode(e)]));
    });
    final data = new XmlElement(new XmlName('data'), [], values);
    return new XmlElement(new XmlName('array'), [], [data]);
  }

  @override
  List decode(XmlNode node, Function(XmlNode) decode) {
    if (!(node is XmlElement && node.name.local == 'array'))
      throw new ArgumentError();

    return (node as XmlElement)
        .findElements('data')
        .first
        .findElements('value')
        .map(getValueContent)
        .map(decode)
        .toList();
  }
}

XmlNode getValueContent(XmlElement valueElt) => valueElt.children
    .firstWhere((e) => e is XmlElement, orElse: () => valueElt.firstChild);

XmlNode encode(value, List<Codec> codecs) {
  for (final codec in codecs) {
    try {
      return codec.encode(value, (v) => encode(v, codecs));
    } on ArgumentError {
      // this codec don't support this value
    }
  }
  throw new ArgumentError('No encoder to encode the value');
}

dynamic decode(XmlNode node, List<Codec> codecs) {
  for (final codec in codecs) {
    try {
      return codec.decode(node, (v) => decode(v, codecs));
    } on ArgumentError {
      // this codec don't support this xml node
    }
  }
  throw new ArgumentError('No decoder to decode the value');
}
