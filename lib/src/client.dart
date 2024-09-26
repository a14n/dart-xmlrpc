// Copyright (c) 2015, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

library;

import 'dart:async';
import 'dart:convert' show Encoding, utf8;

import 'package:http/http.dart' as http show post, Response;
import 'package:xml/xml.dart';

import 'common.dart';
import 'converter.dart';

export 'common.dart';

/// The function to make http post.
typedef HttpPost = Future<http.Response> Function(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
});

/// Make a xmlrpc call to the given [url], which can be a [Uri] or a [String].
Future call(
  Uri url,
  String methodName,
  List params, {
  Map<String, String>? headers,
  Encoding encoding = utf8,
  HttpPost? httpPost,
  List<Codec>? encodeCodecs,
  List<Codec>? decodeCodecs,
}) async {
  encodeCodecs ??= standardCodecs;
  decodeCodecs ??= standardCodecs;

  final xml = convertMethodCall(methodName, params, encodeCodecs).toXmlString();

  final _headers = <String, String>{
    'Content-Type': 'text/xml',
    if (headers != null) ...headers,
  };

  final post = httpPost ?? http.post;
  final response =
      await post(url, headers: _headers, body: xml, encoding: encoding);
  if (response.statusCode != 200) throw response;
  final body = response.body;
  final value = decodeResponse(XmlDocument.parse(body), decodeCodecs);
  if (value is Fault) {
    throw value;
  } else {
    return value;
  }
}

XmlDocument convertMethodCall(
    String methodName, List params, List<Codec> encodeCodecs) {
  final methodCallChildren = [
    XmlElement(XmlName('methodName'), [], [XmlText(methodName)]),
    if (params.isNotEmpty)
      XmlElement(
        XmlName('params'),
        [],
        params.map(
          (p) => XmlElement(
            XmlName('param'),
            [],
            [
              XmlElement(XmlName('value'), [], [encode(p, encodeCodecs)]),
            ],
          ),
        ),
      ),
  ];

  return XmlDocument([
    XmlProcessing('xml', 'version="1.0"'),
    XmlElement(XmlName('methodCall'), [], methodCallChildren)
  ]);
}

dynamic decodeResponse(XmlDocument document, List<Codec> decodeCodecs) {
  final responseElt = document.findElements('methodResponse').first;
  final paramsElts = responseElt.findElements('params');
  if (paramsElts.isNotEmpty) {
    final paramElt = paramsElts.first.findElements('param').first;
    final valueElt = paramElt.findElements('value').first;
    final elt = getValueContent(valueElt);
    return decode(elt, decodeCodecs);
  } else {
    late int faultCode;
    late String faultString;
    final members = responseElt
        .findElements('fault')
        .first
        .findElements('value')
        .first
        .findElements('struct')
        .first
        .findElements('member');
    for (final member in members) {
      final name = member.findElements('name').first.text;
      final valueElt = member.findElements('value').first;
      final elt = getValueContent(valueElt);
      final value = decode(elt, decodeCodecs);
      if (name == 'faultCode') {
        faultCode = value as int;
      } else if (name == 'faultString') {
        faultString = value as String;
      }
    }
    return Fault(faultCode, faultString);
  }
}
