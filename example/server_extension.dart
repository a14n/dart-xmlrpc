import 'package:xml_rpc/client.dart' as client;
import 'package:xml_rpc/simple_server.dart' as server;
import 'package:xml_rpc/src/converter_extension.dart';

const port = 8080;
const url = '127.0.0.1';

final clientURI = 'http://localhost:$port';
void main() async {
  final s = server.SimpleXmlRpcServer(
      host: url, port: port, handler: MyXmlRpcHandler());
  await s.start();
  try {
    await callService();
    await callService();
    callService();
    callService();
    await Future.delayed(Duration(milliseconds: 10));
    final response = await client.call(clientURI, 'nonExistantMethod', [],
        decodeCodecs: [...client.standardCodecs, nilCodec]);
    print(response);
  } catch (e) {
    print(e);
  }
  await s.stop();
}

void callService() async {
  print('calling service');
  var result = await client.call(
    clientURI,
    'hello',
    [
      {'api_key': 'yourApiKey'}
    ],
  );
  print(result);
}

class MyXmlRpcHandler extends server.XmlRpcHandler {
  int clientNum = 0;

  MyXmlRpcHandler() : super(methods: {}) {
    methods['hello'] = hello;
  }

  int hello(Map params) {
    print(params['api_key']);
    clientNum += 1;
    return clientNum;
  }
}
