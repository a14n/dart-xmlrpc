# xml_rpc

[![Build Status](https://travis-ci.org/a14n/dart-xmlrpc.svg?branch=master)](https://travis-ci.org/a14n/dart-xmlrpc)

A library to communicate through the [XML-RPC protocol][xmlrpc].

## Usage

A simple usage example:

```dart
import 'package:xml_rpc/client.dart' as xml_rpc;

main() {
  final url = '...';
  xml_rpc
      .call(url, 'examples.getStateName', [41])
      .then((result) => print(result))
      .catchError((error) => print(error));
}
```

It will sent the following xml content:

```xml
<?xml version="1.0"?>
<methodCall>
  <methodName>examples.getStateName</methodName>
  <params>
    <param>
      <value><i4>41</i4></value>
    </param>
  </params>
</methodCall>
```

Every xmlrpc call has to be done with the `call(...)` function. You must give
the url, the method name and the parameters. This function returns a `Future`
with the result received. If the response contains a <fault> a `Fault` object is
thrown and can be catch with the `.catchError()` on the `Future`.

## Parameter types

Here are the conversion table.

| xmlrpc             | Dart                 |
| ------------------ | -------------------- |
| <int>              | int                  |
| <bool>             | bool                 |
| <string>           | String               |
| <double>           | double               |
| <dateTime.iso8601> | DateTime             |
| <base64>           | Base64Value          |
| <struct>           | Map<String, dynamic> |
| <array>            | List                 |

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/a14n/dart-xmlrpc/issues
[xmlrpc]: http://xmlrpc.scripting.com/spec.html