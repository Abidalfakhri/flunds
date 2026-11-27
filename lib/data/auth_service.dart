import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'app_data.dart';
import 'firestore_repository.dart';

/// member = akun email/password, guest = akun anonim Firebase (mode tamu).
enum AccountKind { member, guest }

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
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthUser? _current;

  AuthUser? get currentUser => _current;
  bool get isSignedIn => _current != null;
  bool get isGuest => _current?.isGuest ?? false;

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static bool isValidEmail(String value) =>
      _emailPattern.hasMatch(value.trim());

  AuthUser _toAuthUser(User user, {String fallbackEmail = ''}) => AuthUser(
        id: user.uid,
        email: user.email ?? fallbackEmail,
        kind: user.isAnonymous ? AccountKind.guest : AccountKind.member,
      );

  Future<void> initialize() async {
    final user = _firebaseAuth.currentUser;

    if (user != null) {
      _current = _toAuthUser(user);
      await appData.startSync(user.uid);
    }

    notifyListeners();
  }

  /// Buat dokumen profil + kategori default untuk akun baru.
  Future<void> _createAccountData({
    required String uid,
    required String name,
    required String businessName,
    int startingBalance = 0,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'businessName': businessName,
      'businessType': 'UMKM',
      'email': _firebaseAuth.currentUser?.email ?? '',
      'startingBalance': startingBalance,
      'runwayThresholdDays': 14,
      'ownerCutPercentage': 0.10,
      'taxEstimateEnabled': true,
      'categoriesSeeded': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirestoreRepository(uid).saveCategories(AppData.defaultCategories());
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

    if (user == null) {
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
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        return 'Gagal mendapatkan data akun.';
      }

      _current = _toAuthUser(user, fallbackEmail: email.trim());

      await appData.startSync(user.uid);
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

  /// Mode tamu memakai akun anonim Firebase, jadi datanya tetap
  /// tersimpan di Firestore dan bisa diubah jadi akun email saat daftar.
  Future<String?> continueAsGuest() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      final user = credential.user;

      if (user == null) {
        return 'Gagal memulai mode tamu.';
      }

      await _createAccountData(
        uid: user.uid,
        name: 'Tamu',
        businessName: 'Usaha Saya',
      );

      _current = _toAuthUser(user);

      await appData.startSync(user.uid);
      notifyListeners();

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        return 'Mode tamu belum diaktifkan di Firebase '
            '(Authentication → Sign-in method → Anonymous).';
      }
      return e.message ?? 'Gagal memulai mode tamu.';
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  Future<String?> register({
    required String name,
    required String businessName,
    required String email,
    required String password,
    int startingBalance = 0,
  }) async {
    try {
      final current = _firebaseAuth.currentUser;
      final User user;

      if (current != null && current.isAnonymous) {
        // Tamu -> akun email. UID sama, jadi semua data tamu ikut terbawa.
        final linked = await current.linkWithCredential(
          EmailAuthProvider.credential(
            email: email.trim(),
            password: password,
          ),
        );
        user = linked.user ?? current;

        await _firestore.collection('users').doc(user.uid).set({
          'name': name.trim(),
          'businessName': businessName.trim(),
          'email': user.email ?? email.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        final credential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        final created = credential.user;

        if (created == null) {
          return 'Gagal membuat akun.';
        }
        user = created;

        await _createAccountData(
          uid: user.uid,
          name: name.trim(),
          businessName: businessName.trim(),
          startingBalance: startingBalance,
        );

        await appData.startSync(user.uid);
      }

      _current = _toAuthUser(user, fallbackEmail: email.trim());
      notifyListeners();

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
        case 'credential-already-in-use':
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
    final firebaseUser = _firebaseAuth.currentUser;
    final wasGuest = _current?.isGuest ?? false;

    await appData.stopSync();

    if (wasGuest && firebaseUser != null) {
      // Data tamu tidak bisa diakses lagi setelah keluar, jadi dihapus.
      try {
        await FirestoreRepository(firebaseUser.uid)
            .deleteUserData()
            .timeout(const Duration(seconds: 8));
        await firebaseUser.delete();
      } catch (e) {
        debugPrint('Gagal menghapus data tamu: $e');
      }
    }

    await _firebaseAuth.signOut();
    appData.clearCache();

    _current = null;
    notifyListeners();
  }

  /// Hapus semua catatan di Firestore dan pulihkan kategori default.
  void resetCurrentWorkspace() {
    if (_current == null) return;
    appData.resetData();
  }
}

final AuthService auth = AuthService();
