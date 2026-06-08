import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/bill.dart';
import '../../data/models/certificate.dart';
import '../../data/models/contractor.dart';
import '../../data/models/scheme.dart';
import 'pdf_theme.dart';

/// Native PDF generation for bills, certificates and reports.
class PdfService {
  const PdfService(this.settings);

  final Map<String, String> settings;

  String get _department => settings['department_name'] ?? '';
  String get _office => settings['office_name'] ?? '';
  String get _officer => settings['officer_name'] ?? '';
  String get _designation => settings['officer_designation'] ?? '';

  /// Assam Running Account Bill — Form 25.
  Future<Uint8List> form25({
    required Scheme scheme,
    required Bill bill,
    required List<BillItem> items,
    Contractor? contractor,
  }) async {
    final pw.Document doc = pw.Document();

    final List<List<String>> rows = <List<String>>[];
    for (int i = 0; i < items.length; i++) {
      final BillItem item = items[i];
      rows.add(<String>[
        item.itemNo ?? '${i + 1}',
        item.description ?? '',
        item.unit ?? '',
        Formatters.quantity(item.quantity),
        Formatters.quantity(item.rate),
        Formatters.quantity(item.amount),
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context ctx) => PdfTheme.header(
          department: _department,
          office: _office,
          title: 'RUNNING ACCOUNT BILL — FORM 25',
          subtitle: bill.billType ?? 'RA Bill',
        ),
        footer: PdfTheme.footer,
        build: (pw.Context ctx) => <pw.Widget>[
          pw.SizedBox(height: 8),
          _twoColumnMeta(<List<String>>[
            <String>['Scheme', scheme.schemeName],
            <String>['Scheme ID', scheme.id],
            <String>['Contractor', contractor?.name ?? '-'],
            <String>['Agreement / WO No.', scheme.workOrderNumber ?? '-'],
            <String>['AA No.', scheme.aaNumber ?? '-'],
            <String>['TS No.', scheme.tsNumber ?? '-'],
            <String>['Bill No.', bill.billNumber ?? '-'],
            <String>['Bill Date', Formatters.date(bill.billDate)],
          ]),
          pw.SizedBox(height: 10),
          pw.Text('I. Account of Work Executed',
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: <String>[
              'Item',
              'Description',
              'Unit',
              'Qty (upto date)',
              'Rate',
              'Amount upto date',
            ],
            data: rows,
            headerStyle: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfTheme.primary),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignments: <int, pw.Alignment>{
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
            columnWidths: <int, pw.TableColumnWidth>{
              0: const pw.FixedColumnWidth(34),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FixedColumnWidth(34),
              3: const pw.FixedColumnWidth(64),
              4: const pw.FixedColumnWidth(54),
              5: const pw.FixedColumnWidth(74),
            },
            border: pw.TableBorder.all(color: PdfTheme.border, width: 0.5),
          ),
          pw.SizedBox(height: 12),
          _abstract(bill),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: const pw.BoxDecoration(color: PdfTheme.secondary),
            child: pw.Text(
              'Net Amount Payable: ${Formatters.amountInWords(bill.netPayable)}',
              style: pw.TextStyle(
                  fontSize: 10, fontStyle: pw.FontStyle.italic),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: <pw.Widget>[
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.SizedBox(height: 40),
                  pw.Container(
                      width: 160, child: pw.Divider(color: PdfTheme.border)),
                  pw.Text("Contractor's Signature",
                      style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              PdfTheme.signatureBlock(_officer, _designation),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _twoColumnMeta(List<List<String>> entries) {
    final int half = (entries.length / 2).ceil();
    final List<List<String>> left = entries.sublist(0, half);
    final List<List<String>> right = entries.sublist(half);
    pw.Widget col(List<List<String>> rows) => pw.Column(
          children: rows
              .map((List<String> r) => PdfTheme.labelValue(r[0], r[1]))
              .toList(),
        );
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Expanded(child: col(left)),
        pw.SizedBox(width: 16),
        pw.Expanded(child: col(right)),
      ],
    );
  }

  pw.Widget _abstract(Bill bill) {
    pw.TableRow row(String label, num value, {bool bold = false}) {
      return pw.TableRow(children: <pw.Widget>[
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: pw.Text(Formatters.currency(value),
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
      ]);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfTheme.border, width: 0.5),
      columnWidths: <int, pw.TableColumnWidth>{
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
      },
      children: <pw.TableRow>[
        row('Gross value of work done (A)', bill.grossAmount, bold: true),
        row('Less: Amount of previous bill', bill.previousAmount),
        row('Net value of this bill (B)', bill.netAmount, bold: true),
        row('Less: Security Deposit', bill.securityDeposit),
        row('Less: GST', bill.gst),
        row('Less: Labour Cess', bill.labourCess),
        row('Less: Income Tax', bill.incomeTax),
        row('Less: Royalty', bill.royalty),
        row('Less: Other Recoveries', bill.otherRecoveries),
        row('Total Deductions', bill.totalDeductions, bold: true),
        row('Net Amount Payable', bill.netPayable, bold: true),
      ],
    );
  }

  /// Generic certificate document.
  Future<Uint8List> certificate({
    required Scheme scheme,
    required Certificate certificate,
  }) async {
    final pw.Document doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context ctx) => PdfTheme.header(
          department: _department,
          office: _office,
          title: (certificate.title ?? certificate.type ?? 'CERTIFICATE')
              .toUpperCase(),
        ),
        footer: PdfTheme.footer,
        build: (pw.Context ctx) => <pw.Widget>[
          pw.SizedBox(height: 16),
          _twoColumnMeta(<List<String>>[
            <String>['Scheme', scheme.schemeName],
            <String>['Scheme ID', scheme.id],
            <String>['Date', Formatters.date(certificate.issuedDate)],
            <String>['Department', scheme.department ?? '-'],
          ]),
          pw.SizedBox(height: 16),
          pw.Text(
            certificate.body ?? '',
            style: const pw.TextStyle(fontSize: 11, lineSpacing: 4),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 30),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: PdfTheme.signatureBlock(
                certificate.officerName ?? _officer, _designation),
          ),
        ],
      ),
    );
    return doc.save();
  }

  /// Generic tabular report (Scheme Register, Bill Register, etc.).
  Future<Uint8List> tableReport({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    String? subtitle,
    bool landscape = true,
  }) async {
    final pw.Document doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat:
            landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context ctx) => PdfTheme.header(
          department: _department,
          office: _office,
          title: title.toUpperCase(),
          subtitle: subtitle,
        ),
        footer: PdfTheme.footer,
        build: (pw.Context ctx) => <pw.Widget>[
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfTheme.primary),
            cellStyle: const pw.TextStyle(fontSize: 8),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfTheme.border, width: 0.4)),
            ),
            cellHeight: 18,
          ),
          pw.SizedBox(height: 10),
          pw.Text('Total records: ${rows.length}',
              style: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
    return doc.save();
  }

  /// Scheme summary one-pager.
  Future<Uint8List> schemeSummary({
    required Scheme scheme,
    required Contractor? contractor,
    required double boqTotal,
    required double billedNet,
    required double physical,
    required double financial,
  }) async {
    final pw.Document doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context ctx) => PdfTheme.header(
          department: _department,
          office: _office,
          title: 'SCHEME SUMMARY',
        ),
        footer: PdfTheme.footer,
        build: (pw.Context ctx) => <pw.Widget>[
          pw.SizedBox(height: 12),
          _twoColumnMeta(<List<String>>[
            <String>['Scheme ID', scheme.id],
            <String>['Scheme Name', scheme.schemeName],
            <String>['Type', scheme.schemeType ?? '-'],
            <String>['Status', scheme.status],
            <String>['Department', scheme.department ?? '-'],
            <String>['Financial Year', scheme.financialYear ?? '-'],
            <String>['Contractor', contractor?.name ?? '-'],
            <String>['Funding', scheme.fundingSource ?? '-'],
            <String>['Tender Value', Formatters.currency(scheme.tenderValue)],
            <String>['BOQ Total', Formatters.currency(boqTotal)],
            <String>['Billed (Net)', Formatters.currency(billedNet)],
            <String>['Balance', Formatters.currency(scheme.tenderValue - billedNet)],
            <String>['Physical Progress', Formatters.percent(physical)],
            <String>['Financial Progress', Formatters.percent(financial)],
            <String>['Start Date', Formatters.date(scheme.startDate)],
            <String>['Target Completion', Formatters.date(scheme.targetCompletionDate)],
            <String>['Location', scheme.location ?? '-'],
            <String>['District', scheme.district ?? '-'],
          ]),
          if ((scheme.remarks ?? '').isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 10),
            PdfTheme.labelValue('Remarks', scheme.remarks!),
          ],
          pw.SizedBox(height: 24),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: PdfTheme.signatureBlock(_officer, _designation),
          ),
        ],
      ),
    );
    return doc.save();
  }

  /// Opens the platform print/preview dialog (also enables Save as PDF).
  static Future<void> preview(Uint8List bytes, String name) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: name,
    );
  }

  static Future<void> share(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
