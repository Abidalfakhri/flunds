import 'package:flutter/foundation.dart';
import 'app_data.dart';

enum AccountKind { demo, member, guest }

class AuthUser {
  final String id;
  final String email;
  final AccountKind kind;

  const AuthUser({required this.id, required this.email, required this.kind});

  bool get isGuest => kind == AccountKind.guest;
  bool get isDemo => kind == AccountKind.demo;
}

class _Account {
  final String id;
  final String email;
  final String password;
  final AccountKind kind;

  const _Account(this.id, this.email, this.password, this.kind);
}
                                                                            


class AuthService extends ChangeNotifier {
                                                                           
  static const demoEmail = 'budi@gmail.com';
  static const demoPassword = '123';

  final List<_Account> _accounts = [
    const _Account('demo', demoEmail, demoPassword, AccountKind.demo),
  ];
  final Map<String, AppSnapshot> _snapshots = {};

  AuthUser? _current;
  AuthUser? get currentUser => _current;
  bool get isSignedIn => _current != null;
  bool get isGuest => _current?.isGuest ?? false;

  int _guestCounter = 0;
  int _memberCounter = 0;

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static bool isValidEmail(String v) => _emailPattern.hasMatch(v.trim());

  Future<void> _fakeLatency() =>
      Future<void>.delayed(const Duration(milliseconds: 600));

                                                         
  Future<String?> signIn(String email, String password) async {
    await _fakeLatency();
    final key = email.trim().toLowerCase();
    final matches = _accounts.where((a) => a.email == key);
    if (matches.isEmpty) return 'Email belum terdaftar. Coba daftar dulu.';
    final account = matches.first;
    if (account.password != password) return 'Kata sandi salah.';
    _enter(account);
    return null;
  }

  Future<void> signInAsDemo() async {
    await _fakeLatency();
    _enter(_accounts.first);
  }

  Future<void> continueAsGuest() async {
    await _fakeLatency();
    _stashCurrent();
    appData.startFreshWorkspace(ownerName: 'Tamu', businessName: 'Usaha Saya');
    _current = AuthUser(
      id: 'guest-${_guestCounter++}',
      email: '',
      kind: AccountKind.guest,
    );
    notifyListeners();
  }
  Future<String?> register({
    required String name,
    required String businessName,
    required String email,
    required String password,
    int startingBalance = 0,
  }) async {
    await _fakeLatency();
    final key = email.trim().toLowerCase();
    if (_accounts.any((a) => a.email == key)) {
      return 'Email ini sudah terdaftar. Silakan masuk.';
    }

    final account = _Account(
      'member-${_memberCounter++}',
      key,
      password,
      AccountKind.member,
    );
    _accounts.add(account);

    if (isGuest) {
      appData.updateProfile(
        ownerName: name.trim(),
        businessName: businessName.trim(),
      );
      _current = AuthUser(id: account.id, email: key, kind: AccountKind.member);
      notifyListeners();
    } else {
      _stashCurrent();
      appData.startFreshWorkspace(
        ownerName: name.trim(),
        businessName: businessName.trim(),
        startingBalance: startingBalance,
      );
      _current = AuthUser(id: account.id, email: key, kind: AccountKind.member);
      notifyListeners();
    }
    return null;
  }

  void signOut() {
    _stashCurrent();
    _current = null;
    notifyListeners();
  }

                                                                          
                            
  void resetCurrentWorkspace() {
    final user = _current;
    if (user == null) return;
    if (user.isDemo) {
      appData.resetAllData();
    } else {
      appData.startFreshWorkspace(
        ownerName: appData.ownerName,
        businessName: appData.businessName,
        businessType: appData.businessType,
      );
    }
  }

  void _enter(_Account account) {
    _stashCurrent();
    final saved = _snapshots[account.id];
    if (saved != null) {
      appData.restoreSnapshot(saved);
    } else if (account.kind == AccountKind.demo) {
      appData.resetAllData();
    }
    _current = AuthUser(
      id: account.id,
      email: account.email,
      kind: account.kind,
    );
    notifyListeners();
  }

  void _stashCurrent() {
    final user = _current;
    if (user == null || user.isGuest) return;
    _snapshots[user.id] = appData.takeSnapshot();
  }
}

final AuthService auth = AuthService();
