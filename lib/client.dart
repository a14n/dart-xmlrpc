// Copyright (c) 2015, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

/// The client library for [XML-RPC](http://xmlrpc.scripting.com/spec.html)
/// protocol.
///
/// You can make method calls with:
///
///     import 'package:xml_rpc/client.dart' as xml_rpc;
///     main() {
///       final url = '...';
///       xml_rpc
///           .call(url, 'examples.getStateName', [41])
///           .then((result) => print(result))
///           .catchError((error) => print(error));
///     }

export 'src/client.dart' show call, Fault, Base64Value;
export 'src/converter.dart' hide getValueContent, encode, decode;
