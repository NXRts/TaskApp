# TaskApp v2.0.2 — Interactive Scrolling & Smart Calendar Centering

> **TaskApp v2.0.2** meningkatkan kenyamanan navigasi lintas perangkat (Touch, Mouse, & Trackpad) serta menambahkan pemusatan otomatis (*auto-centering*) pada deretan tanggal kalender dan chip filter status.

---

## ✨ Apa yang Baru di Versi 2.0.2 (Changelog)

### 🖱️ 1. Dukungan Geser Lintas Perangkat (Cross-Device Drag & Swipe)
* Mengaktifkan `AppScrollBehavior` untuk seluruh perangkat input (`touch`, `mouse`, `trackpad`, dan `stylus`), sehingga semua komponen daftar horizontal maupun vertikal dapat langsung digeser (*click-and-drag* / *swipe*) dengan mulus.

### 📅 2. Pemusatan Otomatis Tanggal Sekarang di Kalender (Auto-Center Today)
* **Posisi Awal Presisi di Tengah**: Deretan tanggal pada layar Kalender kini otomatis menempatkan **tanggal hari ini (tanggal sekarang)** tepat di bagian **paling tengah** layar, sehingga tanggal-tanggal yang sudah terlewat tidak lagi memenuhi tampilan utama.
* **Deteksi Pergantian Hari Otomatis**: Jika hari berganti (tanggal sebelumnya sudah terlewat), kalender secara otomatis memperbarui fokus ke tanggal sekarang dan menggesernya ke tengah.
* **Animasi Geser Halus**: Menekan tombol **"Hari Ini"** atau memilih tanggal mana pun pada deretan kalender akan menggeser tanggal tersebut secara halus ke tengah layar (`Curves.easeOutCubic`).
* **Rentang Tanggal Lebih Luas**: Mendukung navigasi 14 hari ke belakang hingga 30 hari ke depan (total 45 hari).

### 🏷️ 3. Auto-Scroll Filter Status Tugas di Beranda
* Deretan chip filter status (`Semua`, `Hari Ini`, `Mendatang`, `Terlewat`, `Selesai`) kini dilengkapi `BouncingScrollPhysics` dan fitur *auto-center* (`Scrollable.ensureVisible`) saat chip yang berada di tepi layar dipilih.

---

## 📥 Panduan Instalasi (Android APK)

1. Unduh file **`TaskApp-v2.0.2.apk`** atau **`app-release.apk`** dari bagian **Assets** di bawah.
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

**Full Changelog**: https://github.com/NXRts/TaskApp/compare/v2.0.1...v2.0.2
