import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Native implementation: writes the file into an app exports directory.
Future<String?> saveBytesImpl(
  Uint8List bytes,
  String filename,
  String mime,
) async {
  Directory base;
  try {
    base = (await getDownloadsDirectory()) ??
        await getApplicationDocumentsDirectory();
  } catch (_) {
    base = await getApplicationDocumentsDirectory();
  }
  final Directory dir = Directory(p.join(base.path, 'GovSchemePro'));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final File file = File(p.join(dir.path, filename));
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
