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
    final label = _trimZero(thousands);
                                                                                
    result = label == '1000' ? 'Rp1jt' : 'Rp${label}rb';
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

                                                                           
                                                                            
                                        
String formatDateRelative(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = target.difference(today).inDays;
  if (diff == 0) return 'Hari ini';
  if (diff == 1) return 'Besok';
  if (diff > 1) return '$diff hari lagi';
  return 'Terlambat ${-diff} hari';
}

                                                                     
                                                                           
                                                                          
String groupThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i != 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return value < 0 ? '-${buffer.toString()}' : buffer.toString();
}

                                                                           
                                                                         
                                                                          
                                                                              
class AmountInputFormatter extends TextInputFormatter {
                                                                               
                                                                             
                         
  static const int maxDigits = 12;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }
    if (digitsOnly.length > maxDigits) {
      return oldValue;
    }
    final formatted = groupThousands(int.parse(digitsOnly));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
