import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// A parsed BOQ line before it is persisted as a [BoqItem].
class ParsedBoqRow {
  final String? itemNo;
  final String description;
  final String? unit;
  final double quantity;
  final double rate;
  final double amount;

  ParsedBoqRow({
    this.itemNo,
    required this.description,
    this.unit,
    this.quantity = 0,
    this.rate = 0,
    double? amount,
  }) : amount = amount ?? (quantity * rate);
}

class BoqImportResult {
  final String fileName;
  final String format;
  final List<ParsedBoqRow> rows;

  const BoqImportResult({
    required this.fileName,
    required this.format,
    required this.rows,
  });
}

/// Imports BOQ data from Excel, CSV or PDF files with column auto-detection.
class BoqImportService {
  const BoqImportService();

  Future<BoqImportResult?> pickAndParse() async {
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['xlsx', 'xls', 'csv', 'pdf'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final PlatformFile file = picked.files.first;
    final Uint8List? bytes = file.bytes;
    if (bytes == null) return null;

    final String ext = (file.extension ?? '').toLowerCase();
    final List<ParsedBoqRow> rows;
    switch (ext) {
      case 'xlsx':
      case 'xls':
        rows = parseExcel(bytes);
        break;
      case 'csv':
        rows = parseCsv(bytes);
        break;
      case 'pdf':
        rows = parsePdf(bytes);
        break;
      default:
        rows = <ParsedBoqRow>[];
    }
    return BoqImportResult(
        fileName: file.name, format: ext.toUpperCase(), rows: rows);
  }

  List<ParsedBoqRow> parseExcel(Uint8List bytes) {
    final Excel excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return <ParsedBoqRow>[];
    final Sheet sheet = excel.tables.values.first;
    final List<List<Object?>> matrix = sheet.rows
        .map((List<Data?> r) =>
            r.map<Object?>((Data? c) => c?.value?.toString()).toList())
        .toList();
    return _fromMatrix(matrix);
  }

  List<ParsedBoqRow> parseCsv(Uint8List bytes) {
    final String content = String.fromCharCodes(bytes);
    final List<List<dynamic>> matrix =
        const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
            .convert(content);
    return _fromMatrix(matrix);
  }

  /// Heuristic PDF parse: extract text, split into lines and pull numeric tail.
  List<ParsedBoqRow> parsePdf(Uint8List bytes) {
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final String text = PdfTextExtractor(document).extractText();
    document.dispose();

    final List<ParsedBoqRow> rows = <ParsedBoqRow>[];
    final RegExp numbers = RegExp(r'([0-9][0-9,]*\.?[0-9]*)');
    for (final String raw in text.split('\n')) {
      final String line = raw.trim();
      if (line.isEmpty) continue;
      final List<RegExpMatch> matches = numbers.allMatches(line).toList();
      if (matches.length < 3) continue;
      final List<double> nums = matches
          .map((RegExpMatch m) =>
              double.tryParse(m.group(1)!.replaceAll(',', '')) ?? 0)
          .toList();
      // Assume last three numbers are qty, rate, amount.
      final double amount = nums[nums.length - 1];
      final double rate = nums[nums.length - 2];
      final double qty = nums[nums.length - 3];
      final int descEnd = matches[matches.length - 3].start;
      final String desc = line.substring(0, descEnd).trim();
      if (desc.isEmpty) continue;
      rows.add(ParsedBoqRow(
        description: desc,
        quantity: qty,
        rate: rate,
        amount: amount,
      ));
    }
    return rows;
  }

  List<ParsedBoqRow> _fromMatrix(List<List<dynamic>> matrix) {
    if (matrix.isEmpty) return <ParsedBoqRow>[];

    // Find a header row containing recognisable column names.
    int headerIndex = -1;
    Map<String, int> cols = <String, int>{};
    for (int i = 0; i < matrix.length && i < 8; i++) {
      final Map<String, int> detected = _detectColumns(matrix[i]);
      if (detected.containsKey('description')) {
        headerIndex = i;
        cols = detected;
        break;
      }
    }
    if (headerIndex == -1) return <ParsedBoqRow>[];

    final List<ParsedBoqRow> rows = <ParsedBoqRow>[];
    for (int i = headerIndex + 1; i < matrix.length; i++) {
      final List<dynamic> row = matrix[i];
      String cell(String key) {
        final int? idx = cols[key];
        if (idx == null || idx >= row.length) return '';
        return (row[idx]?.toString() ?? '').trim();
      }

      final String description = cell('description');
      if (description.isEmpty) continue;
      final double qty = _num(cell('quantity'));
      final double rate = _num(cell('rate'));
      final double amount = _num(cell('amount'));
      rows.add(ParsedBoqRow(
        itemNo: cell('item').isEmpty ? null : cell('item'),
        description: description,
        unit: cell('unit').isEmpty ? null : cell('unit'),
        quantity: qty,
        rate: rate,
        amount: amount > 0 ? amount : qty * rate,
      ));
    }
    return rows;
  }

  Map<String, int> _detectColumns(List<dynamic> headerRow) {
    final Map<String, int> result = <String, int>{};
    for (int i = 0; i < headerRow.length; i++) {
      final String h = (headerRow[i]?.toString() ?? '').toLowerCase().trim();
      if (h.isEmpty) continue;
      if (result['item'] == null &&
          (h.contains('item') || h == 'sl' || h.contains('sr') || h.contains('s.no'))) {
        result['item'] = i;
      } else if (result['description'] == null &&
          (h.contains('desc') || h.contains('particular') || h.contains('work'))) {
        result['description'] = i;
      } else if (result['unit'] == null &&
          (h == 'unit' || h.contains('uom'))) {
        result['unit'] = i;
      } else if (result['quantity'] == null &&
          (h.contains('qty') || h.contains('quantity'))) {
        result['quantity'] = i;
      } else if (result['rate'] == null && h.contains('rate')) {
        result['rate'] = i;
      } else if (result['amount'] == null &&
          (h.contains('amount') || h.contains('value'))) {
        result['amount'] = i;
      }
    }
    return result;
  }

  double _num(String value) {
    if (value.isEmpty) return 0;
    return double.tryParse(value.replaceAll(',', '').replaceAll('\u20B9', '').trim()) ??
        0;
  }
}
