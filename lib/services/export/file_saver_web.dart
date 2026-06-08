import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Web implementation: builds a Blob and clicks a temporary download anchor.
Future<String?> saveBytesImpl(
  Uint8List bytes,
  String filename,
  String mime,
) async {
  final web.Blob blob = web.Blob(
    <JSUint8Array>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mime),
  );
  final String url = web.URL.createObjectURL(blob);
  final web.HTMLAnchorElement anchor =
      web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = filename
        ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return null;
}
