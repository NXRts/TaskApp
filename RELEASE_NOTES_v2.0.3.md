# TaskApp v2.0.3 — Full-State JSON Backup & Adaptive Android System Navigation Bar

> **TaskApp v2.0.3** menghadirkan **100% Full-State JSON Export & Import** tanpa terkecuali, memperbaiki warna **System Navigation Bar** Android di bagian bawah layar agar menyatu sempurna dengan tema gelap/terang, serta menyertakan dokumen spesifikasi **PRD (Product Requirements Document)** lengkap.

---

## ✨ Apa yang Baru di Versi 2.0.3 (Changelog)

### 🎨 1. Perbaikan Bilah Navigasi Bawah Android (System Navigation Bar & Status Bar)
* **Sinkronisasi Penuh dengan Tema Gelap & Terang (`SystemUiOverlayStyle`)**: Memperbaiki masalah bilah navigasi sistem Android (3 tombol di bagian paling bawah layar) yang sebelumnya berwarna putih terang saat aplikasi berada di Mode Gelap.
* Kini bilah navigasi sistem Android secara otomatis menyesuaikan warnanya dengan permukaan aplikasi (`#16181D` pada *Dark Mode* dan `#FFFFFF` pada *Light Mode*), lengkap dengan warna ikon tombol sistem yang kontras dan *divider* tipis yang serasi.
* Memperbarui `NormalTheme` pada konfigurasi native Android (`styles.xml`) agar tidak memunculkan kilatan warna putih saat inisialisasi awal.

### 💾 2. 100% Full-State JSON Export & Import (Tanpa Terkecuali)
* **Cakupan Data 100% Utuh (`version: 2`)**:
  * **Profil Akademik (`user_profile`)**: Nama lengkap, universitas/kampus, program studi, dan semester aktif.
  * **Pengaturan & Statistik Fokus (`settings`)**: Preferensi tema (`is_dark_mode`), total sesi fokus Pomodoro (`completed_pomodoro_sessions`), total menit fokus (`total_focus_minutes`), serta seluruh pasangan *key-value* mentah (`raw_settings`).
  * **Mata Kuliah (`subjects`)**: Seluruh daftar mata kuliah beserta kode, dosen, ruangan, SKS, warna, hari, dan jam kuliah.
  * **Tugas & Sub-tugas (`tasks`)**: Seluruh tugas akademik maupun pribadi beserta daftar `subtasks`, tautan lampiran (`attachments`), catatan (`notes`), status penyelesaian, waktu selesai (`completedAt`), dan waktu pembuatan (`createdAt`).
* **Dialog Ekspor Interaktif & Pratinjau JSON**: Menyalin otomatis ke *Clipboard*, menampilkan ringkasan statistik data yang diekspor, serta menyediakan pratinjau JSON lengkap dengan tombol **Salin Ulang**.
* **Impor 1-Klik & Pembaruan Reaktif Seketika**: Dilengkapi tombol **Tempel dari Clipboard** dan langsung memperbarui seluruh tampilan aplikasi (tema, profil, matkul, SKS, tugas, dan statistik fokus) tanpa perlu me-restart aplikasi.

### 📖 3. Dokumentasi PRD (`PRD_TaskApp_Redesign.md`)
* Menambahkan dokumen spesifikasi produk dan arsitektur data lengkap (`PRD_TaskApp_Redesign.md`).

---

## 📥 Panduan Instalasi (Android APK)

1. Unduh file **`TaskApp-v2.0.3.apk`** atau **`app-release.apk`** dari bagian **Assets** di bawah.
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

**Full Changelog**: https://github.com/NXRts/TaskApp/compare/v2.0.2...v2.0.3

