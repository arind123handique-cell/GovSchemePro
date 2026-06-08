import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../services/export/file_saver.dart';

/// Common UI helpers for snackbars, confirmations and file exports.
class UiHelpers {
  UiHelpers._();

  static void showSnack(BuildContext context, String message,
      {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
      ));
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    bool destructive = false,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: Colors.red.shade700)
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Saves bytes and shows a contextual confirmation message.
  static Future<void> exportAndNotify(
    BuildContext context, {
    required Uint8List bytes,
    required String filename,
    required String mime,
  }) async {
    try {
      final String? path = await FileSaver.save(bytes, filename, mime);
      if (!context.mounted) return;
      showSnack(
        context,
        kIsWeb
            ? 'Downloaded $filename'
            : 'Saved to ${path ?? filename}',
      );
    } catch (e) {
      if (!context.mounted) return;
      showSnack(context, 'Export failed: $e', error: true);
    }
  }
}

/// MIME constants for exports.
class Mime {
  Mime._();
  static const String pdf = 'application/pdf';
  static const String xlsx =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  static const String csv = 'text/csv';
  static const String zip = 'application/zip';
  static const String json = 'application/json';
}
