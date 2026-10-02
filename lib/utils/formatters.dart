import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _rupiahFull = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

final _dateFull = DateFormat('d MMM yyyy', 'id_ID');
final _dateShort = DateFormat('d/M/yy');

String formatRupiah(int amount) => _rupiahFull.format(amount);

String formatRupiahCompact(int amount) {
  final isNegative = amount < 0;
  final value = amount.abs();
  String result;
  if (value >= 1000000) {
    final millions = value / 1000000;
    result = 'Rp${_trimZero(millions)}jt';
  } else if (value >= 1000) {
    final thousands = value / 1000;
    result = 'Rp${_trimZero(thousands)}rb';
  } else {
    result = 'Rp$value';
  }
  return isNegative ? '-$result' : result;
}

String _trimZero(double value) {
  final rounded = (value * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) {
    return rounded.toInt().toString();
  }
  return rounded.toString().replaceAll('.', ',');
}

String formatDateFull(DateTime date) => _dateFull.format(date);

String formatDateShort(DateTime date) => _dateShort.format(date);

/// Groups an integer's digits with '.' every 3 digits (id_ID style),
/// e.g. 1250000 -> "1.250.000". Used both by [AmountInputFormatter] and to
/// seed a controller's initial text so typed and pre-filled values match.
String groupThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i != 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return value < 0 ? '-${buffer.toString()}' : buffer.toString();
}

/// Live thousand-separator formatting for nominal/amount fields, so typing
/// "150000" renders as "150.000" as the user types. Digits are recovered
/// with the same `replaceAll(RegExp(r'[^0-9]'), '')` parsing already used
/// across the app, so this is a drop-in visual layer with no parsing changes.
class AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = groupThousands(int.parse(digitsOnly));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
