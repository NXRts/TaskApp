# TaskApp v2.0.5 — Chronological Course Scheduling & Automatic Day-Time Sorting

> **TaskApp v2.0.5** menghadirkan pengurutan otomatis daftar mata kuliah berdasarkan **hari perkuliahan** (Senin–Minggu) dan **jam mulai perkuliahan**, sehingga jadwal kuliah tampil rapi, terstruktur, dan kronologis.

---

## ✨ Apa yang Baru di Versi 2.0.5 (Changelog)

### 📚 1. Pengurutan Otomatis Jadwal Mata Kuliah (Chronological Course Sorting)
* **Urut Berdasarkan Hari & Jam**: Daftar mata kuliah di tab **Matkul** kini secara otomatis diurutkan secara kronologis berdasarkan:
  1. **Hari Perkuliahan**: Mulai dari Senin (1), Selasa (2), Rabu (3), Kamis (4), Jumat (5), Sabtu (6), hingga Minggu (7).
  2. **Jam Mulai Kuliah**: Parsing otomatis waktu mulai dari rentang jam kuliah (misal `07.00`, `09.30`, `13.10`, `13.20`), mendukung format pemisah titik (`.`) maupun titik dua (`:`).
  3. **Abjad Nama**: Jika hari dan jam sama, diurutkan menurut abjad. Mata kuliah tanpa jadwal ditempatkan di paling akhir.
* **Integrasi Menyeluruh**: Pengurutan aktif di seluruh komponen aplikasi:
  * Layar utama **Mata Kuliah** (`SubjectsScreen`)
  * Dropdown pemilihan mata kuliah saat membuat tugas (`AddTaskModal`)
  * Layar detail dan cadangan data

---

## 📥 Panduan Instalasi (Android APK)

1. Unduh file **`TaskApp-v2.0.5.apk`** atau **`app-release.apk`** dari bagian **Assets** di bawah.
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

**Full Changelog**: https://github.com/NXRts/TaskApp/compare/v2.0.4...v2.0.5
