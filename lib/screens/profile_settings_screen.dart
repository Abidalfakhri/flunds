import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/app_data.dart';
import '../models/insight.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/summary_builder.dart';
import '../widgets/confirm_dialog.dart';
import 'categories_list_screen.dart';
import 'debts_screen.dart';
import 'notifications_screen.dart';
import 'savings_goals_screen.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil & Pengaturan')),
      body: ListenableBuilder(
        listenable: appData,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileCard(),
                    const SizedBox(height: 20),
                    Text('Pengaturan kas & gaji pemilik', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    _SettingsForm(),
                    const SizedBox(height: 24),
                    Text('Menu lainnya', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    _MenuTile(
                      icon: Icons.category_outlined,
                      title: 'Kelola Kategori & Anggaran',
                      subtitle: '${appData.categories.length} kategori tersimpan',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesListScreen())),
                    ),
                    const SizedBox(height: 10),
                    _MenuTile(
                      icon: Icons.handshake_outlined,
                      title: 'Utang & Piutang',
                      subtitle: '${appData.debts.where((d) => !d.isPaid).length} catatan belum lunas',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtsScreen())),
                    ),
                    const SizedBox(height: 10),
                    _MenuTile(
                      icon: Icons.flag_outlined,
                      title: 'Target Menabung',
                      subtitle: '${appData.goals.length} target tersimpan',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsGoalsScreen())),
                    ),
                    const SizedBox(height: 10),
                    _MenuTile(
                      icon: Icons.notifications_outlined,
                      title: 'Pemberitahuan',
                      subtitle: '${appData.insights.where((i) => i.level != InsightLevel.info).length} perlu perhatian',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                    ),
                    const SizedBox(height: 24),
                    Text('Data & bagikan', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    _MenuTile(
                      icon: Icons.ios_share_outlined,
                      title: 'Bagikan Ringkasan Keuangan',
                      subtitle: 'Salin ringkasan kas untuk WhatsApp atau catatanmu',
                      onTap: () => _shareSummary(context),
                    ),
                    const SizedBox(height: 10),
                    _MenuTile(
                      icon: Icons.restart_alt_outlined,
                      title: 'Reset Semua Data',
                      subtitle: 'Kembalikan aplikasi ke data contoh awal',
                      iconColor: FlundsColors.expense,
                      onTap: () => _confirmReset(context),
                    ),
                    const SizedBox(height: 24),
                    _AboutPersonaCard(),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Flunds v1.0.0',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _shareSummary(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: buildCashflowSummary(appData)));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ringkasan disalin — tinggal tempel ke WhatsApp atau catatanmu')),
      );
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reset semua data?',
      message:
          'Semua transaksi, utang/piutang, target menabung, dan kategori yang sudah kamu tambahkan akan dihapus dan '
          'dikembalikan ke data contoh awal. Tindakan ini tidak bisa dibatalkan.',
      confirmLabel: 'Reset',
    );
    if (!confirmed) return;
    appData.resetAllData();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil direset ke kondisi awal')),
      );
    }
  }
}

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [FlundsColors.primary, FlundsColors.primaryDark]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              appData.ownerName.isEmpty ? '?' : appData.ownerName[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appData.ownerName, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                const SizedBox(height: 3),
                Text(appData.businessName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text(appData.businessType, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsForm extends StatefulWidget {
  const _SettingsForm();

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _businessController;
  late final TextEditingController _businessTypeController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _startingBalanceController;
  late double _percentage;
  late bool _taxEstimateEnabled;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: appData.ownerName);
    _businessController = TextEditingController(text: appData.businessName);
    _businessTypeController = TextEditingController(text: appData.businessType);
    _thresholdController = TextEditingController(text: appData.runwayThresholdDays.toString());
    _startingBalanceController = TextEditingController(text: groupThousands(appData.startingBalance));
    _percentage = appData.ownerCutPercentage;
    _taxEstimateEnabled = appData.taxEstimateEnabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    _businessTypeController.dispose();
    _thresholdController.dispose();
    _startingBalanceController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final startingBalance = int.tryParse(
          _startingBalanceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    appData.updateProfile(
      ownerName: _nameController.text.trim(),
      businessName: _businessController.text.trim(),
      businessType: _businessTypeController.text.trim(),
      runwayThresholdDays: int.parse(_thresholdController.text),
      ownerCutPercentage: _percentage,
      startingBalance: startingBalance,
      taxEstimateEnabled: _taxEstimateEnabled,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan disimpan')),
    );
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FlundsColors.surfaceLine),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama pemilik'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _businessController,
              decoration: const InputDecoration(labelText: 'Nama usaha'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama usaha wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _businessTypeController,
              decoration: const InputDecoration(labelText: 'Jenis usaha'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Jenis usaha wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _startingBalanceController,
              keyboardType: TextInputType.number,
              inputFormatters: [AmountInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Modal / saldo kas awal',
                prefixText: 'Rp ',
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').replaceAll(RegExp(r'[^0-9]'), ''));
                if (n == null || n < 0) return 'Masukkan jumlah yang valid';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _thresholdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Batas aman "kas bisa bertahan" (hari)'),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Masukkan jumlah hari yang valid';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text('Persentase owner\'s cut aman: ${(_percentage * 100).round()}%', style: Theme.of(context).textTheme.bodySmall),
            Slider(
              value: _percentage,
              min: 0.05,
              max: 0.4,
              divisions: 7,
              activeColor: FlundsColors.primary,
              label: '${(_percentage * 100).round()}%',
              onChanged: (v) => setState(() => _percentage = v),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _taxEstimateEnabled,
              onChanged: (v) => setState(() => _taxEstimateEnabled = v),
              title: const Text('Estimasi Pajak UMKM (PPh Final 0,5%)'),
              subtitle: const Text('Tampilkan perkiraan pajak di halaman Analisis'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size(140, 46)),
                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? FlundsColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FlundsColors.surfaceLine),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FlundsColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _AboutPersonaCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlundsColors.accentSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.badge_outlined, color: FlundsColors.accent, size: 18),
              SizedBox(width: 8),
              Text('Tentang persona Flunds', style: TextStyle(fontWeight: FontWeight.w700, color: FlundsColors.accent)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Flunds dirancang untuk pemilik UMKM rumahan seperti ${appData.ownerName} yang menjalankan '
            '${appData.businessType.toLowerCase()}. Tujuannya sederhana: memisahkan uang bisnis dari uang '
            'pribadi, memantau berapa lama kas usaha masih bisa bertahan, dan memberi tahu kapan aman '
            'menarik "gaji" sebagai pemilik tanpa mengganggu operasional — ditambah pencatatan utang '
            'piutang, anggaran per kategori, dan target menabung supaya semua kebutuhan usaha kecil '
            'ada di satu tempat.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
