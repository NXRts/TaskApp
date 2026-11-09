# TaskApp v2.0.1 — Patch Release & Data Cleanliness

> **TaskApp v2.0.1** membawa perbaikan penting pada persistensi penyimpanan offline (Hive LocalStorage), pencegahan bug reseeding data otomatis, serta pembersihan menyeluruh data dummy bawaan.

---

## ✨ Apa yang Baru di Versi 2.0.1 (Changelog)

### 🐛 1. Perbaikan Bug Reseeding Data Demo (Persistence Fix)
* **Masalah**: Ketika pengguna menghapus seluruh daftar tugas atau mata kuliah, aplikasi salah mendeteksi kondisi database kosong sebagai "penginstalan pertama" (*first run*), sehingga 4 mata kuliah demo dan 4 tugas demo muncul kembali saat aplikasi ditutup dan dibuka ulang.
* **Solusi**:
  * Menambahkan penanda persistensi permanen `has_seeded_v1` di `settingsBox`.
  * Menerapkan **Singleton Pattern** pada `StorageService` untuk memastikan konsistensi instans database di seluruh siklus hidup aplikasi.
  * Menambahkan blok pelindung `try-catch` saat operasi penghapusan data ke disk.

### 🧹 2. Pembersihan Total Data Dummy (Clean Canvas)
* Menghapus seluruh data demo bawaan (tugas dan mata kuliah dummy) agar pengguna langsung memulai dengan aplikasi yang bersih.
* Menambahkan rutin pembersihan otomatis di `StorageService.init()` untuk menghapus cache data dummy lama (`task-1` s/d `task-4`, `sub-1` s/d `sub-4`) pada instalasi perangkat yang sudah ada.
* **Profil pengguna (`user_profile`) dan pengaturan tema (Dark/Light mode) tetap dipertahankan dengan aman**.

### 🎨 3. Penyempurnaan Ikon Aplikasi Editorial
* Menggunakan ikon peluncur aplikasi (*adaptive app launcher icon*) bergaya editorial modern yang tajam di berbagai resolusi Android.

---

## 📥 Panduan Instalasi (Android APK)

1. Unduh file **`TaskApp-v2.0.1.apk`** atau **`app-release.apk`** dari bagian **Assets** di bawah.
2. Buka file APK yang telah diunduh di smartphone Android Anda.
3. Jika diminta izin instalasi dari sumber tak dikenal, pilih **Izinkan (Allow)**.
4. Tekan **Pasang (Install)** / **Perbarui (Update)**.
5. Selesai! Data profil dan pengaturan tema Anda akan tetap tersimpan secara aman.

---

## 📱 Spesifikasi Sistem
* **Sistem Operasi**: Android 6.0 (Marshmallow, API 23) ke atas
* **Arsitektur**: `arm64-v8a`, `armeabi-v7a`, `x86_64`
* **Kebutuhan Jaringan**: 100% Offline (Bekerja penuh tanpa koneksi internet)
* **Ukuran File**: ~20 MB

---

**Full Changelog**: https://github.com/NXRts/TaskApp/compare/v2.0.0...v2.0.1
