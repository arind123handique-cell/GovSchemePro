import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Bundles scheme artefacts (PDFs, Excel, JSON) into a single audit ZIP.
class AuditService {
  const AuditService();

  /// [files] maps an in-archive path to its bytes.
  Uint8List buildZip(Map<String, Uint8List> files) {
    final Archive archive = Archive();
    files.forEach((String name, Uint8List bytes) {
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    });
    final List<int>? encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded ?? <int>[]);
  }
}
