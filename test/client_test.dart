// Copyright (c) 2015, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

library xml_rpc.test;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:unittest/unittest.dart';
import 'package:xml_rpc/client.dart';

main() {
  HttpServer httpServer;

  setUp(() => startServer(9000).then((e) => httpServer = e));
  tearDown(() => httpServer.close(force: true));

  test('Call without parameters', () {
    httpServer.listen(expectAsync((HttpRequest r) {
      expect(r.headers['content-length'], isNotNull);
      expect(r.method, equals('POST'));
      UTF8.decodeStream(r).then(expectAsync((String body) {
        expect(body, equals('<?xml version="1.0"?>'
            '<methodCall><methodName>m1</methodName></methodCall>'));
        r.response.write('''
<?xml version="1.0"?>
<methodResponse>
  <params>
    <param>
      <value><string>South Dakota</string></value>
    </param>
  </params>
</methodResponse>''');
        r.response.close();
      }));
    }));
    call('http://localhost:${httpServer.port}', 'm1', []).then(expectAsync((e) {
      expect(e, equals('South Dakota'));
    }));
  });

  test('Call with parameters', () {
    httpServer.listen(expectAsync((HttpRequest r) {
      expect(r.headers['content-length'], isNotNull);
      expect(r.method, equals('POST'));
      UTF8.decodeStream(r).then(expectAsync((String body) {
        expect(body, equals('<?xml version="1.0"?>'
            '<methodCall>'
            '<methodName>m1</methodName>'
            '<params><param><value><int>1</int></value></param></params>'
            '</methodCall>'));
        r.response.write('''
<?xml version="1.0"?>
<methodResponse>
  <params>
    <param>
      <value><string>South Dakota</string></value>
    </param>
  </params>
</methodResponse>''');
        r.response.close();
      }));
    }));
    call('http://localhost:${httpServer.port}', 'm1', [1]).then(expectAsync(
        (e) {
      expect(e, equals('South Dakota'));
    }));
  });
}

Future<HttpServer> startServer(int port) =>
    HttpServer.bind('localhost', port).catchError((_) => startServer(port + 1));
