// Copyright (c) 2015, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

library xml_rpc.src.client.test;

import 'package:test/test.dart';
import 'package:xml/xml.dart' show parse;
import 'package:xml_rpc/src/client.dart';
import 'package:xml_rpc/src/converter.dart';

void main() {
  group('convertMethodCall', () {
    test('for method without parameter', () {
      expect(
          convertMethodCall('m1', [], standardCodecs).toXmlString(pretty: true),
          equals('''
<?xml version="1.0"?>
<methodCall>
  <methodName>m1</methodName>
</methodCall>'''));
    });

    test('for method with 1 parameter', () {
      expect(
          convertMethodCall('m1', [1], standardCodecs)
              .toXmlString(pretty: true),
          equals('''
<?xml version="1.0"?>
<methodCall>
  <methodName>m1</methodName>
  <params>
    <param>
      <value>
        <int>1</int>
      </value>
    </param>
  </params>
</methodCall>'''));
    });

    test('for method with 2 parameters', () {
      expect(
          convertMethodCall('m1', [1, 'a'], standardCodecs)
              .toXmlString(pretty: true),
          equals('''
<?xml version="1.0"?>
<methodCall>
  <methodName>m1</methodName>
  <params>
    <param>
      <value>
        <int>1</int>
      </value>
    </param>
    <param>
      <value>
        <string>a</string>
      </value>
    </param>
  </params>
</methodCall>'''));
    });
  });

  group('decodeResponse', () {
    test('for simple response', () {
      expect(decodeResponse(parse('''
<?xml version="1.0"?>
<methodResponse>
  <params>
    <param>
      <value><string>South Dakota</string></value>
    </param>
  </params>
</methodResponse>'''), standardCodecs), equals('South Dakota'));
    });

    test('for fault', () {
      var result = decodeResponse(parse('''
<?xml version="1.0"?>
<methodResponse>
  <fault>
    <value>
      <struct>
        <member>
          <name>faultCode</name>
          <value><int>4</int></value>
        </member>
        <member>
          <name>faultString</name>
          <value><string>Too many parameters.</string></value>
        </member>
      </struct>
    </value>
  </fault>
</methodResponse>'''), standardCodecs);
      expect(result, const TypeMatcher<Fault>());
      result = result as Fault;
      expect(result.code, equals(4));
      expect(result.text, equals('Too many parameters.'));
    });
  });
}
