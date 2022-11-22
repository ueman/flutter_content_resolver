import 'dart:async';
import 'dart:ffi';

import 'package:flutter/services.dart';

/// Resolves `content:xxxx` style URI using [ContentResolver](https://developer.android.com/reference/android/content/ContentResolver).
class ContentResolver {
  ContentResolver._(this.address, this.length, this.mimeType);

  /// Buffer address.
  final int address;

  /// Buffer length.
  final int length;

  final String mimeType;

  static const MethodChannel _channel = const MethodChannel('content_resolver');

  /// Directly get the content in [Uint8List] buffer.
  static Future<ContentItem> resolveContent(String uri) async {
    final cr = await resolve(uri);
    final ret = ContentItem(Uint8List.fromList(cr.buffer), cr.mimeType);

    cr.dispose();
    return ret;
  }

  /// For advanced use only; obtaining [ContentResolver] that manages content buffer.
  /// the instance must be released by calling [dispose] method.
  static Future<ContentResolver> resolve(String uri) async {
    try {
      final result = await _channel.invokeMethod('getContent', uri);
      return ContentResolver._(
          result['address'] as int, result['length'] as int, result['mimeType'] as String);
    } on Exception {
      throw Exception('Handling URI "$uri" failed.');
    }
  }

  /// Directly writes a content as a [Uint8List]
  static Future<void> writeContent(String uri, Uint8List bytes,
      {String mode = "wt"}) async {
    try {
      await _channel.invokeMethod(
          'writeContent', {"uri": uri, "bytes": bytes, "mode": mode});
    } on Exception {
      throw Exception('Handling URI "$uri" failed.');
    }
  }

  /// Dispose the associated native buffer.
  Future<void> dispose() async {
    await _channel.invokeMethod('releaseBuffer', address);
  }

  /// Buffer that contains the content.
  Uint8List get buffer =>
      Pointer<Uint8>.fromAddress(address).asTypedList(length);
}

// represents content item 
class ContentItem {
  /// byte buffer that contains the content
  Uint8List buffer;
  /// mimetype of the content
  String mimeType;

  ContentItem(this.buffer, this.mimeType);
}
