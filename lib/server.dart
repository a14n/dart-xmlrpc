import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart';

import 'src/common.dart';
import 'src/converter.dart';

/// A [XmlRpcHandler] handles the handling RPC functions along with marshalling the arguments and results to / from XMLRPC spec
///
/// Has a set of [codecs] for encoding and decoding the datatypes
/// To register a method or function with the dispatcher call [registerFunction] along with the function and name
class XmlRpcHandler {
  /// The [codecs] used for encoding and decoding
  List<Codec> codecs;

  /// The function registry
  final Map<String, Function> methods;

  /// Creates a [XmlRpcHandler] with the set of [codecs] for encoding and decoding
  XmlRpcHandler({@required this.methods, List<Codec> codecs})
      : codecs = codecs ?? standardCodecs;

  /// Marshalls the [data] from XML to Dart types, and then dispatches the function, and marshals the return value back into the XMLRPC format
  Future<XmlDocument> handle(XmlDocument document) async {
    final methodCall = document.findElements('methodCall').first;
    final methodName = methodCall.findElements('methodName').first.text;
    final params = methodCall.findElements('params');
    final parsedArgs = params.isNotEmpty
        ? params.first
            .findElements('param')
            .map((arg) => arg.findElements('value').first)
            .map(getValueContent)
            .map((e) => decode(e, codecs))
            .toList()
        : [];

    final returnValue = await _dispatch(methodName, parsedArgs);
    List<XmlElement> methodResponseChildren;
    if (returnValue is Fault) {
      methodResponseChildren = [
        XmlElement(XmlName('fault'), [], [
          XmlElement(XmlName('value'), [], [
            encode(returnValue, [faultCodec, ...codecs])
          ])
        ])
      ];
    } else {
      methodResponseChildren = [
        XmlElement(XmlName('params'), [], [
          XmlElement(XmlName('param'), [], [
            XmlElement(XmlName('value'), [], [encode(returnValue, codecs)])
          ]),
        ])
      ];
    }
    return XmlDocument([
      XmlProcessing('xml', 'version="1.0"'),
      XmlElement(XmlName('methodResponse'), [], methodResponseChildren)
    ]);
  }

  /// Dispatches [method] with the Dart [params]
  ///
  /// Functions registered overshadow the instance methods
  dynamic _dispatch(String method, List<dynamic> params) async {
    try {
      if (methods[method] != null) {
        return await Function.apply(methods[method], params);
      } else {
        return Fault(
            2, 'No method by the name $method, registered with this server');
      }
    } on Exception {
      return Fault(1, 'Dispatching $method, with params $params failed');
    }
  }
}
