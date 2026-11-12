import '../data/app_data.dart';
import 'formatters.dart';

                                                                       
                                                                             
                                                                    
                                                            
String buildCashflowSummary(AppData data) {
  final buffer = StringBuffer();
  buffer.writeln('Ringkasan Kas — ${data.businessName}');
  buffer.writeln(formatDateFull(DateTime.now()));
  buffer.writeln('');
  buffer.writeln('Saldo kas saat ini   : ${formatRupiah(data.currentBalance)}');
  buffer.writeln('Pemasukan bulan ini  : ${formatRupiah(data.monthIncome)}');
  buffer.writeln('Pengeluaran bulan ini: ${formatRupiah(data.monthExpense)}');
  buffer.writeln('Laba bersih bulan ini: ${formatRupiah(data.monthIncome - data.monthExpense)}');
  buffer.writeln('Kas bisa bertahan    : ${data.runwayDays} hari (${data.runwayStatusLabel})');
  buffer.writeln("Aman ditarik (Owner's Cut): ${formatRupiah(data.ownerCutSafeAmount)}");
  if (data.totalReceivable > 0) {
    buffer.writeln('Piutang belum lunas  : ${formatRupiah(data.totalReceivable)}');
  }
  if (data.totalPayable > 0) {
    buffer.writeln('Utang belum lunas    : ${formatRupiah(data.totalPayable)}');
  }
  buffer.writeln('');
  buffer.writeln('Dibuat otomatis lewat aplikasi Flunds');
  return buffer.toString();
}
