import 'package:flutter/material.dart';
import '../../data/auth_service.dart';
import '../../theme/app_theme.dart';
import 'auth_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _Busy { none, login, guest }

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  _Busy _busy = _Busy.none;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = _Busy.login;
      _error = null;
    });
    final error = await auth.signIn(_email.text, _password.text);
    if (!mounted) return;
                                                            
    setState(() {
      _busy = _Busy.none;
      _error = error;
    });
  }

  Future<void> _guest() async {
    setState(() {
      _busy = _Busy.guest;
      _error = null;
    });
    await auth.continueAsGuest();
    if (mounted) setState(() => _busy = _Busy.none);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final idle = _busy == _Busy.none;

    return AuthScaffold(
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthLogo(),
              const SizedBox(height: 36),
              Text('Selamat datang kembali', style: text.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Masuk untuk melihat kas, utang, dan owner\'s cut usahamu.',
                style: text.bodyMedium?.copyWith(color: FlundsColors.textMuted),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                AuthErrorBanner(_error!),
                const SizedBox(height: 14),
              ],
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
                onSubmitted: (_) => _login(),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Kata sandi wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              LoadingButton(
                label: 'Masuk',
                loading: _busy == _Busy.login,
                onPressed: idle ? _login : null,
              ),
              const SizedBox(height: 22),
              const SizedBox(height: 4),
              const _OrDivider(),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: idle ? _guest : null,
                icon: _busy == _Busy.guest
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(Icons.person_outline, size: 20),
                label: const Text('Lanjut sebagai Tamu'),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Belum punya akun?', style: text.bodyMedium),
                  TextButton(
                    onPressed: idle
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            )
                        : null,
                    child: const Text('Daftar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('atau', style: Theme.of(context).textTheme.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
