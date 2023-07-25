import 'package:xml/xml.dart';

import 'src/common.dart';
import 'src/converter.dart';

/// A [XmlRpcHandler] handles the handling RPC functions along with marshalling the arguments and results to / from XMLRPC spec
///
/// Has a set of [codecs] for encoding and decoding the datatypes
class XmlRpcHandler {
  /// Creates a [XmlRpcHandler] that handles the set of [methods].
  ///
  /// It uses the specified set of [codecs] for encoding and decoding.
  XmlRpcHandler({
    required this.methods,
    List<Codec>? codecs,
  }) : codecs = codecs ?? standardCodecs;

  /// The [codecs] used for encoding and decoding
  final List<Codec> codecs;

  /// The function registry
  final Map<String, Function> methods;

  /// Marshalls the [data] from XML to Dart types, and then dispatches the function, and marshals the return value back into the XMLRPC format
  Future<XmlDocument> handle(XmlDocument document) async {
    String methodName;
    final params = <Object?>[];
    try {
      final methodCall = document.findElements('methodCall').first;
      methodName = methodCall.findElements('methodName').first.innerText;
      var paramsElements = methodCall.findElements('params');
      if (paramsElements.isNotEmpty) {
        final args = paramsElements.first.findElements('param');
        for (final arg in args) {
          params.add(
            decode(getValueContent(arg.findElements('value').first), codecs),
          );
        }
      }
    } catch (e) {
      throw XmlRpcRequestFormatException(e);
    }

    // check method has target
    if (!methods.containsKey(methodName)) {
      throw XmlRpcMethodNotFoundException(methodName);
    }

    // execute call
    Object? result;
    try {
      result = await Function.apply(methods[methodName]!, params);
    } catch (e) {
      throw XmlRpcCallException(e);
    }

    // encode result
    XmlNode encodedResult;
    try {
      encodedResult = encode(result, codecs);
    } catch (e) {
      throw XmlRpcResponseEncodingException(e);
    }
    return XmlDocument([
      XmlProcessing('xml', 'version="1.0"'),
      XmlElement(XmlName('methodResponse'), [], [
        XmlElement(XmlName('params'), [], [
          XmlElement(XmlName('param'), [], [
            XmlElement(XmlName('value'), [], [encodedResult])
          ]),
        ])
      ])
    ]);
  }

  XmlDocument handleFault(Fault fault, {List<Codec>? codecs}) => XmlDocument([
        XmlProcessing('xml', 'version="1.0"'),
        XmlElement(XmlName('methodResponse'), [], [
          XmlElement(XmlName('fault'), [], [
            XmlElement(XmlName('value'), [], [
              encode(fault, codecs ?? [faultCodec, ...this.codecs])
            ])
          ])
        ])
      ]);
}

abstract class XmlRpcException implements Exception {
  XmlRpcException([this.cause]);

  /// The cause thrown when the real method was called.
  Object? cause;
}

class XmlRpcRequestFormatException extends XmlRpcException {
  XmlRpcRequestFormatException([Object? cause]) : super(cause);
}

/// When an exception occurs in the real method call
class XmlRpcMethodNotFoundException extends XmlRpcException {
  XmlRpcMethodNotFoundException(this.name);

  /// The name of the method not found.
  String name;
}

/// When an exception occurs in the real method call
class XmlRpcCallException extends XmlRpcException {
  XmlRpcCallException([Object? cause]) : super(cause);
}

/// When an exception occurs in response encoding
class XmlRpcResponseEncodingException extends XmlRpcException {
  XmlRpcResponseEncodingException([Object? cause]) : super(cause);
}
