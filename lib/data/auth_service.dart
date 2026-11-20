
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'app_data.dart';

enum AccountKind { demo, member, guest }

class AuthUser {
  final String id;
  final String email;
  final AccountKind kind;

  const AuthUser({
    required this.id,
    required this.email,
    required this.kind,
  });

  bool get isGuest => kind == AccountKind.guest;
  bool get isDemo => kind == AccountKind.demo;
}

class AuthService extends ChangeNotifier {
  static const demoEmail = 'budi@gmail.com';
  static const demoPassword = '123';

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthUser? _current;

  AuthUser? get currentUser => _current;
  bool get isSignedIn => _current != null;
  bool get isGuest => _current?.isGuest ?? false;

  int _guestCounter = 0;

  static final _emailPattern =
  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static bool isValidEmail(String value) =>
      _emailPattern.hasMatch(value.trim());

  Future<void> initialize() async {
    final user = _firebaseAuth.currentUser;

    if (user != null) {
      _current = AuthUser(
        id: user.uid,
        email: user.email ?? '',
        kind: AccountKind.member,
      );

      await _loadProfile(user.uid);
    }

    notifyListeners();
  }

  Future<void> _loadProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) return;

    final data = doc.data();
    if (data == null) return;

    appData.updateProfile(
      ownerName: data['name'] as String?,
      businessName: data['businessName'] as String?,
      businessType: data['businessType'] as String?,
      startingBalance: (data['startingBalance'] as num?)?.toInt(),
      runwayThresholdDays:
      (data['runwayThresholdDays'] as num?)?.toInt(),
      ownerCutPercentage:
      (data['ownerCutPercentage'] as num?)?.toDouble(),
      taxEstimateEnabled: data['taxEstimateEnabled'] as bool?,
    );
  }

  Future<void> _saveProfile({
    required String uid,
    required String name,
    required String businessName,
    required int startingBalance,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'businessName': businessName,
      'businessType': appData.businessType,
      'email': _firebaseAuth.currentUser?.email ?? '',
      'startingBalance': startingBalance,
      'runwayThresholdDays': appData.runwayThresholdDays,
      'ownerCutPercentage': appData.ownerCutPercentage,
      'taxEstimateEnabled': appData.taxEstimateEnabled,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateProfile({
    required String name,
    required String businessName,
    required String businessType,
    required int startingBalance,
    required int runwayThresholdDays,
    required double ownerCutPercentage,
    required bool taxEstimateEnabled,
  }) async {
    final user = _firebaseAuth.currentUser;

    if (user == null || _current?.kind != AccountKind.member) {
      throw Exception('Pengguna belum login.');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'businessName': businessName,
      'businessType': businessType,
      'email': user.email ?? '',
      'startingBalance': startingBalance,
      'runwayThresholdDays': runwayThresholdDays,
      'ownerCutPercentage': ownerCutPercentage,
      'taxEstimateEnabled': taxEstimateEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final credential =
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        return 'Gagal mendapatkan data akun.';
      }

      _current = AuthUser(
        id: user.uid,
        email: user.email ?? email.trim(),
        kind: AccountKind.member,
      );

      await _loadProfile(user.uid);
      notifyListeners();

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
          return 'Email atau kata sandi salah.';
        case 'wrong-password':
          return 'Kata sandi salah.';
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'user-disabled':
          return 'Akun ini telah dinonaktifkan.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Coba lagi nanti.';
        default:
          return e.message ?? 'Gagal masuk. Silakan coba lagi.';
      }
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  Future<void> signInAsDemo() async {
    _current = const AuthUser(
      id: 'demo',
      email: demoEmail,
      kind: AccountKind.demo,
    );

    appData.resetAllData();
    notifyListeners();
  }

  Future<void> continueAsGuest() async {
    appData.startFreshWorkspace(
      ownerName: 'Tamu',
      businessName: 'Usaha Saya',
    );

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
    try {
      final credential =
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        return 'Gagal membuat akun.';
      }

      if (isGuest) {
        appData.updateProfile(
          ownerName: name.trim(),
          businessName: businessName.trim(),
        );
      } else {
        appData.startFreshWorkspace(
          ownerName: name.trim(),
          businessName: businessName.trim(),
          startingBalance: startingBalance,
        );
      }

      await _saveProfile(
        uid: user.uid,
        name: name.trim(),
        businessName: businessName.trim(),
        startingBalance: appData.startingBalance,
      );

      _current = AuthUser(
        id: user.uid,
        email: user.email ?? email.trim(),
        kind: AccountKind.member,
      );

      notifyListeners();

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Email ini sudah terdaftar. Silakan masuk.';
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'weak-password':
          return 'Kata sandi terlalu lemah.';
        case 'operation-not-allowed':
          return 'Metode Email/Password belum diaktifkan.';
        default:
          return e.message ?? 'Gagal membuat akun.';
      }
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  Future<void> signOut() async {
    if (_current?.kind == AccountKind.member) {
      await _firebaseAuth.signOut();
    }

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
}

final AuthService auth = AuthService();
