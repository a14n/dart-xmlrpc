// Copyright (c) 2015, Alexandre Ardhuin. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in the
// LICENSE file.
import 'package:xml_rpc/client.dart' as xml_rpc;

void main() async {
  const url = 'https://api.flickr.com/services/xmlrpc';
  try {
    var result = await xml_rpc.call(
      url,
      'flickr.panda.getList',
      [
        {'api_key': 'yourApiKey'}
      ],
    );
    print(result);
  } catch (e) {
    print(e);
  }
}
