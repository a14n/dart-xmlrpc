import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart';

import 'common.dart';
import 'converter.dart';

/// A [SimpleXMLRPCServer] that handles the XMLRPC server protocol with a single threaded [HttpServer]
class SimpleXMLRPCServer extends SimpleXMLRPCDispatcher {
  /// The [host] uri
  final String host;

  /// The [port] to host the server on
  final int port;

  /// The [Encoding] to use as default, this defaults to [utf8]
  final Encoding encoding;

  /// The [HttpServer] used for handling responses
  HttpServer _httpServer;

  /// The [SimpleXMLRPCRequestHandler] used for handling the http calls
  SimpleXMLRPCRequestHandler _requestHandler;

  /// Creates a [SimpleXMLRPCServer] that will bind to the specified [host] and [port]
  ///
  /// Optionally you can specify the [codecs] used for encoding and decoding values
  /// as well as the String [encoding] for http requests and responses
  ///
  /// You must await the call to [serverForever] to start up the server
  /// before making any client requests
  SimpleXMLRPCServer(
    this.host,
    this.port, {
    this.encoding = utf8,
    List<Codec> codecs,
  }) : super(codecs) {
    _requestHandler = SimpleXMLRPCRequestHandler();
  }

  /// Starts up the [_httpServer] and starts listening to requests
  Future<void> serveForever() async {
    _httpServer = await HttpServer.bind(host, port);
    _httpServer
        .listen((req) => _requestHandler._acceptRequest(req, this, encoding));
  }
}

/// A [SimpleXMLRPCDispatcher] handles the dispatching of functions along with marshalling the arguments and results to / from XMLRPC spec
///
/// Has a set of [codecs] for encoding and decoding the datatypes
/// To register a method or function with the dispatcher call [registerFunction] along with the function and name
/// To register a [XMLFunctionHandler] class instance call [registerInstance], currently only one instance is supported
/// You can both [registerInstance] and [registerFunction], but the functions will overshadow the instance functions with the same name
/// To register a set of functions that can be used for introspection call [registerIntrospectionFunctions]
class SimpleXMLRPCDispatcher {
  /// The [codecs] used for encoding and decoding
  List<Codec> codecs;

  /// The function registry
  final _funcs = <String, Function>{};

  /// The [XMLFunctionHandler] instance used for dispatching
  XMLFunctionHandler _instance;

  /// Creates a [SimpleXMLRPCDispatcher] with the set of [codecs] for encoding and decoding
  SimpleXMLRPCDispatcher(this.codecs) {
    codecs ??= standardCodecs;
  }

  /// Marshals the [data] from XML to Dart types, and then dispatches the function, and marshals the return value back into the XMLRPC format
  String _marshaledDispatch(String data) {
    final document = parse(data);
    final methodCall = document.findElements('methodCall').first;
    final methodName = methodCall.findElements('methodName').first.text;
    final args = methodCall.findElements('params').first.findElements('param');
    final parsedArgs = [];
    for (final arg in args) {
      parsedArgs.add(
        decode(getValueContent(arg.findElements('value').first), codecs),
      );
    }
    final returnValue = _dispatch(methodName, parsedArgs);
    List<XmlElement> methodResponseChildren;
    if (returnValue is Fault) {
      methodResponseChildren = [
        XmlElement(XmlName('fault'), [], [
          XmlElement(XmlName('value'), [], [
            encode(returnValue, [faultCodec])
          ])
        ])
      ];
    }

    methodResponseChildren = [
      XmlElement(XmlName('params'), [], [
        XmlElement(XmlName('param'), [], [
          XmlElement(XmlName('value'), [], [encode(returnValue, codecs)])
        ]),
      ])
    ];
    return XmlDocument([
      XmlProcessing('xml', 'version="1.0"'),
      XmlElement(XmlName('methodResponse'), [], methodResponseChildren)
    ]).toXmlString();
  }

  /// Registers a [function] to be dispatched when recieving an XMLRPC call on a function with the name [name]
  void registerFunction(Function function, String name) {
    _funcs[name] = function;
  }

  /// Registers a set of introspection functions for introspection on what functions the XMLRPC server can handle
  void registerIntrospectionFunctions() {
    _funcs.addAll({
      'system.listMethods': _systemListMethods,
      'system.methodHelp': _systemMethodHelp
    });
  }

  /// Registers a [XMLFunctionHandler] [instance] to be used when dispatching functions
  void registerInstance(XMLFunctionHandler instance) {
    _instance = instance;
  }

  /// Lists the methods that are registered with the server
  List<String> _systemListMethods() {
    final methods = _funcs.keys.toList();
    if (_instance != null) {
      methods.addAll(_instance.listMethods());
    }
    return methods..sort();
  }

  /// Returns the help string of the method with the speicified [methodName]
  String _systemMethodHelp(String methodName) {
    if (_funcs[methodName] != null) {
      return '';
    }
    if (_instance != null) {
      return _instance.methodHelp(methodName);
    }
    return '';
  }

  /// Dispatches [method] with the Dart [params]
  ///
  /// Functions registered overshadow the instance methods
  dynamic _dispatch(String method, List<dynamic> params) {
    try {
      if (_funcs[method] != null) {
        return Function.apply(_funcs[method], params);
      } else {
        return _instance.dispatch(method, params);
      }
    } on Exception {
      return Fault(1, 'Dispatching $method, with params $params failed');
    }
  }
}

/// A [XMLFunctionHandler] is a class that registers a map of [methods] along with their names that can be called from XMLRPC
///
/// Extend this class and override the [methods] getter specifying the XMLRPC method name, and which function it maps to
/// Optionally override the [methodHelp] to allow for introspection
/// To handle the dispatching yourself override the [dispatch] function
abstract class XMLFunctionHandler {
  Map<String, Function> get methods;
  List<String> listMethods() => methods.keys.toList();
  String methodHelp(String methodName) => '';
  dynamic dispatch(String methodName, List<dynamic> params) {
    if (methods[methodName] != null) {
      return Function.apply(methods[methodName], params);
    } else {
      return 'No function by that name exists';
    }
  }
}

/// A [SimpleXMLRPCRequestHanlder] that handles encoding and decoding messages and handing them to a [SimpleXMLRPCDispatcher]
class SimpleXMLRPCRequestHandler {
  static final rpcPaths = ['/', '/RPC2'];

  /// Accepts a HTTP [request]
  ///
  /// This method decodes the request with the encoding specified in the content-encoding header, or else the given [encoding]
  /// Then it handles the request using the [dispatcher], and responds with the appropriate response
  void _acceptRequest(HttpRequest request, SimpleXMLRPCDispatcher dispatcher,
      Encoding encoding) async {
    if (request.method == 'POST') {
      if (!_isRPCPathValid(request)) {
        return _report404(request);
      }
      try {
        final result = await _decodeRequestContent(request, encoding);
        if (result == null) {
          return;
        } else {
          final response = dispatcher._marshaledDispatch(result);
          request.response.statusCode = 200;
          request.response.headers.contentType = ContentType.parse('text/xml');
          request.response.headers.contentLength = response.length;
          request.response.write(response);
          await request.response.close();
        }
      } on Exception catch (e) {
        print('Exception $e');
        throw Exception();
      }
    } else {
      return _report404(request);
    }
  }

  /// Reports a 404 error to the [request]
  void _report404(HttpRequest request) {
    _sendResponse(request, 404, 'No such page');
  }

  /// Checks to make sure that the [request]'s path is meant for the RPC handler
  bool _isRPCPathValid(HttpRequest request) {
    return rpcPaths.contains(request.requestedUri.path);
  }

  /// Decodes the [request] with the encoding specified in the [request]'s content-encoding header or else the given [encoding]
  Future<String> _decodeRequestContent(
      HttpRequest request, Encoding encoding) async {
    final headerEncoding = request.headers.value('content-encoding');
    if (headerEncoding == null) {
      return await encoding.decoder.bind(request).join('');
    } else if (headerEncoding == 'gzip') {
      try {
        return await gzip.decoder.bind(request).join('');
      } catch (e) {
        _sendResponse(request, 400, 'Error decoding gzip content');
        return null;
      }
    } else {
      _sendResponse(request, 501, 'Encoding $headerEncoding not supported');
      return null;
    }
  }
}

/// Sends a simple Http response to the [request] with the specified [code] and [messsage]
void _sendResponse(HttpRequest request, int code, String message) {
  request.response.statusCode = 404;
  request.response.headers.contentLength = message.length;
  request.response.headers.contentType = ContentType.text;
  request.response.write(message);
  request.response.close();
}
