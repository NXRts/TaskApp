# 📱 TaskApp — Modern Editorial Productivity & Academic Planner

[![Release](https://img.shields.io/github/v/release/NXRts/TaskApp?color=emerald&style=flat-square)](https://github.com/NXRts/TaskApp/releases/latest)
[![Build Status](https://img.shields.io/github/actions/workflow/status/NXRts/TaskApp/build-release.yml?branch=main&style=flat-square)](https://github.com/NXRts/TaskApp/actions)
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android-success?style=flat-square&logo=android)](https://github.com/NXRts/TaskApp/releases/latest)
[![Offline-First](https://img.shields.io/badge/storage-Hive%20Offline--First-orange?style=flat-square)](https://pub.dev/packages/hive)

> **TaskApp** adalah aplikasi manajemen tugas kuliah dan aktivitas harian dengan pendekatan **Modern Editorial Productivity × Premium Minimalism**. Dibangun khusus untuk mahasiswa aktif yang membutuhkan aplikasi perencana studi yang berfokus tinggi, bebas distraksi (*Anti-AI Slop*), memahami beban SKS perkuliahan, dan bekerja **100% offline-first**.

[📥 **Unduh APK Rilis Terbaru (v2.0.1)**](https://github.com/NXRts/TaskApp/releases/download/v2.0.1/TaskApp-v2.0.1.apk) · [✨ Catatan Rilis (v2.0.1)](RELEASE_NOTES_v2.0.1.md) · [📖 Dokumentasi Desain (PRD)](PRD_TaskApp_Redesign.md)

---

## ✨ Fitur Utama

### 1. Dual-Mode Task Management
* **Mode Akademik (Kuliah)**:
  * Mengelompokkan tugas berdasarkan **Mata Kuliah** aktif.
  * Tipe tugas lengkap: *Tugas Individu, Tugas Kelompok, Kuis, UTS/UAS, Laporan Praktikum*.
  * Tautan lampiran (Google Drive, LMS/Spada, link Zoom).
* **Mode Personal (Pribadi)**:
  * To-do list harian untuk belanja, habit, atau kegiatan non-akademik.

### 2. Anti-Prokrastinasi & Sub-tugas
* **Pecah Sub-tugas**: Memecah tugas besar menjadi langkah-langkah kecil dengan indikator progres persentase yang dinamis.
* **Sesi Fokus (Pomodoro Timer)**: Timer belajar bawaan (25 menit fokus / 5 menit istirahat) yang dapat dihubungkan langsung ke tugas spesifik yang sedang dikerjakan.

### 3. Sistem Urgensi & Deadline Visual
* 🔴 **Merah**: Jatuh tempo < 24 jam atau terlewat (*overdue*).
* 🟡 **Oranye/Kuning**: Jatuh tempo 1–3 hari ke depan.
* 🔵 **Biru**: Deadline aman (> 3 hari).
* 🟢 **Hijau**: Tugas selesai.

### 4. Manajemen Mata Kuliah & Jadwal
* Kelola nama matkul, kode, dosen pengampu, ruangan, SKS, hari, dan jam kuliah.
* Label warna kustom per mata kuliah untuk identifikasi visual yang cepat.
* Tampilan detail mata kuliah yang menampilkan seluruh daftar tugas terkait matkul tersebut.

### 5. Kalender & Timeline
* Pemilih tanggal mingguan horizontal interaktif dengan indikator titik penanda adanya tugas.
* Filter berdasarkan tanggal untuk melihat beban tugas harian (*daily workload*).

### 6. LocalStorage Cepat & Offline-First
* Menggunakan **Hive NoSQL Key-Value Store** lokal.
* Tidak memerlukan internet, zero-loading time (< 1 detik buka aplikasi), data tersimpan aman di perangkat.
* Dilengkapi seed data demo otomatis saat pertama kali dibuka.

---

## 🏗️ Struktur Proyek

```
lib/
├── main.dart                      # Inisialisasi Hive, MultiProvider, MaterialApp
├── models/
│   ├── subtask.dart               # Model data sub-tugas
│   ├── subject.dart               # Model mata kuliah (SKS, dosen, ruang, warna)
│   ├── task.dart                  # Model tugas (urgensi, tipe, kategori, subtasks)
│   └── user_profile.dart          # Profil mahasiswa (nama, kampus, semester)
├── services/
│   └── storage_service.dart       # Layer persistensi lokal Hive NoSQL
├── providers/
│   ├── task_provider.dart         # State management & filter tugas
│   ├── subject_provider.dart      # State management mata kuliah & SKS
│   └── settings_provider.dart     # Dark mode & profil pengguna
├── screens/
│   ├── main_screen.dart           # Bottom navigation shell
│   ├── home_screen.dart           # Beranda, summary card, daftar tugas
│   ├── subjects_screen.dart       # Daftar mata kuliah
│   ├── subject_detail_screen.dart # Detail mata kuliah & tugas terkait
│   ├── calendar_screen.dart       # Kalender & jadwal per hari
│   ├── pomodoro_screen.dart       # Timer fokus belajar Pomodoro
│   └── profile_settings_screen.dart # Edit profil & semester
├── widgets/
│   ├── summary_card.dart          # Kartu ringkasan SKS & status deadline
│   ├── task_card.dart             # Kartu tugas dengan checkbox & badge
│   ├── add_task_modal.dart        # Modal bottom sheet input tugas
│   ├── task_detail_modal.dart     # Modal detail lengkap tugas & sub-tugas
│   └── add_subject_dialog.dart    # Dialog tambah/edit mata kuliah
└── utils/
    ├── app_theme.dart             # Tema Material 3 (Light & Dark Mode)
    └── date_formatter.dart        # Format tanggal & countdown deadline bahasa Indonesia
```

---

## 🚀 Cara Menjalankan Aplikasi

Pastikan Flutter SDK telah terpasang di komputer Anda.

### 1. Jalankan di Desktop (Linux)
```bash
flutter run -d linux
```

### 2. Jalankan di Web Browser (Chrome)
```bash
flutter run -d chrome
```

### 3. Jalankan di HP Android / Emulator
Hubungkan smartphone Android Anda via kabel USB (aktifkan USB Debugging) atau buka Android Emulator, lalu jalankan:
```bash
flutter run
```

### 4. Build APK untuk Android
Untuk menghasilkan file installer `.apk` yang siap dipasang langsung di smartphone:
```bash
flutter build apk --release
```
File APK akan berada di `build/app/outputs/flutter-apk/app-release.apk`.
