import 'package:xml_rpc/client.dart' as client;
import 'package:xml_rpc/simple_server.dart' as server;

void main() async {
  const url = '127.0.0.1';
  const port = 8080;
  final h = server.XmlRpcHandler(methods: {
    'hello': (Map params) {
      print(params['api_key']);
      return 1;
    }
  });
  final s = server.SimpleXmlRpcServer(host: url, port: port, handler: h);
  await s.start();
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

  await s.stop();
}
