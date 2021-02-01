// Copyright (c) 2015, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

library xml_rpc.test;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:xml_rpc/client.dart';

void main() {
  late HttpServer httpServer;

  setUp(() => startServer(9000).then((e) => httpServer = e));
  tearDown(() => httpServer.close(force: true));

  test('Simple call', () {
    httpServer.listen(expectAsync1((r) {
      expect(r.headers.contentLength, isNotNull);
      expect(r.method, equals('POST'));
      utf8.decodeStream(r).then(expectAsync1((body) {
        expect(
            body,
            equals('<?xml version="1.0"?>'
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
    call(Uri.parse('http://localhost:${httpServer.port}'), 'm1', [])
        .then(expectAsync1((e) {
      expect(e, equals('South Dakota'));
    }));
  });

  test('Specify encoding', () {
    httpServer.listen(expectAsync1((r) {
      expect(r.headers.contentLength, isNotNull);
      expect(r.headers.contentType!.charset, equals('iso-8859-1'));
      expect(r.method, equals('POST'));
      latin1.decodeStream(r).then(expectAsync1((body) {
        expect(
            body,
            equals('<?xml version="1.0"?>'
                '<methodCall><methodName>éà</methodName></methodCall>'));
        r.response.write('''
<?xml version="1.0"?>
<methodResponse>
  <params>
    <param>
      <value><string>éçàù</string></value>
    </param>
  </params>
</methodResponse>''');
        r.response.close();
      }));
    }));
    call(Uri.parse('http://localhost:${httpServer.port}'), 'éà', [],
            encoding: latin1)
        .then(expectAsync1((e) {
      expect(e, equals('éçàù'));
    }));
  });

  test('Call with error', () {
    httpServer.listen((_) => httpServer.close(force: true));
    call(Uri.parse('http://localhost:${httpServer.port}'), 'm1', [1])
        .catchError(expectAsync1((dynamic e) {
      expect(e, const TypeMatcher<ClientException>());
    }));
  });
}

Future<HttpServer> startServer(int port) =>
    HttpServer.bind('localhost', port).catchError((_) => startServer(port + 1));
