import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart';
import 'package:xml_rpc/src/converter_extension.dart';

import 'src/common.dart';
import 'src/converter.dart';

/// A [MethodFailureSignature] contains the name, parameters, and error from any exception or error during a function call
///
/// Name of the method being called
/// Parameters that were passed in
/// Exception or error that occurred
typedef MethodFailureSignature = Fault Function(String, List<dynamic>, dynamic);

/// A [XmlRpcHandler] handles the handling RPC functions along with marshalling the arguments and results to / from XMLRPC spec
///
/// Has a set of [codecs] for encoding and decoding the datatypes
/// To register a method or function with the dispatcher call [registerFunction] along with the function and name
class XmlRpcHandler {
  /// The [codecs] used for encoding and decoding
  List<Codec> codecs;

  /// The function registry
  final Map<String, Function> methods;

  /// A function that gets called on a method failure with the following data
  ///
  /// Name of the method being called
  /// Parameters that were passed in
  /// Exception or error that occurred
  MethodFailureSignature methodFailureHandler;

  /// The error code for a method failure
  final int methodFailureCode;

  /// The error code for a missing method
  final int noExistingMethodCode;

  /// Creates a [XmlRpcHandler] with the set of [codecs] for encoding and decoding
  XmlRpcHandler({
    @required this.methods,
    List<Codec> codecs,
    MethodFailureSignature methodFailureHandler,
    this.methodFailureCode,
    this.noExistingMethodCode,
  }) : codecs = codecs ?? standardCodecs {
    this.methodFailureHandler =
        methodFailureHandler ?? defaultMethodFailureHandler;
  }

  Fault defaultMethodFailureHandler(
          String method, List<dynamic> params, dynamic error) =>
      Fault(methodFailureCode,
          'Dispatching $method, with params $params failed with error $error');

  /// Marshalls the [data] from XML to Dart types, and then dispatches the function, and marshals the return value back into the XMLRPC format
  Future<XmlDocument> handle(XmlDocument document) async {
    final methodCall = document.findElements('methodCall').first;
    final methodName = methodCall.findElements('methodName').first.text;
    var returnValue;
    if (methods.containsKey(methodName)) {
      final params = methodCall.findElements('params');
      final parsedArgs = params.isNotEmpty
          ? params.first
              .findElements('param')
              .map((arg) => arg.findElements('value').first)
              .map(getValueContent)
              .map((e) => decode(e, codecs))
              .toList()
          : [];

      returnValue = await _dispatch(methodName, parsedArgs);
    } else {
      returnValue = Fault(noExistingMethodCode,
          'No method by the name $methodName, registered with this server');
    }
    List<XmlElement> methodResponseChildren;
    if (returnValue is Fault) {
      methodResponseChildren = [
        XmlElement(XmlName('fault'), [], [
          XmlElement(XmlName('value'), [], [
            encode(returnValue, [faultCodec, nilCodec, ...codecs])
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
      return await Function.apply(methods[method], params);
    } catch (e) {
      return methodFailureHandler(method, params, e);
    }
  }
}
