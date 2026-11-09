# TaskApp v2.0.4 — Redesigned Checklist App Icon & Unified "TaskApp" Branding

> **TaskApp v2.0.4** menghadirkan desain ikon aplikasi baru bergaya **Modern Minimalist Checklist / Kartu Tugas** (dengan dukungan penuh **Android Adaptive Icon**), serta menyeragamkan judul dan nama aplikasi menjadi **"TaskApp"** di seluruh platform.

---

## ✨ Apa yang Baru di Versi 2.0.4 (Changelog)

### 🎨 1. Ikon Aplikasi Baru (Modern Minimalist Checklist & Adaptive Icon)
* **Desain Kartu Tugas & Checklist Modern**: Menggunakan palet *Warm Obsidian* (`#0E0F12`), permukaan kartu `#16181D`, dan aksen *Electric Cobalt* (`#3B82F6`) dengan tiga baris status tugas yang tajam dan jelas di ukuran layar apa pun.
* **Dukungan Penuh Android Adaptive Icon (API 26+)**: Menambahkan konfigurasi `mipmap-anydpi-v26/ic_launcher.xml` dan `ic_launcher_round.xml` dengan layer `ic_launcher_foreground` dan warna latar `#0E0F12`, sehingga ikon tampil penuh dan proporsional di semua jenis launcher Android (bulat, *squircle*, maupun *teardrop*) tanpa bingkai putih tambahan.
* **Multi-Platform Icon Assets**: Memperbarui seluruh aset ikon di Android (`mdpi` hingga `xxxhdpi`), iOS (`AppIcon.appiconset`), Web (`favicon.png`, `Icon-192`, `Icon-512`, `maskable`), macOS, dan Windows (`app_icon.ico`).

### 🏷️ 2. Penyeragaman Judul Aplikasi Menjadi `"TaskApp"`
* Memperbarui judul aplikasi menjadi **`"TaskApp"`** secara konsisten di:
  * Flutter `MaterialApp` (`lib/main.dart`)
  * Android (`AndroidManifest.xml`)
  * iOS (`Info.plist`: `CFBundleDisplayName` & `CFBundleName`)
  * Web (`index.html` & `manifest.json`)
  * Linux (`my_application.cc`), macOS (`AppInfo.xcconfig`), dan Windows (`main.cpp`)

---

## 📥 Panduan Instalasi (Android APK)

1. Unduh file **`TaskApp-v2.0.4.apk`** atau **`app-release.apk`** dari bagian **Assets** di bawah.
2. Buka file APK yang telah diunduh di smartphone Android Anda.
3. Jika diminta izin instalasi dari sumber tak dikenal, pilih **Izinkan (Allow)**.
4. Tekan **Pasang (Install)** / **Perbarui (Update)**.
5. Selesai! Data tugas, mata kuliah, dan profil Anda akan tetap tersimpan secara aman.

---

## 📱 Spesifikasi Sistem
* **Sistem Operasi**: Android 6.0 (Marshmallow, API 23) ke atas
* **Arsitektur**: `arm64-v8a`, `armeabi-v7a`, `x86_64`
* **Kebutuhan Jaringan**: 100% Offline (Bekerja penuh tanpa koneksi internet)
* **Ukuran File**: ~20 MB

---

**Full Changelog**: https://github.com/NXRts/TaskApp/compare/v2.0.3...v2.0.4
