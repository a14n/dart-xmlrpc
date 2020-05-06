import 'package:xml_rpc/client.dart' as client;
import 'package:xml_rpc/server.dart' as server;

const port = 8080;
const url = '127.0.0.1';

final clientURI = 'http://localhost:$port';
void main() async {
  final s = server.SimpleXmlRpcServer(
      host: url, port: port, requestHandler: MyXmlRpcHandler());
  await s.serveForever();
  try {
    await callService();
    await callService();
    callService();
    callService();
    await Future.delayed(Duration(milliseconds: 10));
    final response = await client.call(clientURI, 'nonExistantMethod', []);
    print(response);
  } catch (e) {
    print(e);
  }
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
