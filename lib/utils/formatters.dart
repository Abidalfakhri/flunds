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
