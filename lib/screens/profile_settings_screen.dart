import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'categories_list_screen.dart';

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
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileCard(),
                    const SizedBox(height: 20),
                    Text('Pengaturan runway & owner\'s cut', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    const _SettingsForm(),
                    const SizedBox(height: 24),
                    Text('Data & referensi', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    _MenuTile(
                      icon: Icons.category_outlined,
                      title: 'Kelola Kategori',
                      subtitle: '${appData.categories.length} kategori tersimpan',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesListScreen())),
                    ),
                    const SizedBox(height: 24),
                    _AboutPersonaCard(),
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
  late final TextEditingController _thresholdController;
  late double _percentage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: appData.ownerName);
    _businessController = TextEditingController(text: appData.businessName);
    _thresholdController = TextEditingController(text: appData.runwayThresholdDays.toString());
    _percentage = appData.ownerCutPercentage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    appData.updateProfile(
      ownerName: _nameController.text.trim(),
      businessName: _businessController.text.trim(),
      runwayThresholdDays: int.parse(_thresholdController.text),
      ownerCutPercentage: _percentage,
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
              controller: _thresholdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ambang batas runway aman (hari)'),
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

  const _MenuTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
              decoration: BoxDecoration(color: FlundsColors.primarySoft, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: FlundsColors.primary, size: 19),
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
            'pribadi, memantau berapa lama kas bisnis masih bisa bertahan (runway), dan memberi tahu kapan '
            'aman menarik "gaji" sebagai pemilik tanpa mengganggu operasional.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
