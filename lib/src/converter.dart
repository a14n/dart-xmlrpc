// Copyright (c) 2015, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

library xml_rpc.src.converter;

import 'dart:convert';

import 'package:xml/xml.dart';

import 'common.dart';

abstract class Decoder<T> extends Converter<XmlElement, T> {
  bool accept(XmlElement element);
}

abstract class Encoder<T> extends Converter<T, XmlElement> {
  bool accept(value) => value is T;
}

class IntEncoder extends Encoder<int> {
  @override
  XmlElement convert(int value) {
    if (value > 2147483647 || value < -2147483648) {
      throw new ArgumentError('$value must be a four-byte signed integer.');
    }
    return new XmlElement(
        new XmlName('int'), [], [new XmlText(value.toString())]);
  }
}

class IntDecoder extends Decoder<int> {
  @override
  int convert(XmlElement element) {
    if (!accept(element)) throw new ArgumentError();
    return int.parse(element.text);
  }

  @override
  bool accept(XmlElement element) =>
      element.name.local == 'int' || element.name.local == 'i4';
}

class BoolEncoder extends Encoder<bool> {
  @override
  XmlElement convert(bool value) =>
      new XmlElement(new XmlName('bool'), [], [new XmlText(value ? '1' : '0')]);
}

class BoolDecoder extends Decoder<bool> {
  @override
  bool convert(XmlElement element) {
    if (!accept(element)) throw new ArgumentError();
    final text = element.text;
    if (text != '0' && text != '1') {
      throw new ArgumentError(
          'The element <bool> must contain 0 or 1. Not "$text"');
    }
    return text == '1';
  }

  @override
  bool accept(XmlElement element) => element.name.local == 'bool';
}

class StringEncoder extends Encoder<String> {
  @override
  XmlElement convert(String value) =>
      new XmlElement(new XmlName('string'), [], [new XmlText(value)]);
}

class StringDecoder extends Decoder<String> {
  @override
  String convert(XmlElement element) {
    if (!accept(element)) throw new ArgumentError();
    return element.text;
  }

  @override
  bool accept(XmlElement element) => element.name.local == 'string';
}

class DoubleEncoder extends Encoder<double> {
  @override
  XmlElement convert(double value) => new XmlElement(
      new XmlName('double'), [], [new XmlText(value.toString())]);
}

class DoubleDecoder extends Decoder<double> {
  @override
  double convert(XmlElement element) {
    if (!accept(element)) throw new ArgumentError();
    return double.parse(element.text);
  }

  @override
  bool accept(XmlElement element) => element.name.local == 'double';
}

class DateTimeEncoder extends Encoder<DateTime> {
  @override
  XmlElement convert(DateTime value) => new XmlElement(
      new XmlName('dateTime.iso8601'), [], [
    new XmlText(value.toIso8601String())
  ]);
}

class DateTimeDecoder extends Decoder<DateTime> {
  @override
  DateTime convert(XmlElement element) {
    if (!accept(element)) throw new ArgumentError();
    return DateTime.parse(element.text);
  }

  @override
  bool accept(XmlElement element) => element.name.local == 'dateTime.iso8601';
}

class Base64Encoder extends Encoder<Base64Value> {
  @override
  XmlElement convert(Base64Value value) => new XmlElement(
      new XmlName('base64'), [], [new XmlText(value.base64String)]);
}

class Base64Decoder extends Decoder<Base64Value> {
  @override
  Base64Value convert(XmlElement element) {
    if (!accept(element)) throw new ArgumentError();
    return new Base64Value.fromBase64String(element.text);
  }

  @override
  bool accept(XmlElement element) => element.name.local == 'base64';
}

class StructEncoder extends Encoder<Map<String, dynamic>> {
  @override
  XmlElement convert(Map<String, dynamic> value) {
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
  Map<String, dynamic> convert(XmlElement element) {
    if (!accept(element)) throw new ArgumentError();
    final struct = <String, dynamic>{};
    element.findElements('member').forEach((memberElt) {
      final name = memberElt.findElements('name').first.text;
      final valueElt = memberElt.findElements('value').first;
      final elt = valueElt.children.firstWhere((e) => e is XmlElement);
      struct[name] = decode(elt);
    });
    return struct;
  }

  @override
  bool accept(XmlElement element) => element.name.local == 'struct';
}

class ArrayEncoder extends Encoder<List> {
  @override
  XmlElement convert(List value) {
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
  List convert(XmlElement element) {
    if (!accept(element)) throw new ArgumentError();
    return element.findElements('data').first
        .findElements('value')
        .map((e) => e.children.firstWhere((e) => e is XmlElement))
        .map(decode)
        .toList();
  }

  @override
  bool accept(XmlElement element) => element.name.local == 'array';
}

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

XmlElement encode(value) {
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

decode(XmlElement element) =>
    decoders.firstWhere((e) => e.accept(element)).convert(element);
