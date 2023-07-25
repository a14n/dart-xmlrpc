// Copyright (c) 2015, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

import 'package:collection/collection.dart';
import 'package:xml/xml.dart';

import 'common.dart';

final standardCodecs = List<Codec>.unmodifiable(<Codec>[
  doubleCodec,
  intCodec,
  boolCodec,
  stringCodec,
  dateTimeCodec,
  base64Codec,
  structCodec,
  arrayCodec,
]);
typedef XmlCodecDecodeSignature = Object? Function(XmlNode?);
typedef XmlCodecEncodeSignature = XmlNode Function(Object?);

abstract class Codec<T> {
  T decode(XmlNode? node, XmlCodecDecodeSignature? decode);
  XmlNode encode(Object? value, XmlCodecEncodeSignature? encode);
}

class SimpleCodec<T> implements Codec<T> {
  SimpleCodec({
    required this.nodeLocalName,
    required this.encodeValue,
    required this.decodeValue,
  });

  final String nodeLocalName;
  final String Function(T value) encodeValue;
  final T Function(String text)? decodeValue;

  @override
  XmlNode encode(Object? value, XmlCodecEncodeSignature? encode) =>
      switch (value) {
        _ when value is T => XmlElement(
            XmlName(nodeLocalName),
            [],
            [XmlText(encodeValue(value))],
          ),
        _ => throw ArgumentError(),
      };

  @override
  T decode(XmlNode? node, XmlCodecDecodeSignature? decode) => switch (node) {
        XmlElement(name: XmlName(:final local), :final innerText)
            when local == nodeLocalName =>
          decodeValue!(innerText),
        _ => throw ArgumentError()
      };
}

final intCodec = _IntCodec();

class _IntCodec implements Codec<int> {
  @override
  XmlNode encode(Object? value, XmlCodecEncodeSignature? encode) {
    return switch (value) {
      int() when value >= -2147483648 && value <= 2147483647 => XmlElement(
          XmlName('int'),
          [],
          [XmlText(value.toString())],
        ),
      _ => throw ArgumentError(),
    };
  }

  @override
  int decode(XmlNode? node, XmlCodecDecodeSignature? decode) => switch (node) {
        XmlElement(name: XmlName(local: 'int' || 'i4'), :final innerText) =>
          int.parse(innerText),
        _ => throw ArgumentError()
      };
}

final boolCodec = SimpleCodec<bool>(
  nodeLocalName: 'boolean',
  encodeValue: (value) => switch (value) {
    false => '0',
    true => '1',
  },
  decodeValue: (text) => switch (text) {
    '0' => false,
    '1' => true,
    _ => throw StateError(
        'The element <boolean> must contain 0 or 1. Not "$text"'),
  },
);

final stringCodec = _StringCodec();

class _StringCodec extends SimpleCodec<String> {
  _StringCodec()
      : super(
          nodeLocalName: 'string',
          encodeValue: (value) => value,
          decodeValue: null,
        );

  @override
  String decode(XmlNode? node, XmlCodecDecodeSignature? decode) =>
      switch (node) {
        null => '', // with empty String that leads to "<value />"
        XmlText(:final value) => value,
        XmlElement(name: XmlName(local: 'string'), :final innerText) =>
          innerText,
        _ => throw ArgumentError()
      };
}

final doubleCodec = SimpleCodec<double>(
  nodeLocalName: 'double',
  encodeValue: (value) => value.toString(),
  decodeValue: double.parse,
);

final dateTimeCodec = SimpleCodec<DateTime>(
  nodeLocalName: 'dateTime.iso8601',
  encodeValue: (value) => value.toIso8601String(),
  decodeValue: DateTime.parse,
);

final base64Codec = SimpleCodec<Base64Value>(
  nodeLocalName: 'base64',
  encodeValue: (value) => value.base64String,
  decodeValue: (text) => Base64Value.fromBase64String(text),
);

final faultCodec = _FaultCodec();

class _FaultCodec implements Codec<Fault> {
  @override
  XmlNode encode(Object? value, XmlCodecEncodeSignature? encode) {
    if (value is! Fault) throw ArgumentError();

    final members = <XmlNode>[];
    final faultMap = <String, Object?>{
      'faultCode': value.code,
      'faultString': value.text
    };
    faultMap.forEach((k, v) {
      members.add(XmlElement(XmlName('member'), [], [
        XmlElement(XmlName('name'), [], [XmlText(k)]),
        XmlElement(XmlName('value'), [], [encode!(v)])
      ]));
    });
    return XmlElement(XmlName('struct'), [], members);
  }

  @override
  Fault decode(XmlNode? node, XmlCodecDecodeSignature? decode) {
    if (!(node is XmlElement && node.name.local == 'struct')) {
      throw ArgumentError();
    }
    final struct = <String, Object?>{};
    for (final member in node.findElements('member')) {
      final name = member.findElements('name').first.innerText;
      final valueElt = member.findElements('value').first;
      final elt = getValueContent(valueElt);
      struct[name] = decode!(elt);
    }
    final faultCode = struct['faultCode'];
    final faultString = struct['faultString'];
    if (faultCode is! int || faultString is! String) {
      throw StateError('$struct is not a properly encoded Fault');
    }
    return Fault(faultCode, faultString);
  }
}

final structCodec = _StructCodec();

class _StructCodec implements Codec<Map<String, dynamic>> {
  @override
  XmlNode encode(Object? value, XmlCodecEncodeSignature? encode) {
    if (value is! Map<String, Object?>) throw ArgumentError();

    final members = <XmlNode>[];
    value.forEach((k, v) {
      members.add(XmlElement(XmlName('member'), [], [
        XmlElement(XmlName('name'), [], [XmlText(k)]),
        XmlElement(XmlName('value'), [], [encode!(v)])
      ]));
    });
    return XmlElement(XmlName('struct'), [], members);
  }

  @override
  Map<String, dynamic> decode(XmlNode? node, XmlCodecDecodeSignature? decode) {
    if (!(node is XmlElement && node.name.local == 'struct')) {
      throw ArgumentError();
    }

    final struct = <String, dynamic>{};
    for (final member in node.findElements('member')) {
      final name = member.findElements('name').first.innerText;
      final valueElt = member.findElements('value').first;
      final elt = getValueContent(valueElt);
      struct[name] = decode!(elt);
    }
    return struct;
  }
}

final arrayCodec = _ArrayCodec();

class _ArrayCodec implements Codec<List> {
  @override
  XmlNode encode(Object? value, XmlCodecEncodeSignature? encode) {
    if (value is! List) throw ArgumentError();

    final values = <XmlNode>[];
    for (var e in value) {
      values.add(XmlElement(XmlName('value'), [], [encode!(e)]));
    }
    final data = XmlElement(XmlName('data'), [], values);
    return XmlElement(XmlName('array'), [], [data]);
  }

  @override
  List decode(XmlNode? node, XmlCodecDecodeSignature? decode) {
    if (!(node is XmlElement && node.name.local == 'array')) {
      throw ArgumentError();
    }

    return node
        .findElements('data')
        .first
        .findElements('value')
        .map(getValueContent)
        .map((value) => decode?.call(value))
        .toList();
  }
}

XmlNode? getValueContent(XmlElement valueElt) =>
    valueElt.children.firstWhereOrNull((e) => e is XmlElement) ??
    valueElt.firstChild;

XmlNode encode(Object? value, List<Codec<Object?>> codecs) {
  for (final codec in codecs) {
    try {
      return codec.encode(value, (v) => encode(v, codecs));
    } on ArgumentError {
      // this codec don't support this value
    }
  }
  throw ArgumentError('No encoder to encode the value');
}

Object? decode(XmlNode? node, List<Codec<Object?>> codecs) {
  for (final codec in codecs) {
    try {
      return codec.decode(node, (v) => decode(v, codecs));
    } on ArgumentError {
      // this codec don't support this xml node
    }
  }
  throw ArgumentError('No decoder to decode the value');
}
