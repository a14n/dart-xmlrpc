// Copyright (c) 2018, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

/// A client library for [XML-RPC](http://xmlrpc.scripting.com/spec.html)
/// protocol that also support [XML-RPC Extension Types](https://xmlrpc-c.sourceforge.net/doc/libxmlrpc.html#extensiontype).
///
/// You can make method calls with:
///
///     import 'package:xml_rpc/client_c.dart' as xml_rpc;
///     main() async {
///       final url = Uri.parse('...');
///       try {
///         final result = await xml_rpc.call(url, 'examples.getStateName', [41]);
///         print(result);
///       } catch (error) {
///         print(error);
///       }
///     }
library;

import 'dart:async';
import 'dart:convert' show Encoding, utf8;

import 'client.dart' as xml_rpc show call, HttpPost;
import 'src/converter.dart';
import 'src/converter_extension.dart';

export 'client.dart' hide call;

final _codecs = List<Codec>.unmodifiable(<Codec>[
  ...standardCodecs,
  i8Codec,
  nilCodec,
]);

Future call(
  Uri url,
  String methodName,
  List params, {
  Map<String, String>? headers,
  Encoding encoding = utf8,
  xml_rpc.HttpPost? httpPost,
}) =>
    xml_rpc.call(
      url,
      methodName,
      params,
      headers: headers,
      encoding: encoding,
      httpPost: httpPost,
      encodeCodecs: _codecs,
      decodeCodecs: _codecs,
    );
