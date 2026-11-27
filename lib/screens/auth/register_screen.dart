import 'package:flutter/material.dart';
import '../../data/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _business = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _balance = TextEditingController();

  bool _loading = false;
  String? _error;

                                                                              
  bool get _upgrading => auth.isGuest;

  @override
  void dispose() {
    _name.dispose();
    _business.dispose();
    _email.dispose();
    _password.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final balance =
        int.tryParse(_balance.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final error = await auth.register(
      name: _name.text,
      businessName: _business.text,
      email: _email.text,
      password: _password.text,
      startingBalance: balance,
    );
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      return;
    }
                                                                         
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AuthScaffold(
      showBack: true,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Buat akun Flunds', style: text.headlineSmall),
              const SizedBox(height: 6),
              Text(
                _upgrading
                    ? 'Data yang sudah kamu catat sebagai tamu akan ikut tersimpan di akun baru.'
                    : 'Cukup satu menit. Kamu bisa ubah semua data usaha nanti di Profil.',
                style: text.bodyMedium?.copyWith(color: FlundsColors.textMuted),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                AuthErrorBanner(_error!),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(labelText: 'Nama kamu'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _business,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nama usaha'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama usaha wajib diisi' : null,
              ),
              if (!_upgrading) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _balance,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [AmountInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Modal / saldo kas awal (opsional)',
                    prefixText: 'Rp ',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                  if (!AuthService.isValidEmail(v)) return 'Format email belum benar';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _password,
                label: 'Kata sandi (min. 6 karakter)',
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _submit(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
                  if (v.length < 6) return 'Minimal 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 22),
              LoadingButton(
                label: 'Daftar & Masuk',
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
