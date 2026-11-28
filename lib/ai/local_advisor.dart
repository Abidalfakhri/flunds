import '../data/app_data.dart';
import '../models/category.dart';
import '../utils/formatters.dart';

/// Penasihat offline berbasis aturan.
///
/// Dipakai sebagai cadangan ketika AI online tidak bisa dihubungi (timeout,
/// kuota habis, tanpa internet). Semua angka dihitung dari data di perangkat,
/// jadi fitur analisis tetap memberi hasil yang berguna.
class LocalAdvisor {
  LocalAdvisor._();

  /// Awalan yang menandai jawaban berasal dari mode offline.
  static const String offlineLabel = 'Mode offline';

  // ============================================================
  // ANALISIS SINGKAT (kartu dashboard)
  // ============================================================

  static String insight(AppData d) {
    final b = StringBuffer();

    b.writeln(
      'Kondisi kas: ${d.runwayStatusLabel.toLowerCase()}. Saldo '
      '${formatRupiah(d.currentBalance)} cukup untuk sekitar '
      '${d.runwayDays} hari (batas aman ${d.runwayThresholdDays} hari).',
    );

    for (final tip in _tips(d).take(3)) {
      b.writeln('- $tip');
    }

    return b.toString().trim();
  }

  static List<String> _tips(AppData d) {
    final tips = <String>[];

    // 1. Hal paling mendesak lebih dulu.
    if (d.runwayDays < d.runwayThresholdDays) {
      tips.add(
        'Kas di bawah batas aman. Tunda pengeluaran yang tidak mendesak '
        'dan prioritaskan penagihan piutang.',
      );
    }

    final overdue = d.overdueDebts;
    if (overdue.isNotEmpty) {
      final total = overdue.fold<int>(0, (sum, x) => sum + x.amount);
      tips.add(
        '${overdue.length} utang/piutang lewat jatuh tempo '
        '(total ${formatRupiah(total)}). Segera tagih atau bayar.',
      );
    }

    final income = d.monthIncome;
    final expense = d.monthExpense;
    if (expense > income) {
      tips.add(
        'Pengeluaran bulan ini (${formatRupiah(expense)}) melebihi '
        'pemasukan (${formatRupiah(income)}). Tinjau kategori terbesar.',
      );
    }

    // 2. Anggaran yang jebol.
    for (final c in d.categoriesByType(CategoryType.expense)) {
      final usage = d.budgetUsage(c.id);
      if (usage != null && usage >= 1.0) {
        tips.add(
          'Anggaran "${c.name}" sudah terpakai ${(usage * 100).round()}%. '
          'Kurangi pengeluaran di kategori ini.',
        );
        break;
      }
    }

    // 3. Kategori terbesar.
    final top = d.categoryBreakdown(CategoryType.expense, thisMonthOnly: true);
    if (top.isNotEmpty && expense > 0) {
      final e = top.first;
      final pct = (e.value * 100 / expense).round();
      tips.add(
        'Pengeluaran terbesar: ${e.key.name} '
        '(${formatRupiah(e.value)}, $pct% dari total). '
        'Cek apakah ada yang bisa dihemat.',
      );
    }

    // 4. Owner's Cut.
    if (d.ownerCutSafeAmount > 0) {
      tips.add(
        "Owner's Cut yang aman ditarik saat ini: "
        '${formatRupiah(d.ownerCutSafeAmount)}.',
      );
    } else if (d.runwayDays < d.runwayThresholdDays) {
      tips.add("Tunda penarikan Owner's Cut sampai kas melewati batas aman.");
    }

    // 5. Target menabung terdekat.
    final open = d.goals.where((g) => !g.isComplete).toList()
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    if (open.isNotEmpty) {
      final g = open.first;
      tips.add(
        'Target "${g.name}" masih kurang ${formatRupiah(g.remaining)}, '
        'tenggat ${g.daysLeft} hari lagi.',
      );
    }

    if (tips.isEmpty) {
      tips.add(
        'Pertahankan pencatatan harian agar analisis makin akurat.',
      );
    }
    return tips;
  }

  // ============================================================
  // JAWABAN CHAT OFFLINE
  // ============================================================

  static String answer(AppData d, String question) {
    final q = question.toLowerCase();

    bool has(List<String> words) => words.any(q.contains);

    if (has(['owner', 'tarik', 'dividen', 'prive'])) {
      return _ownerCut(d);
    }
    if (has(['utang', 'piutang', 'tagih', 'jatuh tempo', 'cicil'])) {
      return _debts(d);
    }
    if (has(['target', 'tabung', 'nabung', 'menabung'])) {
      return _goals(d);
    }
    if (has(['boros', 'pengeluaran', 'hemat', 'kurangi', 'biaya'])) {
      return _expenses(d);
    }
    return insight(d);
  }

  static String _ownerCut(AppData d) {
    if (d.ownerCutSafeAmount > 0) {
      return "Owner's Cut yang aman ditarik sekarang sekitar "
          '${formatRupiah(d.ownerCutSafeAmount)}. Angka ini sudah '
          'menyisakan kas untuk ${d.runwayThresholdDays} hari operasional '
          '(rata-rata pengeluaran harian '
          '${formatRupiah(d.averageDailyBurn.round())}).';
    }
    return "Saat ini belum ada Owner's Cut yang aman ditarik. Saldo "
        '${formatRupiah(d.currentBalance)} belum melebihi cadangan '
        '${d.runwayThresholdDays} hari operasional. Tunggu kas bertambah '
        'sebelum menarik.';
  }

  static String _debts(AppData d) {
    final b = StringBuffer();
    b.writeln(
      'Piutang belum lunas: ${formatRupiah(d.totalReceivable)}. '
      'Utang belum lunas: ${formatRupiah(d.totalPayable)}.',
    );
    final overdue = d.overdueDebts;
    if (overdue.isEmpty) {
      b.writeln('Tidak ada yang lewat jatuh tempo.');
    } else {
      b.writeln('Lewat jatuh tempo:');
      for (final x in overdue.take(5)) {
        final kind = x.isReceivable ? 'Piutang dari' : 'Utang ke';
        b.writeln(
          '- $kind ${x.partyName}: ${formatRupiah(x.amount)} '
          '(${formatDateRelative(x.dueDate)})',
        );
      }
    }
    return b.toString().trim();
  }

  static String _goals(AppData d) {
    final open = d.goals.where((g) => !g.isComplete).toList();
    if (open.isEmpty) {
      return d.goals.isEmpty
          ? 'Belum ada target menabung. Buat target dulu agar progresnya '
              'bisa dipantau.'
          : 'Semua target menabung sudah tercapai.';
    }
    final b = StringBuffer('Target menabung yang masih berjalan:\n');
    for (final g in open.take(5)) {
      final pct = (g.progress * 100).round();
      b.writeln(
        '- ${g.name}: $pct% (kurang ${formatRupiah(g.remaining)}, '
        '${g.daysLeft} hari lagi)',
      );
    }
    return b.toString().trim();
  }

  static String _expenses(AppData d) {
    final top = d.categoryBreakdown(CategoryType.expense, thisMonthOnly: true);
    if (top.isEmpty) return 'Belum ada pengeluaran tercatat bulan ini.';

    final total = d.monthExpense;
    final b = StringBuffer(
      'Total pengeluaran bulan ini ${formatRupiah(total)}. Terbesar:\n',
    );
    for (final e in top.take(3)) {
      final pct = total > 0 ? (e.value * 100 / total).round() : 0;
      b.writeln('- ${e.key.name}: ${formatRupiah(e.value)} ($pct%)');
    }
    return b.toString().trim();
  }
}
