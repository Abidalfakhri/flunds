# Flunds

Flunds adalah aplikasi berbasis Flutter yang dirancang untuk membantu pelaku UMKM dalam mencatat, mengelola, dan memantau kondisi keuangan usaha. Aplikasi ini menyediakan fitur pengelolaan transaksi, pemantauan arus kas, pengaturan keuangan, serta analisis keuangan berbantuan AI.

## Fitur Utama

- **Dashboard Keuangan** – Menampilkan ringkasan kondisi keuangan usaha, seperti saldo kas, pemasukan, pengeluaran, laba bersih, dan cash runway.
- **Manajemen Transaksi** – Mencatat dan mengelola transaksi pemasukan maupun pengeluaran.
- **Kategori Transaksi** – Mengelompokkan transaksi berdasarkan kategori pemasukan dan pengeluaran.
- **Manajemen Utang dan Piutang** – Mencatat kewajiban dan tagihan usaha beserta status pembayarannya.
- **Target Tabungan** – Membuat dan memantau target keuangan usaha.
- **Pengaturan Profil Usaha** – Mengelola informasi dan pengaturan keuangan usaha.
- **What-If Simulation** – Menyimulasikan dampak rencana pengeluaran terhadap saldo kas dan cash runway.
- **AI Financial Assistant** – Membantu pengguna memahami kondisi keuangan usaha dan memperoleh saran berdasarkan data keuangan yang tersimpan.

## Teknologi yang Digunakan

- Flutter dan Dart – Pengembangan aplikasi.
- Firebase Authentication – Autentikasi dan pengelolaan akun pengguna.
- Cloud Firestore – Penyimpanan data profil dan keuangan pengguna.
- Firebase AI Logic – Integrasi layanan AI Gemini.
- Firebase App Check – Membantu melindungi akses layanan Firebase.
- Provider – Pengelolaan state aplikasi.

## Persyaratan

Pastikan perangkat pengembangan sudah memiliki:

- Flutter SDK
- Dart SDK
- Android Studio
- Android SDK
- Android Emulator atau perangkat Android
- Node.js dan Firebase CLI
- FlutterFire CLI

## Setup Project

Clone repository:

```bash
git clone <URL_REPOSITORY>
cd flunds
```

Install dependency:

```bash
flutter pub get
```

Periksa konfigurasi Flutter:

```bash
flutter doctor
```

## Konfigurasi Firebase

Flunds menggunakan Firebase sebagai backend untuk autentikasi dan penyimpanan data.

Untuk menjalankan project, pastikan:

1. Project Firebase sudah dibuat.
2. Aplikasi Android dan/atau Web sudah didaftarkan pada Firebase.
3. Firebase Authentication sudah diaktifkan.
4. Cloud Firestore sudah dibuat.
5. Firebase App Check sudah dikonfigurasi sesuai platform.
6. Firebase AI Logic sudah disiapkan untuk penggunaan Gemini.

Konfigurasi Firebase dapat dibuat menggunakan FlutterFire CLI:

```bash
flutterfire configure
```

Perintah tersebut akan menghasilkan file konfigurasi `lib/firebase_options.dart`.

Pastikan konfigurasi Firebase sesuai dengan project yang digunakan. Jangan membagikan file atau kredensial yang bersifat rahasia.

## Menjalankan Aplikasi

Cek perangkat yang tersedia:

```bash
flutter devices
```

Jalankan aplikasi:

```bash
flutter run
```

Untuk menjalankan pada Chrome:

```bash
flutter run -d chrome
```

Aplikasi juga dapat dijalankan melalui tombol **Run** di Android Studio atau Visual Studio Code.

## Integrasi AI Gemini

Flunds menyediakan AI Financial Assistant yang menggunakan Gemini melalui Firebase AI Logic.

AI Assistant memanfaatkan konteks data keuangan pengguna, seperti:

- Saldo kas.
- Pemasukan dan pengeluaran.
- Laba bersih.
- Rata-rata pengeluaran harian.
- Cash runway.
- Pengeluaran berdasarkan kategori.
- Utang dan piutang.
- Target tabungan.
- Riwayat transaksi terbaru.

Informasi tersebut digunakan sebagai konteks agar AI dapat memberikan penjelasan dan saran yang relevan dengan kondisi keuangan usaha.

## What-If Simulation

Fitur What-If Simulation digunakan untuk memperkirakan dampak rencana pengeluaran terhadap kondisi kas sebelum keputusan dilakukan.

### Skenario 1

Saldo kas sebesar **Rp10.000.000** dengan rencana pembelian peralatan sebesar **Rp2.000.000**.

Perhitungan:

```text
Rp10.000.000 - Rp2.000.000 = Rp8.000.000
```

Hasil simulasi menunjukkan saldo kas menjadi **Rp8.000.000**.

### Skenario 2

Saldo kas sebesar **Rp10.000.000** dengan rencana pembelian aset sebesar **Rp7.000.000**.

Perhitungan:

```text
Rp10.000.000 - Rp7.000.000 = Rp3.000.000
```

Hasil simulasi menunjukkan saldo kas menjadi **Rp3.000.000**.

Simulasi membantu pengguna memahami perubahan saldo kas dan potensi perubahan cash runway setelah rencana pengeluaran dilakukan.

## Catatan Pengembangan

- Data keuangan pengguna dikelola melalui integrasi Firebase.
- Akses data pengguna mengikuti konfigurasi autentikasi dan Firestore Security Rules.
- Fitur AI memerlukan koneksi internet dan konfigurasi Firebase AI Logic yang sesuai.
- Ketersediaan layanan AI mengikuti batas penggunaan dan kebijakan layanan Gemini.
- Beberapa data simulasi dapat digunakan untuk keperluan pengujian fitur.

## Status Project

Flunds dikembangkan secara bertahap dengan fokus pada pengelolaan keuangan UMKM, integrasi backend Firebase, dan pemanfaatan AI untuk membantu analisis kondisi keuangan usaha.
## Catatan Fitur AI

- Rantai model otomatis: `gemini-3.5-flash-lite` -> `gemini-3.8-flash` -> `gemini-4-hydrogen`
  (semua stable dan tidak butuh billing). Jika satu model lambat, kuotanya habis, atau
  dimatikan, aplikasi pindah ke model berikutnya.
- Jika semua model gagal, kartu analisis dan chat memakai analisis offline
  (`lib/ai/local_advisor.dart`) yang dihitung dari data di perangkat.
- Ganti model utama tanpa mengubah kode:
  `flutter build apk --release --dart-define=AI_MODEL=gemini-3.8-flash`
- Debug token App Check harus terdaftar di Firebase Console > App Check > Manage debug tokens.

## Build APK

```bash
flutter pub get
flutter build apk --release
# hasil: build/app/outputs/flutter-apk/app-release.apk
```
