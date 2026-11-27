import 'package:flutter/material.dart';

/// Daftar ikon yang boleh dipakai kategori dan target tabungan.
/// Firestore menyimpan KUNCI (string), bukan IconData, supaya aman
/// untuk build release (icon tree-shaking).
/// Kalau menambah pilihan ikon baru di form, tambahkan juga di sini.
const Map<String, IconData> iconRegistry = {
  'storefront': Icons.storefront_outlined,
  'ramen_dining': Icons.ramen_dining_outlined,
  'shopping_basket': Icons.shopping_basket_outlined,
  'build': Icons.build_outlined,
  'home_work': Icons.home_work_outlined,
  'wallet': Icons.account_balance_wallet_outlined,
  'category': Icons.category_outlined,
  'local_shipping': Icons.local_shipping_outlined,
  'payments': Icons.payments_outlined,
  'school': Icons.school_outlined,
  'receipt_long': Icons.receipt_long_outlined,
  'shopping_cart': Icons.shopping_cart_outlined,
  'bolt': Icons.bolt_outlined,
  // Ikon target tabungan
  'flag': Icons.flag_outlined,
  'kitchen': Icons.kitchen_outlined,
  'shield': Icons.shield_outlined,
  'home_repair': Icons.home_repair_service_outlined,
  'celebration': Icons.celebration_outlined,
  'inventory_2': Icons.inventory_2_outlined,
};

String iconToKey(IconData icon) {
  for (final e in iconRegistry.entries) {
    if (e.value == icon) return e.key;
  }
  return 'category';
}

IconData iconFromKey(String? key, {IconData fallback = Icons.category_outlined}) =>
    iconRegistry[key] ?? fallback;
