# 📱 TaskApp — Modern Editorial Productivity, Academic & Financial Student Hub

[![Release](https://img.shields.io/github/v/release/NXRts/TaskApp?color=emerald&style=flat-square)](https://github.com/NXRts/TaskApp/releases/latest)
[![Build Status](https://img.shields.io/github/actions/workflow/status/NXRts/TaskApp/build-release.yml?branch=main&style=flat-square)](https://github.com/NXRts/TaskApp/actions)
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Linux-success?style=flat-square&logo=flutter)](https://github.com/NXRts/TaskApp/releases/latest)
[![Offline-First](https://img.shields.io/badge/storage-Hive%20Offline--First-orange?style=flat-square)](https://pub.dev/packages/hive)

> **TaskApp** adalah sistem operasi produktivitas akademik dan manajemen keuangan harian mahasiswa dengan pendekatan **Modern Editorial Productivity × Premium Minimalism**. Dibangun khusus untuk mahasiswa aktif yang membutuhkan perencana studi berfokus tinggi, bebas iklan, bebas distraksi, memahami beban SKS perkuliahan, dan bekerja **100% offline-first**.

[📥 **Unduh APK Rilis Terbaru**](https://github.com/NXRts/TaskApp/releases/latest) · [✨ Catatan Rilis Terbaru](RELEASE_NOTES.md) · [📖 Dokumentasi Desain (PRD)](PRD_TaskApp_Redesign.md)

---

## ✨ Fitur Utama

### 1. Dual-Mode Task Management & Lampiran Berkas Offline

* **Mode Akademik & Personal**:
  * Kelompokkan tugas berdasarkan **Mata Kuliah** aktif (*Tugas Individu, Tugas Kelompok, Kuis, UTS/UAS, Laporan Praktikum*) maupun aktivitas personal harian.
  * Pecah tugas besar menjadi **Sub-tugas** dengan indikator progres persentase dinamis dan penanda warna urgensi deadline.
* **Lampiran Kamera, Galeri, PDF & Tautan (100% Offline)**:
  * Ambil foto catatan papan tulis langsung dari **Kamera**, pilih multi-foto dari **Galeri**, lampirkan berkas **PDF Soal/Materi**, atau simpan tautan URL (Google Drive, LMS/Spada, Zoom).
  * Dilengkapi **Penampil Gambar Interaktif** (*pinch-to-zoom* & *pan*) serta **Pembaca PDF Tersemat** langsung di dalam aplikasi tanpa internet.

### 2. Fokus Belajar: Timer Pomodoro & Multi-Track Ambient Sounds Mixer

* **Timer Pomodoro (25m Fokus / 5m Rehat)**:
  * Hubungkan sesi fokus langsung ke tugas spesifik yang sedang dikerjakan, lengkap dengan bunyi lonceng zen, getaran haptik, notifikasi penyelesaian sesi, dan pencatat total sesi/menit fokus.
* **Tab Ambient Sounds Terpisah (Multi-Track Audio Mixer)**:
  * Menyediakan **9 lanskap suara alam & suasana offline** (*Rain, Fireplace, River, Wind, Cafe Ambience, Morning Birds, Thunderstorm, Nature Night, Ocean Waves*).
  * **Pemutaran Simultan**: Seluruh 9 suara dapat dinyalakan bersamaan dan dicampur bebas dengan slider volume masing-masing tanpa mengulang posisi audio dari awal saat volume diubah.
  * Dilengkapi **Master Volume Slider**, **Sleep Timer** (`No Timer`, `15 Minutes`, `30 Minutes`, `45 Minutes`, `1 Hour`), tombol **`Play All` / `Pause All`**, dan **`Reset`**.

### 3. Manajemen Mata Kuliah, Matriks Jadwal & Attendance Sentinel

* **Manajemen Mata Kuliah & SKS**: Kelola nama matkul, kode, dosen pengampu, ruangan, bobot SKS, hari, jam kuliah, dan label warna kustom.
* **Matriks Jadwal Kuliah Mingguan Visual**: Grid jadwal Senin–Sabtu (`06:00–16:00`) dengan blok warna proporsional dan penyorotan otomatis celah waktu belajar kosong (*Free Study Window*).
* **Attendance Sentinel (Presensi 16 Pertemuan)**: Lacak status kehadiran per pertemuan (*Hadir, Sakit, Izin, Alfa*) dengan kalkulasi otomatis batas aman minimal kehadiran 75% dan sisa kuota absen.

### 4. Kalender Bulanan Penuh, Strip Mingguan & Garis Waktu Harian 24 Jam

* **Sakelar `Strip` | `Bulanan` (*Monthly Grid View*)**:
  * Beralih instan antara pita tanggal horizontal dan kisi kalender 1 bulan penuh (Senin–Minggu) dengan navigasi antarbulan (`<` / `>` & *horizontal swipe*).
  * Menampilkan indikator titik warna semantik deadline tugas, batang warna hari kuliah aktif, legenda ringkas, dan jumlah tugas bulanan.
* **Garis Waktu Harian 24 Jam (`00:00–24:00`)**:
  * Visualisasi jadwal kuliah dan tenggat tugas per jam, mendukung sakelar format **24 Jam** / **12 Jam (AM/PM)**, garis penanda waktu saat ini (*live time indicator*), dan *tap-to-schedule* pada setiap slot jam.

### 5. FinTrack Mahasiswa (Buku Kas & Uang Harian Anak Kos)

* **Kalkulator *Safe-to-Spend Today***: Menghitung batas aman pengeluaran makan & kebutuhan harian berdasarkan sisa saldo, anggaran amplop, dan sisa hari pada bulan berjalan.
* **Multi-Dompet & Live Currency Formatter**: Kelola saldo **Tunai**, **Bank**, dan **E-Wallet** dengan pemformatan titik ribuan Rupiah otomatis saat mengetik.
* **Amplop Anggaran Bulanan (*Envelope Budgeting*)**: Pantau penyerapan anggaran *Kos & Tagihan*, *Makan Harian*, *Kebutuhan Kuliah*, dan *Self-Reward*.
* **Patungan & Piutang Teman (*Split Bill & IOU Tracker*)**: Catat uang talangan teman atau pinjaman lengkap dengan aksi 1-ketuk **Tandai Lunas** dan analisis arus kas bulanan.

### 6. Studio Ekspor Jadwal (Wallpaper Lockscreen 9:16 PNG & PDF A4)

* **Ekspor Wallpaper 9:16 PNG**: Hasilkan gambar jadwal kuliah beresolusi tinggi dengan tema Obsidian Gelap (opsi tata letak Otomatis, 2 Kolom, atau 1 Kolom) yang langsung tersimpan ke Galeri perangkat (`Pictures/TaskApp`).
* **Ekspor Dokumen Ringkasan Studi (PDF A4)**: Cetak atau bagikan dokumen PDF berisi jadwal kuliah, dosen, ruangan, dan *checklist* tugas aktif.

### 7. Pengingat Deadline Multi-Tier & Full-State JSON Backup

* **Alarm Deadline 3 Tingkat**: Notifikasi terjadwal otomatis pada **H-1 Hari (19:00)**, **H-3 Jam**, dan **H-30 Menit** sebelum tenggat tugas dengan saluran audio alarm khusus dan banner layar kunci.
* **100% Offline-First & Full-State JSON Backup**: Seluruh data tersimpan di perangkat menggunakan **Hive NoSQL** tanpa akun/cloud wajib, dilengkapi fitur ekspor dan pemulihan cadangan JSON menyeluruh.

---

## 🏗️ Struktur Proyek

```text
lib/
├── main.dart                                 # Inisialisasi Hive, layanan notifikasi, MultiProvider
├── models/
│   ├── attendance_record.dart                # Model riwayat kehadiran per pertemuan kuliah
│   ├── finance_envelope.dart                 # Model amplop anggaran bulanan FinTrack
│   ├── finance_loan.dart                     # Model catatan patungan & piutang/hutang teman
│   ├── finance_settings.dart                 # Model pengaturan anggaran FinTrack
│   ├── finance_transaction.dart              # Model transaksi pemasukan & pengeluaran
│   ├── finance_wallet.dart                   # Model dompet (Tunai, Bank, E-Wallet)
│   ├── subject.dart                          # Model mata kuliah (SKS, dosen, ruang, jadwal, presensi)
│   ├── subtask.dart                          # Model sub-tugas
│   ├── task.dart                             # Model tugas (prioritas, tipe, kategori, lampiran)
│   └── user_profile.dart                     # Model profil akademik mahasiswa
├── providers/
│   ├── finance_provider.dart                 # State management FinTrack & kalkulasi Safe-to-Spend
│   ├── settings_provider.dart                # State management tema, profil, pengingat & statistik fokus
│   ├── subject_provider.dart                 # State management mata kuliah, SKS & presensi
│   └── task_provider.dart                    # State management tugas, filter, pencarian & sinkronisasi alarm
├── screens/
│   ├── attachment_image_viewer_screen.dart   # Penampil lampiran foto internal (zoom, pan & share)
│   ├── attachment_pdf_viewer_screen.dart     # Pembaca dokumen PDF lampiran tugas tersemat
│   ├── calendar_screen.dart                  # Kalender Strip/Bulanan & garis waktu jadwal 24 jam
│   ├── finance_screen.dart                   # Layar utama FinTrack Mahasiswa
│   ├── home_screen.dart                      # Beranda, ringkasan akademik, kartu Safe-to-Spend & daftar tugas
│   ├── main_screen.dart                      # Shell navigasi bawah 5 tab utama & FAB kontekstual
│   ├── pomodoro_screen.dart                  # Menu Fokus: tab Timer Pomodoro & tab Ambient Sounds
│   ├── profile_settings_screen.dart          # Pengaturan profil, uji alarm, backup JSON & dukungan kreator
│   ├── schedule_export_screen.dart           # Studio ekspor Wallpaper 9:16 PNG & dokumen PDF A4
│   ├── subject_detail_screen.dart            # Detail mata kuliah, matriks Attendance Sentinel & tugas terkait
│   └── subjects_screen.dart                  # Daftar mata kuliah & matriks jadwal mingguan
├── services/
│   ├── ambient_sound_service.dart            # Mesin multi-track audio mixer 9 suara ambient offline
│   ├── pomodoro_alert_service.dart           # Lonceng zen & notifikasi selesai sesi Pomodoro
│   ├── schedule_export_service.dart          # Generator PNG Wallpaper ke galeri & dokumen PDF A4
│   ├── storage_service.dart                  # Persistensi lokal Hive NoSQL & Full-State JSON Backup
│   ├── task_attachment_service.dart          # Pengelola penyimpanan berkas lampiran lokal (foto & PDF)
│   └── task_reminder_service.dart            # Penjadwal alarm deadline multi-tier (H-1, H-3 Jam, H-30 Menit)
├── utils/
│   ├── app_theme.dart                        # Sistem desain Material 3 (Light & Dark Editorial Mode)
│   ├── currency_input_formatter.dart         # Pemformat input pemisah ribuan Rupiah real-time
│   ├── date_formatter.dart                   # Utilitas format tanggal & hitung mundur bahasa Indonesia
│   └── external_link_helper.dart             # Pembuka tautan eksternal lintas platform & fallback clipboard
└── widgets/
    ├── add_loan_dialog.dart                  # Dialog catat patungan & piutang/hutang teman
    ├── add_subject_dialog.dart               # Dialog tambah/edit mata kuliah & jadwal
    ├── add_task_modal.dart                   # Modal tambah/edit tugas beserta pemilih lampiran
    ├── add_transaction_modal.dart            # Modal input cepat transaksi pemasukan/pengeluaran
    ├── adjust_wallet_dialog.dart             # Dialog penyesuaian saldo dompet
    ├── ambient_sounds_view.dart              # Tampilan mixer 9 Ambient Sounds (Master, Timer, Play All)
    ├── edit_envelope_dialog.dart             # Dialog atur batas anggaran amplop bulanan
    ├── finance_home_card.dart                # Kartu ringkas Safe-to-Spend Hari Ini di beranda
    ├── monthly_calendar_grid.dart            # Widget kisi kalender 1 bulan penuh & penanda titik warna
    ├── summary_card.dart                     # Kartu ringkasan beban SKS & progres tugas di beranda
    ├── support_creator_card.dart             # Kartu dukungan pengembang (Saweria, Ko-fi, Yapp.ink)
    ├── task_attachment_picker_sheet.dart     # Bottom sheet pemilih lampiran (Kamera, Galeri, PDF, URL)
    ├── task_attachment_tile.dart             # Kartu item lampiran berkas/tautan
    ├── task_card.dart                        # Kartu tugas di daftar beranda & kalender
    ├── task_detail_modal.dart                # Modal detail tugas, checklist sub-tugas & galeri lampiran
    ├── timetable_matrix_view.dart            # Matriks visual jadwal kuliah mingguan & slot waktu kosong
    └── wallpaper_schedule_widget.dart        # Kanvas render wallpaper jadwal kuliah 9:16
```

---

## 🚀 Cara Menjalankan Aplikasi

Pastikan Flutter SDK telah terpasang di perangkat Anda.

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

### 4. Build APK Rilis untuk Android

Untuk menghasilkan berkas installer `.apk` yang siap dipasang langsung di smartphone:

```bash
flutter build apk --release
```

Berkas APK akan tersedia di `build/app/outputs/flutter-apk/app-release.apk`.

---

## 💖 Dukung Pengembang (Support Me)

TaskApp dibangun dan dipelihara secara gratis, 100% offline-first, dan tanpa iklan. Jika aplikasi ini membantu aktivitas perkuliahan Anda, dukungan Anda sangat berarti untuk pengembangan fitur selanjutnya:

* **Saweria** (QRIS, GoPay, OVO, DANA): [saweria.co/yusufarrofi](https://saweria.co/yusufarrofi)
* **Ko-fi**: [ko-fi.com/yusufarrofi](https://ko-fi.com/yusufarrofi/)
* **Yapp.ink**: [yapp.ink/yusufarrofi21](https://yapp.ink/yusufarrofi21)
