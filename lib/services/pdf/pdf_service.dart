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

  /// Assam Running Account Bill — Form 25 (Assam Schedule III Sec II).
  Future<Uint8List> form25({
    required Scheme scheme,
    required Bill bill,
    required List<BillItem> items,
    Contractor? contractor,
  }) async {
    final pw.Document doc = pw.Document(theme: await PdfTheme.theme());

    const PdfColor blue = PdfColor.fromInt(0xFF0000CC);
    const double fs = 8.0;
    const double fsSmall = 7.0;
    const double fsMed = 8.5;
    const double fsLarge = 10.0;
    final pw.TextStyle baseStyle =
        pw.TextStyle(fontSize: fs, color: blue);
    final pw.TextStyle boldStyle =
        pw.TextStyle(fontSize: fs, fontWeight: pw.FontWeight.bold, color: blue);
    final pw.TextStyle boldLarge =
        pw.TextStyle(fontSize: fsLarge, fontWeight: pw.FontWeight.bold, color: blue);

    final String contractorName = contractor?.name ?? '-';
    final String contractorAddr = contractor?.address ?? '';
    final bool isFirstBill = bill.previousAmount == 0;
    final double totalUptoDate = bill.grossAmount;
    final double totalSincePrev =
        isFirstBill ? totalUptoDate : (totalUptoDate - bill.previousAmount);

    // --- Page 1 header (printed only once via MultiPage firstPageHeader) ---
    pw.Widget firstPageHeader(pw.Context ctx) {
      pw.Widget lv(String label, String value) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
            child: pw.Row(children: <pw.Widget>[
              pw.SizedBox(
                  width: 140,
                  child: pw.Text(label, style: boldStyle)),
              pw.Text(': ', style: baseStyle),
              pw.Expanded(child: pw.Text(value, style: baseStyle)),
            ]),
          );

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Center(
            child: pw.Column(children: <pw.Widget>[
              pw.Text('Assam Schedule III Sec II Form No. 25',
                  style: pw.TextStyle(fontSize: fsSmall, color: blue)),
              pw.SizedBox(height: 1),
              pw.Text('F.R. Form No. 29',
                  style: pw.TextStyle(fontSize: fsSmall, color: blue)),
              pw.SizedBox(height: 4),
              pw.Text(
                  '[Final payment must invariably be made on Forms No. 25(A) Schedule (III - II)]',
                  style: pw.TextStyle(fontSize: fsSmall, color: blue)),
              pw.SizedBox(height: 2),
              pw.Text('RUNNING ACCOUNT BILL (C)', style: boldLarge),
              pw.Text('(See Final Rule 506)',
                  style: pw.TextStyle(fontSize: fsSmall, color: blue)),
              pw.SizedBox(height: 1),
              pw.Text(
                  '(For Contractors and Suppliers \u2013 This form provides only for payment for works or suppliers actual measured)',
                  style: pw.TextStyle(fontSize: fsSmall, color: blue),
                  textAlign: pw.TextAlign.center),
            ]),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Text('Cash Book Voucher No: _______________', style: baseStyle),
              pw.Text('Date: _______________', style: baseStyle),
            ],
          ),
          pw.SizedBox(height: 4),
          lv('Name of Work', scheme.schemeName),
          lv('Name of Contractor',
              contractorAddr.isEmpty
                  ? contractorName
                  : '$contractorName, $contractorAddr'),
          lv('Purpose of Supply {}', ''),
          lv('Serial No. of Bill',
              '${bill.billType ?? "RA Bill"}   dated   ${Formatters.date(bill.billDate)}'),
          lv('No. & date of last Bill', ''),
          lv('Reference to Agreement',
              'F.W.O. No: ${scheme.workOrderNumber ?? "-"}'
              '${scheme.workOrderDate != null ? "  dtd. ${Formatters.date(scheme.workOrderDate)}" : ""}'),
          lv('Tender No', scheme.tenderNumber ?? '-'),
          lv('Date of commencement', Formatters.date(scheme.startDate)),
          lv('Date of completion',
              scheme.status == 'Completed'
                  ? 'Completed'
                  : Formatters.date(scheme.targetCompletionDate)),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text('1. Account of work done for suppliers made.',
                style: boldStyle),
          ),
          pw.SizedBox(height: 3),
        ],
      );
    }

    // --- Reusable table header row ---
    pw.TableRow tableHeaderRow() {
      pw.Widget hc(String text, {pw.TextAlign align = pw.TextAlign.center}) =>
          pw.Padding(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Text(text,
                style: pw.TextStyle(
                    fontSize: fsSmall, fontWeight: pw.FontWeight.bold, color: blue),
                textAlign: align),
          );
      return pw.TableRow(children: <pw.Widget>[
        hc('Unit'),
        hc('Quantity\nexecuted\nfor Supplied\nupto date\nas per\nmeasureme\nnt Book'),
        hc('Name of Work or Suppliers (grouped under Sub\n- heads and Sub- works of estimate'),
        hc('Rate'),
        hc('Amount\n\nUpto Date'),
        hc('Since- previous bill\nTotal for ( each Sub\nhead )'),
        hc('Remarks'),
      ]);
    }

    pw.TableRow colNumberRow() {
      pw.Widget cn(String text) => pw.Padding(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Text(text,
                style: boldStyle, textAlign: pw.TextAlign.center),
          );
      return pw.TableRow(children: <pw.Widget>[
        cn('1'),
        cn('2.00'),
        cn('3'),
        cn('4'),
        cn('5'),
        cn('6'),
        cn('7'),
      ]);
    }

    pw.TableRow subHeaderRow() {
      pw.Widget sh(String text) => pw.Padding(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Text(text,
                style: boldStyle, textAlign: pw.TextAlign.center),
          );
      return pw.TableRow(children: <pw.Widget>[
        pw.SizedBox(),
        pw.SizedBox(),
        pw.Row(children: <pw.Widget>[
          pw.SizedBox(width: 20, child: sh('SL')),
          pw.SizedBox(width: 24, child: sh('BOQ')),
          pw.Expanded(child: sh('Description')),
        ]),
        pw.SizedBox(),
        pw.SizedBox(),
        pw.SizedBox(),
        pw.SizedBox(),
      ]);
    }

    // --- Data rows ---
    List<pw.TableRow> dataRows() {
      final List<pw.TableRow> rows = <pw.TableRow>[];
      for (int i = 0; i < items.length; i++) {
        final BillItem item = items[i];
        final double sincePrev = isFirstBill ? item.amount : 0;
        pw.Widget c(String text, {pw.TextAlign align = pw.TextAlign.left}) =>
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              child: pw.Text(text, style: baseStyle, textAlign: align),
            );

        rows.add(pw.TableRow(children: <pw.Widget>[
          c(item.unit ?? '', align: pw.TextAlign.center),
          c(Formatters.quantity(item.quantity), align: pw.TextAlign.right),
          // Column 3: SL + BOQ + Description combined
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.SizedBox(
                    width: 20,
                    child: pw.Text('${i + 1}', style: baseStyle,
                        textAlign: pw.TextAlign.center)),
                pw.SizedBox(
                    width: 24,
                    child: pw.Text(item.itemNo ?? '${i + 1}', style: baseStyle,
                        textAlign: pw.TextAlign.center)),
                pw.Expanded(
                  child: pw.Text(item.description ?? '', style: baseStyle),
                ),
              ],
            ),
          ),
          c('Rs. ${Formatters.currency2(item.rate)}', align: pw.TextAlign.right),
          c('Rs. ${Formatters.currency2(item.amount)}', align: pw.TextAlign.right),
          c('Rs. ${Formatters.currency2(sincePrev)}', align: pw.TextAlign.right),
          c('', align: pw.TextAlign.left),
        ]));
      }
      return rows;
    }

    // --- Total row ---
    pw.TableRow totalRow(String label, double uptoDate, double sincePrev) {
      pw.Widget c(String text, {bool bold = false, pw.TextAlign align = pw.TextAlign.right}) =>
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            child: pw.Text(text,
                style: bold ? boldStyle : baseStyle, textAlign: align),
          );
      return pw.TableRow(children: <pw.Widget>[
        pw.SizedBox(),
        pw.SizedBox(),
        c(label, bold: true, align: pw.TextAlign.right),
        pw.SizedBox(),
        c('Rs. ${Formatters.currency2(uptoDate)}', bold: true),
        c('Rs. ${Formatters.currency2(sincePrev)}', bold: true),
        pw.SizedBox(),
      ]);
    }

    final Map<int, pw.TableColumnWidth> colWidths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(30),  // Unit
      1: const pw.FixedColumnWidth(45),  // Quantity
      2: const pw.FlexColumnWidth(3),    // SL/BOQ/Description
      3: const pw.FixedColumnWidth(58),  // Rate
      4: const pw.FixedColumnWidth(78),  // Amount Upto Date
      5: const pw.FixedColumnWidth(78),  // Since previous
      6: const pw.FixedColumnWidth(50),  // Remarks
    };
    final pw.TableBorder tBorder =
        pw.TableBorder.all(color: blue, width: 0.5);

    // --- Summary section ---
    pw.Widget summarySection() {
      pw.Widget summaryRow(String label, String amount, {bool bold = false}) {
        final pw.TextStyle s = bold ? boldStyle : baseStyle;
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.Row(children: <pw.Widget>[
            pw.Expanded(child: pw.Text(label, style: s)),
            pw.SizedBox(width: 120, child: pw.Text(amount, style: s, textAlign: pw.TextAlign.right)),
          ]),
        );
      }

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          summaryRow(
            'Total value of work done or supplied made to date ........................... (A)',
            'Rs. ${Formatters.currency2(totalUptoDate)}',
            bold: true,
          ),
          summaryRow(
            'Deduct the value of work or supplies shown on previous bil no......',
            'Rs. ${Formatters.currency2(bill.previousAmount)}',
          ),
          summaryRow(
            'Net value of work or supplies since previous bill .........................(B)',
            'Rs. ${Formatters.currency2(totalSincePrev)}',
            bold: true,
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              '(${Formatters.amountInWords(totalSincePrev)})',
              style: pw.TextStyle(fontSize: fsMed, color: blue),
            ),
          ),
        ],
      );
    }

    // --- Section II: Certificate and Signatures ---
    pw.Widget certificateSection() {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text('II . Certificate and Signatures',
                style: boldStyle),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'The measurements were made by me and are record at page No ___ to ___ '
            'of Measurement Book No. ________ (Abstract) and page No ___ to ___ '
            'of Measurement Book No. ________ respectively',
            style: baseStyle,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'No advance payment has been made previously without detailed measurements.',
            style: baseStyle,
          ),
          pw.SizedBox(height: 14),
          // Signature block 1: Thumb impression + Officer preparing
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: <pw.Widget>[
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text('Thumb impression', style: pw.TextStyle(
                      fontSize: fs, fontStyle: pw.FontStyle.italic, color: blue)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: <pw.Widget>[
                  pw.Container(width: 160, child: pw.Divider(color: blue)),
                  pw.Text('Dated Signature of Officer', style: baseStyle),
                  pw.Text('preparing the bill', style: baseStyle),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text('(Rank )', style: baseStyle),
                  pw.Text('..................sub-division', style: baseStyle),
                  pw.Text('..................division', style: baseStyle),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          // Signature block 2: Contractor
          pw.Text('Dated Signature of', style: pw.TextStyle(
              fontSize: fs, fontStyle: pw.FontStyle.italic, color: blue)),
          pw.Text('   Contractor', style: pw.TextStyle(
              fontSize: fs, fontStyle: pw.FontStyle.italic, color: blue)),
          pw.SizedBox(height: 10),
          // Signature block 3: Officer authorizing payment
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: <pw.Widget>[
              pw.SizedBox(width: 100),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: <pw.Widget>[
                  pw.Container(width: 160, child: pw.Divider(color: blue)),
                  pw.Text('Dated Signature of Officer', style: baseStyle),
                  pw.Text('authorizing Payment', style: baseStyle),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text('(Rank)', style: baseStyle),
                  pw.Text('....................sub-division', style: baseStyle),
                  pw.Text('.................... division', style: baseStyle),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'The signature is necessary only when the officer preparing the bill for the officer who '
            'authorises the payment in such a case dated signature are essential.',
            style: pw.TextStyle(fontSize: 6, color: blue),
          ),
        ],
      );
    }

    // Build the document. The metadata header is part of the flowing content
    // (page 1 only); the table flows across pages and gets a repeated column
    // header on every continuation page via the MultiPage `header` callback.
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context ctx) {
          if (ctx.pageNumber == 1) return pw.SizedBox();
          // Continuation pages: repeat the table column header.
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Table(
              border: tBorder,
              columnWidths: colWidths,
              children: <pw.TableRow>[tableHeaderRow(), colNumberRow()],
            ),
          );
        },
        footer: (pw.Context ctx) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 4),
          child: pw.Text('[${ctx.pageNumber}]',
              style: pw.TextStyle(fontSize: 7, color: blue)),
        ),
        build: (pw.Context ctx) => <pw.Widget>[
          firstPageHeader(ctx),
          // Single table: it carries its own header rows at the top and flows
          // across pages.
          pw.Table(
            border: tBorder,
            columnWidths: colWidths,
            children: <pw.TableRow>[
              tableHeaderRow(),
              colNumberRow(),
              subHeaderRow(),
              ...dataRows(),
              totalRow('TOTAL  (i) =', totalUptoDate, totalSincePrev),
            ],
          ),
          pw.SizedBox(height: 4),
          summarySection(),
          certificateSection(),
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

  /// Generic certificate document.
  Future<Uint8List> certificate({
    required Scheme scheme,
    required Certificate certificate,
  }) async {
    final pw.Document doc = pw.Document(theme: await PdfTheme.theme());
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
    final pw.Document doc = pw.Document(theme: await PdfTheme.theme());
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
    final pw.Document doc = pw.Document(theme: await PdfTheme.theme());
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
