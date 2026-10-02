# Flunds

Flunds adalah aplikasi Flutter untuk membantu UMKM dalam mencatat dan memantau kondisi keuangan usaha.

## Setup

Pastikan sudah terinstall:

- Flutter SDK
- Dart SDK
- Android Studio
- Android SDK
- Android Emulator atau perangkat Android

Clone repository:

    git clone <URL_REPOSITORY>
    cd flunds-abid

Install dependency:

    flutter pub get

Cek konfigurasi Flutter:

    flutter doctor

## Perintah Run

Pastikan emulator atau perangkat Android sudah terhubung.

Cek device:

    flutter devices

Jalankan aplikasi:

    flutter run

Atau jalankan menggunakan tombol **Run** di Android Studio.

## Data Dummy

Aplikasi menggunakan data dummy untuk pengujian fitur.

Data dummy meliputi:

- Profil usaha
- Kategori transaksi
- Transaksi pemasukan
- Transaksi pengeluaran
- Saldo kas

Contoh transaksi:

| Transaksi | Jenis | Nominal |
|---|---|---:|
| Penjualan Produk | Pemasukan | Rp5.000.000 |
| Bahan Baku | Pengeluaran | Rp1.500.000 |
| Operasional | Pengeluaran | Rp500.000 |

Data dummy digunakan agar dashboard dapat langsung menampilkan kondisi keuangan saat aplikasi dijalankan.

## Skenario Simulasi

Fitur **What-If Simulation** digunakan untuk melihat dampak rencana pengeluaran terhadap kondisi kas.

### Skenario 1

Saldo kas sebesar **Rp10.000.000** dan terdapat rencana pembelian peralatan sebesar **Rp2.000.000**.

Perhitungan:

    Rp10.000.000 - Rp2.000.000 = Rp8.000.000

Hasil simulasi menunjukkan saldo kas menjadi **Rp8.000.000**.

### Skenario 2

Saldo kas sebesar **Rp10.000.000** dan terdapat rencana pembelian aset sebesar **Rp7.000.000**.

Perhitungan:

    Rp10.000.000 - Rp7.000.000 = Rp3.000.000

Hasil simulasi menunjukkan saldo kas menjadi **Rp3.000.000**.

Skenario digunakan untuk melihat perubahan saldo kas dan cash runway sebelum pengeluaran dilakukan.