// Copyright (c) 2015, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

library xml_rpc.src.client;

import 'dart:async';

import 'package:http/http.dart' as http show post;
import 'package:xml/xml.dart';

import 'common.dart';
import 'converter.dart';

export 'common.dart';

/// Make a xmlrpc call to the given [url], which can be a [Uri] or a [String].
Future call(url, String methodName, List params,
    {Map<String, String> headers}) {
  final xml = convertMethodCall(methodName, params).toXmlString();

  final _headers = <String, String>{'Content-Type': 'text/xml',};
  if (headers != null) _headers.addAll(headers);

  return http.post(url, headers: _headers, body: xml).then((response) {
    final value = decodeResponse(parse(response.body));
    if (value is Fault) new Future.error(value);
    else return new Future.value(value);
  });
}

XmlDocument convertMethodCall(String methodName, List params) {
  final methodCallChildren = [
    new XmlElement(new XmlName('methodName'), [], [new XmlText(methodName)])
  ];
  if (params != null && params.isNotEmpty) {
    methodCallChildren.add(new XmlElement(new XmlName('params'), [], params.map(
        (p) => new XmlElement(new XmlName('param'), [], [
      new XmlElement(new XmlName('value'), [], [encode(p)])
    ]))));
  }
  return new XmlDocument([
    new XmlProcessing('xml', 'version="1.0"'),
    new XmlElement(new XmlName('methodCall'), [], methodCallChildren)
  ]);
}

decodeResponse(XmlDocument document) {
  final responseElt = document.findElements('methodResponse').first;
  final paramsElts = responseElt.findElements('params');
  if (paramsElts.isNotEmpty) {
    final paramElt = paramsElts.first.findElements('param').first;
    final valueElt = paramElt.findElements('value').first;
    final elt = valueElt.children.firstWhere((e) => e is XmlElement);
    return decode(elt);
  } else {
    int faultCode;
    String faultString;
    responseElt.findElements('fault').first.findElements('value').first
            .findElements('struct').first
        .findElements('member')
        .forEach((memberElt) {
      final name = memberElt.findElements('name').first.text;
      final valueElt = memberElt.findElements('value').first;
      final elt = valueElt.children.firstWhere((e) => e is XmlElement);
      final value = decode(elt);
      if (name == 'faultCode') faultCode = value;
      else if (name == 'faultString') faultString = value;
      else throw new FormatException();
    });
    return new Fault(faultCode, faultString);
  }
}
