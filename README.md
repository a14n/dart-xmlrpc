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
with the result received. If the response contains a `<fault>` a `Fault` object is
thrown and can be catch with the `.catchError()` on the `Future`.

To use this package from browser you can provide as `client` optional named
argument on `call` a `http.BrowserClient`.

## Parameter types

Here are the conversion table.

| xmlrpc               | Dart                 |
| -------------------- | -------------------- |
| `<int>` or `<i4>`    | int                  |
| `<boolean>`          | bool                 |
| `<string>` or Text   | String               |
| `<double>`           | double               |
| `<dateTime.iso8601>` | DateTime             |
| `<base64>`           | Base64Value          |
| `<struct>`           | Map<String, dynamic> |
| `<array>`            | List                 |

## XML-RPC Extension Types

Some XML-RPC implementations handle additionnal types. For instance [Apache ws-xmlrpc](https://ws.apache.org/xmlrpc)
may support long values with `<i8>` and other types (see https://ws.apache.org/xmlrpc/types.html).

You can provide custom codecs that will be used to encode and decode those
values.

If you use the [XML-RPC for C and C++](http://xmlrpc-c.sourceforge.net) library
on the server side you can directly use the dart library `client_c.dart` to be
able to handle `<i8>` and `<nil>`.

## Using this package on JS side

If you use this package on JS side you may face some problem dealing with
numbers. On JS side there are no difference between `int` and `double`. So by
default an double `1.0` will be encoded as `<int>1</int>`.

You can workaround this issue:
- wrap doubles in a custom type:
  ```dart
  class _Double {
    _Double(this.value) : assert(value != null);
    final double value;
  }
  ```
- create a codec for this wrapper type:
  ```dart
  final _doubleWrapperCodec = new SimpleCodec<_Double>(
    nodeLocalName: 'double',
    encodeValue: (value) => value.value.toString(),
    decodeValue: (text) => new _Double(double.parse(text)),
  );
  ```
- create a list of codecs:
  ```dart
  final codecs = new List<Codec>.unmodifiable(<Codec>[
    _doubleWrapperCodec,
    intCodec,
    boolCodec,
    stringCodec,
    dateTimeCodec,
    base64Codec,
    structCodec,
    arrayCodec,
  ]);
  ```
- make calls with your codecs:
  ```dart
  main() {
    xml_rpc.call(url, 'method', [params], encodeCodecs: codecs, decodeCodecs: codecs);
  }
  ```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/a14n/dart-xmlrpc/issues
[xmlrpc]: http://xmlrpc.scripting.com/spec.html
