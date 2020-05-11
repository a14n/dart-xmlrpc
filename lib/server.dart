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
/// The default fault codes specified are from the spec [here](http://xmlrpc-epi.sourceforge.net/specs/rfc.fault_codes.php)
class XmlRpcHandler {
  /// The [codecs] used for encoding and decoding
  final List<Codec> codecs;

  /// The function registry
  final Map<String, Function> methods;

  /// A function that gets called on a method failure with the following data
  ///
  /// Name of the method being called
  /// Parameters that were passed in
  /// Exception or error that occurred
  final MethodFailureSignature methodFailureHandler;

  /// The error code for a missing method
  final int noExistingMethodCode;

  /// The error code for malformed xml
  final int malformedXmlCode;

  /// The error code for unsupported encoding
  final int unsupportedEncoding;

  /// Creates a [XmlRpcHandler] that handles the set of [methods]
  ///
  /// It uses the specified set of [codecs] for encoding and decoding
  /// The [methodErrorHandler] is a callback that handles any exception or error thrown from the methods
  /// The code [noExistingMethodCode] is the fault code returned if the method is not found
  XmlRpcHandler({
    @required this.methods,
    List<Codec> codecs,
    MethodFailureSignature methodFailureHandler,
    int noExistingMethodCode,
    int malformedXmlCode,
    int unsupportedEncoding,
  })  : codecs = codecs ?? standardCodecs,
        methodFailureHandler =
            methodFailureHandler ?? _defaultMethodFailureHandler,
        noExistingMethodCode = noExistingMethodCode ?? -32601,
        malformedXmlCode = malformedXmlCode ?? -32700,
        unsupportedEncoding = unsupportedEncoding ?? -32701;

  /// A default method error handling callback
  ///
  /// The default fault code specified here is from the spec [here](http://xmlrpc-epi.sourceforge.net/specs/rfc.fault_codes.php)
  static Fault _defaultMethodFailureHandler(
          String method, List<dynamic> params, dynamic error) =>
      Fault(-32500,
          'Server error. Calling $method, with params $params failed with error $error');

  /// Marshalls the [data] from XML to Dart types, and then dispatches the function, and marshals the return value back into the XMLRPC format
  Future<XmlDocument> handle(XmlDocument document) async {
    var returnValue;
    try {
      final methodCall = document.findElements('methodCall').first;
      final methodName = methodCall.findElements('methodName').first.text;
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
            'Server error. No method by the name $methodName, registered with this server');
      }
    } on ArgumentError catch (e) {
      returnValue = Fault(unsupportedEncoding,
          'Parse error. Decoding arguments failed, got: ${document.toXmlString()}, error was $e');
    } catch (e) {
      returnValue = Fault(malformedXmlCode,
          'Parse error. Not well Formed, got: ${document.toXmlString()}, error was $e');
    }
    List<XmlElement> methodResponseChildren;
    if (returnValue is! Fault) {
      try {
        methodResponseChildren = [
          XmlElement(XmlName('params'), [], [
            XmlElement(XmlName('param'), [], [
              XmlElement(XmlName('value'), [], [encode(returnValue, codecs)])
            ]),
          ])
        ];
      } on ArgumentError catch (e) {
        returnValue = Fault(unsupportedEncoding,
            'Server error. Encoding arguments failed, response was: $returnValue, error was $e');
      }
    }
    // The reason this is not an else statement is because the encoding can fail
    // if we aren't given a codec to encode the return value
    if (returnValue is Fault) {
      methodResponseChildren = [
        XmlElement(XmlName('fault'), [], [
          XmlElement(XmlName('value'), [], [
            encode(returnValue, [faultCodec, nilCodec, ...codecs])
          ])
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
