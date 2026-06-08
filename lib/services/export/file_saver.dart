import 'dart:typed_data';

import 'file_saver_io.dart' if (dart.library.js_interop) 'file_saver_web.dart'
    as impl;

/// Saves [bytes] to the device (native) or triggers a browser download (web).
///
/// Returns the saved file path on native platforms, or `null` on web.
class FileSaver {
  const FileSaver._();

  static Future<String?> save(
    Uint8List bytes,
    String filename,
    String mime,
  ) =>
      impl.saveBytesImpl(bytes, filename, mime);
}
