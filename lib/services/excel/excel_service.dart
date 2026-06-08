import 'dart:typed_data';

import 'package:excel/excel.dart';

/// A single logical sheet definition for export.
class ExcelSheetData {
  final String name;
  final List<String> headers;
  final List<List<Object?>> rows;

  const ExcelSheetData({
    required this.name,
    required this.headers,
    required this.rows,
  });
}

/// Builds native .xlsx workbooks for registers, summaries and audit exports.
class ExcelService {
  const ExcelService();

  Uint8List buildWorkbook(List<ExcelSheetData> sheets) {
    final Excel excel = Excel.createExcel();
    final String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';

    for (final ExcelSheetData data in sheets) {
      final Sheet sheet = excel[data.name];
      sheet.appendRow(
        data.headers.map<CellValue?>((String h) => TextCellValue(h)).toList(),
      );
      for (final List<Object?> row in data.rows) {
        sheet.appendRow(row.map(_toCell).toList());
      }
    }

    // Remove the auto-created default sheet if we added our own.
    if (sheets.isNotEmpty && sheets.every((ExcelSheetData s) => s.name != defaultSheet)) {
      excel.delete(defaultSheet);
    }

    final List<int>? bytes = excel.save();
    return Uint8List.fromList(bytes ?? <int>[]);
  }

  Uint8List buildSheet({
    required String name,
    required List<String> headers,
    required List<List<Object?>> rows,
  }) =>
      buildWorkbook(<ExcelSheetData>[
        ExcelSheetData(name: name, headers: headers, rows: rows),
      ]);

  static CellValue? _toCell(Object? value) {
    if (value == null) return TextCellValue('');
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    if (value is bool) return TextCellValue(value ? 'Yes' : 'No');
    return TextCellValue(value.toString());
  }
}
