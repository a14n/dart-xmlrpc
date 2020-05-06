import 'dart:convert';
import 'dart:io';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart';

import 'common.dart';
import 'converter.dart';

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
  XmlRpcHandler({@required this.methods, this.codecs}) {
    codecs ??= standardCodecs;
  }

  /// Marshalls the [data] from XML to Dart types, and then dispatches the function, and marshals the return value back into the XMLRPC format
  XmlDocument handle(XmlDocument document) {
    final methodCall = document.findElements('methodCall').first;
    final methodName = methodCall.findElements('methodName').first.text;
    final parsedArgs = [];
    try {
      final args =
          methodCall.findElements('params').first.findElements('param');
      for (final arg in args) {
        parsedArgs.add(
          decode(getValueContent(arg.findElements('value').first), codecs),
        );
      }
    } on StateError {
      // No arguments given
    }
    final returnValue = _dispatch(methodName, parsedArgs);
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

  /// Registers a [function] to be dispatched when recieving an XMLRPC call on a function with the name [name]
  void registerFunction(Function function, String name) {
    methods[name] = function;
  }

  /// Dispatches [method] with the Dart [params]
  ///
  /// Functions registered overshadow the instance methods
  dynamic _dispatch(String method, List<dynamic> params) {
    try {
      if (methods[method] != null) {
        return Function.apply(methods[method], params);
      } else {
        return Fault(
            2, 'No method by the name $method, registered with this server');
      }
    } on Exception {
      return Fault(1, 'Dispatching $method, with params $params failed');
    }
  }
}
