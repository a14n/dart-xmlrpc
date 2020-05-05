import 'package:xml_rpc/client.dart' as client;
import 'package:xml_rpc/server.dart' as server;

void main() async {
  const url = '127.0.0.1';
  const port = 8080;
  final s = server.SimpleXMLRPCServer(url, port);
  s.registerInstance(ServiceHandler());
  await s.serveForever();
  try {
    print('calling service');
    var result = await client.call(
      'http://localhost:$port',
      'hello',
      [
        {'api_key': 'yourApiKey'}
      ],
    );
    print(result);
  } catch (e) {
    print(e);
  }
}

class ServiceHandler extends server.XMLFunctionHandler {
  @override
  Map<String, Function> get methods => {'hello': hello};

  int hello(Map params) {
    print(params['api_key']);
    return 1;
  }
}
