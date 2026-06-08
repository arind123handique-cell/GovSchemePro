import 'package:intl/intl.dart';

/// Formatting helpers for currency, dates and numbers (Indian conventions).
class Formatters {
  Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9 ',
    decimalDigits: 2,
  );

  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '\u20B9 ',
    decimalDigits: 2,
  );

  static final NumberFormat _qty = NumberFormat('#,##0.###', 'en_IN');
  static final NumberFormat _currencyPlain = NumberFormat('#,##,##0.00', 'en_IN');
  static final DateFormat _date = DateFormat('dd-MM-yyyy');
  static final DateFormat _dateTime = DateFormat('dd-MM-yyyy hh:mm a');

  static String currency(num? value) => _currency.format(value ?? 0);

  /// Number-only currency format (no ₹ symbol) — for use with "Rs." prefix in PDFs.
  static String currency2(num? value) => _currencyPlain.format(value ?? 0);

  static String compactCurrency(num? value) => _compact.format(value ?? 0);

  static String quantity(num? value) => _qty.format(value ?? 0);

  static String percent(num? value) =>
      '${(value ?? 0).toStringAsFixed(1)}%';

  static String date(DateTime? value) =>
      value == null ? '-' : _date.format(value);

  static String dateTime(DateTime? value) =>
      value == null ? '-' : _dateTime.format(value);

  static String? dateNullable(DateTime? value) =>
      value == null ? null : _date.format(value);

  /// Converts a numeric amount into Indian-system words (for Form 25 / bills).
  static String amountInWords(num amount) {
    final int rupees = amount.floor();
    final int paise = ((amount - rupees) * 100).round();
    final String rupeeWords = _numberToWords(rupees);
    final StringBuffer buffer = StringBuffer();
    buffer.write('Rupees $rupeeWords');
    if (paise > 0) {
      buffer.write(' and ${_numberToWords(paise)} Paise');
    }
    buffer.write(' Only');
    return buffer.toString();
  }

  static const List<String> _ones = <String>[
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];

  static const List<String> _tens = <String>[
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  static String _numberToWords(int number) {
    if (number == 0) return 'Zero';
    if (number < 0) return 'Minus ${_numberToWords(-number)}';

    String words = '';

    int crore = number ~/ 10000000;
    number %= 10000000;
    int lakh = number ~/ 100000;
    number %= 100000;
    int thousand = number ~/ 1000;
    number %= 1000;
    int hundred = number ~/ 100;
    number %= 100;

    if (crore > 0) words += '${_twoDigits(crore)} Crore ';
    if (lakh > 0) words += '${_twoDigits(lakh)} Lakh ';
    if (thousand > 0) words += '${_twoDigits(thousand)} Thousand ';
    if (hundred > 0) words += '${_ones[hundred]} Hundred ';
    if (number > 0) {
      if (words.isNotEmpty) words += 'and ';
      words += _twoDigits(number);
    }
    return words.trim();
  }

  static String _twoDigits(int number) {
    if (number < 20) return _ones[number];
    final int t = number ~/ 10;
    final int o = number % 10;
    return '${_tens[t]}${o > 0 ? ' ${_ones[o]}' : ''}';
  }
}
