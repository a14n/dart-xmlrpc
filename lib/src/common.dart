// Copyright (c) 2015, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.

import 'dart:convert' show base64;

/// An object corresponding to a `<fault>` in the response.
class Fault {
  /// The code contained in <faultCode>.
  final int code;

  /// The text contained in <faultString>.
  final String text;

  Fault(this.code, this.text);

  @override
  String toString() => 'Fault[code:$code,text:$text]';

  @override
  bool operator ==(Object other) =>
      other is Fault && code == other.code && text == other.text;

  @override
  int get hashCode => (23 * 37 + code.hashCode) * 37 + text.hashCode;
}

/// A container for a base64 encoded value.
class Base64Value {
  String? _base64String;
  List<int>? _bytes;

  Base64Value(this._bytes);
  Base64Value.fromBase64String(this._base64String);

  String get base64String => _base64String ??= base64.encode(_bytes!);

  List<int> get bytes => _bytes ??= base64.decode(_base64String!);
}
