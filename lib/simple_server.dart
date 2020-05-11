import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:xml/xml.dart';

import 'server.dart';
import 'src/common.dart';

export 'server.dart';

/// A [XmlRpcServer] that handles the XMLRPC server protocol with a single threaded [HttpServer]
class SimpleXmlRpcServer extends XmlRpcServer {
  /// The [HttpServer] used for handling responses
  HttpServer _httpServer;

  /// Creates a [SimpleXmlRpcServer]
  SimpleXmlRpcServer({
    @required String host,
    @required int port,
    @required XmlRpcHandler handler,
    Encoding encoding = utf8,
  }) : super(host: host, port: port, handler: handler, encoding: encoding);

  /// Starts up the [_httpServer] and starts listening to requests
  @override
  Future<void> start() async {
    _httpServer = await HttpServer.bind(host, port);
    _httpServer.listen((req) => acceptRequest(req, encoding));
  }

  /// Stops the [_httpServer]
  ///
  /// [force] determines whether to stop the [HttpServer] immediately even if there are open connections
  @override
  Future<void> stop({bool force = false}) async {
    await _httpServer.close(force: force);
  }
}

/// A [XmlRpcServer] that handles the XMLRPC server protocol.
///
/// Subclasses must provide a http server to bind to the host / port and listen for incoming requests.
///
/// The fault codes specified are from the spec [here](http://xmlrpc-epi.sourceforge.net/specs/rfc.fault_codes.php)
abstract class XmlRpcServer {
  static final rpcPaths = ['/', '/RPC2'];

  /// The [host] uri
  final String host;

  /// The [port] to host the server on
  final int port;

  /// The [Encoding] to use as default, this defaults to [utf8]
  final Encoding encoding;

  /// The [XmlRpcHandler] used for method lookup and handling
  final XmlRpcHandler handler;

  /// Creates a [XmlRpcServer] that will bind to the specified [host] and [port]
  ///
  /// as well as the String [encoding] for http requests and responses
  ///
  /// You must await the call to [serverForever] to start up the server
  /// before making any client requests
  XmlRpcServer({
    @required this.host,
    @required this.port,
    @required this.handler,
    this.encoding = utf8,
  });

  /// Starts up the [XmlRpcServer] and starts listening to requests
  Future<void> start();

  /// Stops the [XmlRpcServer]
  ///
  /// [force] determines whether to stop the [XmlRpcServer] immediately even if there are open connections
  Future<void> stop({bool force = false});

  /// Accepts a HTTP [request]
  ///
  /// This method decodes the request with the encoding specified in the content-encoding header, or else the given [encoding]
  /// Then it handles the request using the [dispatcher], and responds with the appropriate response
  @protected
  void acceptRequest(HttpRequest request, Encoding encoding) async {
    final httpResponse = request.response;
    if (request.method != 'POST' || !_isRPCPathValid(request)) {
      _report404(httpResponse);
      return;
    }
    try {
      final xmlRpcRequest = await encoding.decodeStream(request);
      final response = await handler.handle(parse(xmlRpcRequest));
      await _sendResponse(httpResponse, response);
    } on XmlRpcRequestFormatException {
      await _sendResponse(httpResponse,
          handler.handleFault(Fault(-32602, 'invalid method parameters')));
    } on XmlRpcMethodNotFoundException {
      await _sendResponse(httpResponse,
          handler.handleFault(Fault(-32601, 'requested method not found')));
    } on XmlRpcCallException catch (e) {
      await _sendResponse(
          httpResponse,
          handler.handleFault(
              Fault(-32603, 'internal xml-rpc error : ${e.cause}')));
    } on XmlRpcResponseEncodingException {
      await _sendResponse(httpResponse,
          handler.handleFault(Fault(-32603, 'unsupported response')));
    } on Exception catch (e) {
      print('Exception $e');
      rethrow;
    }
  }

  /// Reports a 404 error to the [httpResponse]
  void _report404(HttpResponse httpResponse) {
    _sendError(httpResponse, 404, 'No such page');
  }

  /// Checks to make sure that the [request]'s path is meant for the RPC handler
  bool _isRPCPathValid(HttpRequest request) {
    return rpcPaths.contains(request.requestedUri.path);
  }
}

/// Sends an Http error to the [httpResponse] with the specified [code] and [messsage]
Future<void> _sendError(HttpResponse httpResponse, int code, String message) =>
    (httpResponse
          ..statusCode = code
          ..headers.contentLength = message.length
          ..headers.contentType = ContentType.text
          ..write(message))
        .close();

/// Sends a xmlrpc message to [httpResponse] with the specified [xml].
Future<void> _sendResponse(HttpResponse httpResponse, XmlDocument xml) {
  final text = xml.toXmlString();
  return (httpResponse
        ..statusCode = 200
        ..headers.contentLength = text.length
        ..headers.contentType = ContentType.parse('text/xml')
        ..write(text))
      .close();
}
