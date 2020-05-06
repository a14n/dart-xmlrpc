import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:xml/xml.dart';

import '../server.dart';

/// A [XmlRpcServer] that handles the XMLRPC server protocol with a single threaded [HttpServer]
class SimpleXmlRpcServer extends XmlRpcServer {
  /// The [HttpServer] used for handling responses
  HttpServer _httpServer;

  /// Creates a [SimpleXmlRpcServer]
  SimpleXmlRpcServer({
    @required String host,
    @required int port,
    @required XmlRpcHandler requestHandler,
    Encoding encoding = utf8,
  }) : super(
            host: host,
            port: port,
            requestHandler: requestHandler,
            encoding: encoding);

  /// Starts up the [_httpServer] and starts listening to requests
  @override
  Future<void> serveForever() async {
    _httpServer = await HttpServer.bind(host, port);
    _httpServer.listen((req) => _acceptRequest(req, encoding));
  }
}

/// A [XmlRpcServer] that handles the XMLRPC server protocol
///
/// Subclasses must provide a http server to bind to the host / port and listen for incoming requests
abstract class XmlRpcServer {
  static final rpcPaths = ['/', '/RPC2'];

  /// The [host] uri
  final String host;

  /// The [port] to host the server on
  final int port;

  /// The [Encoding] to use as default, this defaults to [utf8]
  final Encoding encoding;

  /// The [XmlRpcHandler] used for method lookup and handling
  final XmlRpcHandler requestHandler;

  /// Creates a [XmlRpcServer] that will bind to the specified [host] and [port]
  ///
  /// as well as the String [encoding] for http requests and responses
  ///
  /// You must await the call to [serverForever] to start up the server
  /// before making any client requests
  XmlRpcServer({
    @required this.host,
    @required this.port,
    @required this.requestHandler,
    this.encoding = utf8,
  });

  /// Starts up the [XmlRpcServer] and starts listening to requests
  Future<void> serveForever();

  /// Accepts a HTTP [request]
  ///
  /// This method decodes the request with the encoding specified in the content-encoding header, or else the given [encoding]
  /// Then it handles the request using the [dispatcher], and responds with the appropriate response
  void _acceptRequest(HttpRequest request, Encoding encoding) async {
    if (request.method == 'POST') {
      if (!_isRPCPathValid(request)) {
        return _report404(request);
      }
      try {
        final result = await _decodeRequestContent(request, encoding);
        if (result == null) {
          return;
        } else {
          final response = requestHandler.handle(parse(result)).toXmlString();
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
