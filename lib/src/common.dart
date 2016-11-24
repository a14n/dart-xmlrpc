// Copyright (c) 2015, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

library xml_rpc.src.common;

import 'dart:convert';

/// An object corresponding to a `<fault>` in the response.
class Fault {
  /// The code contained in <faultCode>.
  final int code;

  /// The text contained in <faultString>.
  final String text;

  Fault(this.code, this.text);

  @override
  String toString() => 'Fault[code:$code,text:$text]';
}

/// A container for a base64 encoded value.
class Base64Value {
  String _base64String;
  List<int> _bytes;

  Base64Value(this._bytes);
  Base64Value.fromBase64String(this._base64String);

  String get base64String {
    if (_base64String == null) {
      _base64String = BASE64.encode(_bytes);
    }
    return _base64String;
  }

  List<int> get bytes {
    if (_bytes == null) {
      _bytes = BASE64.decode(_base64String);
    }
    return _bytes;
  }
}
