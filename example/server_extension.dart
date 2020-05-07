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
  // Sequential calls to the service
  await callService();
  await callService();

  // Asyncronous calls to the service
  callService();
  callService();
  await Future.delayed(Duration(milliseconds: 10));

  try {
    // A missing method
    await client.call(clientURI, 'nonExistantMethod', [],
        decodeCodecs: [...client.standardCodecs, nilCodec]);
  } catch (e) {
    print(e);
  }

  try {
    // Wrong number of arguments
    await client.call(clientURI, 'hello', ['1', 1, 10],
        decodeCodecs: [...client.standardCodecs, nilCodec]);
  } catch (e) {
    print(e);
  }
  print('here');
  await callService();
  try {
    // A wrong map key
    await client.call(
      clientURI,
      'hello',
      [
        {'api_keys': 'yourApiKey'}
      ],
      decodeCodecs: [...client.standardCodecs, nilCodec],
    );
  } catch (e) {
    print(e);
  }

  try {
    // Invalid encoding
    await client.call(
      clientURI,
      'createClass',
      [],
      decodeCodecs: [...client.standardCodecs],
    );
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
    methods['createClass'] = createClass;
  }

  int hello(Map params) {
    if (params['api_key'] == null) {
      throw Exception('The api key parameter was not given');
    }
    print(params['api_key']);

    clientNum += 1;
    return clientNum;
  }

  SomeClass createClass() {
    return SomeClass(true);
  }
}

class SomeClass {
  final bool aBool;

  SomeClass(this.aBool);
}
