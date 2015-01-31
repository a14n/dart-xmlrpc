// Copyright (c) 2015, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

library xml_rpc.src.converter;

import 'dart:convert';

import 'package:xml/xml.dart';

import 'common.dart';

abstract class Decoder<T> extends Converter<XmlNode, T> {
  bool accept(XmlNode node);
}

abstract class Encoder<T> extends Converter<T, XmlNode> {
  bool accept(value) => value is T;
}

class IntEncoder extends Encoder<int> {
  @override
  XmlNode convert(int value) {
    if (value > 2147483647 || value < -2147483648) {
      throw new ArgumentError('$value must be a four-byte signed integer.');
    }
    return new XmlElement(
        new XmlName('int'), [], [new XmlText(value.toString())]);
  }
}

class IntDecoder extends Decoder<int> {
  @override
  int convert(XmlNode element) {
    if (!accept(element)) throw new ArgumentError();
    return int.parse(element.text);
  }

  @override
  bool accept(XmlNode element) => element is XmlElement &&
      (element.name.local == 'int' || element.name.local == 'i4');
}

class BoolEncoder extends Encoder<bool> {
  @override
  XmlNode convert(bool value) => new XmlElement(
      new XmlName('boolean'), [], [new XmlText(value ? '1' : '0')]);
}

class BoolDecoder extends Decoder<bool> {
  @override
  bool convert(XmlNode element) {
    if (!accept(element)) throw new ArgumentError();
    final text = element.text;
    if (text != '0' && text != '1') {
      throw new ArgumentError(
          'The element <boolean> must contain 0 or 1. Not "$text"');
    }
    return text == '1';
  }

  @override
  bool accept(XmlNode element) =>
      element is XmlElement && element.name.local == 'boolean';
}

class StringEncoder extends Encoder<String> {
  @override
  XmlNode convert(String value) =>
      new XmlElement(new XmlName('string'), [], [new XmlText(value)]);
}

class StringDecoder extends Decoder<String> {
  @override
  String convert(XmlNode element) {
    if (!accept(element)) throw new ArgumentError();
    return element.text;
  }

  @override
  bool accept(XmlNode node) =>
      node is XmlText || node is XmlElement && node.name.local == 'string';
}

class DoubleEncoder extends Encoder<double> {
  @override
  XmlNode convert(double value) => new XmlElement(
      new XmlName('double'), [], [new XmlText(value.toString())]);
}

class DoubleDecoder extends Decoder<double> {
  @override
  double convert(XmlNode element) {
    if (!accept(element)) throw new ArgumentError();
    return double.parse(element.text);
  }

  @override
  bool accept(XmlNode element) =>
      element is XmlElement && element.name.local == 'double';
}

class DateTimeEncoder extends Encoder<DateTime> {
  @override
  XmlNode convert(DateTime value) => new XmlElement(
      new XmlName('dateTime.iso8601'), [], [
    new XmlText(value.toIso8601String())
  ]);
}

class DateTimeDecoder extends Decoder<DateTime> {
  @override
  DateTime convert(XmlNode element) {
    if (!accept(element)) throw new ArgumentError();
    return DateTime.parse(element.text);
  }

  @override
  bool accept(XmlNode element) =>
      element is XmlElement && element.name.local == 'dateTime.iso8601';
}

class Base64Encoder extends Encoder<Base64Value> {
  @override
  XmlNode convert(Base64Value value) => new XmlElement(
      new XmlName('base64'), [], [new XmlText(value.base64String)]);
}

class Base64Decoder extends Decoder<Base64Value> {
  @override
  Base64Value convert(XmlNode element) {
    if (!accept(element)) throw new ArgumentError();
    return new Base64Value.fromBase64String(element.text);
  }

  @override
  bool accept(XmlNode element) =>
      element is XmlElement && element.name.local == 'base64';
}

class StructEncoder extends Encoder<Map<String, dynamic>> {
  @override
  XmlNode convert(Map<String, dynamic> value) {
    final members = [];
    value.forEach((k, v) {
      members.add(new XmlElement(new XmlName('member'), [], [
        new XmlElement(new XmlName('name'), [], [new XmlText(k)]),
        new XmlElement(new XmlName('value'), [], [encode(v)])
      ]));
    });
    return new XmlElement(new XmlName('struct'), [], members);
  }
}

class StructDecoder extends Decoder<Map<String, dynamic>> {
  @override
  Map<String, dynamic> convert(XmlNode element) {
    if (!accept(element)) throw new ArgumentError();
    final struct = <String, dynamic>{};
    (element as XmlElement).findElements('member').forEach((memberElt) {
      final name = memberElt.findElements('name').first.text;
      final valueElt = memberElt.findElements('value').first;
      final elt = getValueContent(valueElt);
      struct[name] = decode(elt);
    });
    return struct;
  }

  @override
  bool accept(XmlNode element) =>
      element is XmlElement && element.name.local == 'struct';
}

class ArrayEncoder extends Encoder<List> {
  @override
  XmlNode convert(List value) {
    final values = [];
    value.forEach((e) {
      values.add(new XmlElement(new XmlName('value'), [], [encode(e)]));
    });
    final data = new XmlElement(new XmlName('data'), [], values);
    return new XmlElement(new XmlName('array'), [], [data]);
  }
}

class ArrayDecoder extends Decoder<List> {
  @override
  List convert(XmlNode element) {
    if (!accept(element)) throw new ArgumentError();
    return (element as XmlElement).findElements('data').first
        .findElements('value')
        .map(getValueContent)
        .map(decode)
        .toList();
  }

  @override
  bool accept(XmlNode element) =>
      element is XmlElement && element.name.local == 'array';
}

XmlNode getValueContent(XmlElement valueElt) => valueElt.children.firstWhere(
    (e) => e is XmlElement, orElse: () => valueElt.firstChild);

final encoders = <Encoder>[
  new IntEncoder(),
  new BoolEncoder(),
  new StringEncoder(),
  new DoubleEncoder(),
  new DateTimeEncoder(),
  new Base64Encoder(),
  new StructEncoder(),
  new ArrayEncoder(),
];

XmlNode encode(value) {
  if (value == null) throw new ArgumentError.notNull();
  return encoders.firstWhere((e) => e.accept(value)).convert(value);
}

final decoders = <Decoder>[
  new IntDecoder(),
  new BoolDecoder(),
  new StringDecoder(),
  new DoubleDecoder(),
  new DateTimeDecoder(),
  new Base64Decoder(),
  new StructDecoder(),
  new ArrayDecoder(),
];

decode(XmlNode node) =>
    decoders.firstWhere((e) => e.accept(node)).convert(node);
