// Copyright (c) 2018, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

/// A client library for [XML-RPC](http://xmlrpc.scripting.com/spec.html)
/// protocol that also support [XML-RPC Extension Types](http://xmlrpc-c.sourceforge.net/doc/libxmlrpc.html#extensiontype).
///
/// You can make method calls with:
///
///     import 'package:xml_rpc/client_c.dart' as xml_rpc;
///     main() {
///       final url = '...';
///       xml_rpc
///           .call(url, 'examples.getStateName', [41])
///           .then((result) => print(result))
///           .catchError((error) => print(error));
///     }

import 'dart:async';
import 'dart:convert' show Encoding, utf8;

import 'package:http/http.dart' as http show Client;

import 'client.dart' as xml_rpc show call;
import 'src/converter.dart';
import 'src/converter_extension.dart';

export 'client.dart' hide call;

final _codecs = new List<Codec>.unmodifiable(<Codec>[]
  ..addAll(standardCodecs)
  ..add(i8Codec)
  ..add(nilCodec));

Future call(
  url,
  String methodName,
  List params, {
  Map<String, String> headers,
  Encoding encoding = utf8,
  http.Client client,
}) =>
    xml_rpc.call(
      url,
      methodName,
      params,
      headers: headers,
      encoding: encoding,
      client: client,
      encodeCodecs: _codecs,
      decodeCodecs: _codecs,
    );
