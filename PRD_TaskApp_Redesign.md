# 📖 Product Requirements Document (PRD) — TaskApp

> **Modern Editorial Productivity, Offline-First Academic Planner & Student Financial Companion**

---

## 1. Visi & Filosofi Produk

**TaskApp** dirancang khusus untuk mahasiswa dan pelajar aktif yang membutuhkan sistem manajemen tugas perkuliahan, jadwal mata kuliah, presensi, buku kas keuangan harian, serta sesi fokus belajar yang cepat, bebas distraksi, dan bekerja **100% secara lokal (Offline-First)**.

### Prinsip Desain Utama (*Modern Editorial × Premium Minimalism*)

1. **Zero-Latency & 100% Offline**: Seluruh operasi baca/tulis menggunakan database lokal NoSQL (**Hive**) serta penyimpanan dokumen internal aplikasi dengan waktu muat di bawah 1 detik tanpa ketergantungan jaringan maupun akun cloud.
2. **Visual Tenang (*Anti-AI Slop*) & Sinkronisasi System UI**: Menggunakan palet kertas hangat (*Warm Bone Paper* `#FBFBF9`) untuk mode terang dan obsidian hangat (*Warm Obsidian* `#0E0F12`) untuk mode gelap, garis batas tipis (*hairline border* `0.8px`), indikator warna semantik yang terkendali, serta sinkronisasi penuh dengan **Status Bar & Android System Navigation Bar** (`SystemUiOverlayStyle`).
3. **Navigasi Lintas Perangkat**: Mendukung interaksi penuh melalui layar sentuh (*touch*), klik-tahan-geser kursor (*mouse drag*), *trackpad*, dan *stylus* (`AppScrollBehavior`).
4. **Kedaulatan Data Penuh (*100% Data Sovereignty*)**: Pengguna memegang kendali penuh atas seluruh data mereka melalui fitur **Full-State JSON Export & Import** tanpa terkecuali.

---

## 2. Arsitektur Data & Modul Fitur

### 2.1 Manajemen Tugas Dual-Mode & Lampiran Lokal (`TaskItem`, `SubTask` & `TaskAttachmentService`)

* **Kategori**: Akademik (`academic`) dan Pribadi (`personal`).
* **Tipe Tugas Akademik**: *Tugas Individu, Tugas Kelompok, Kuis / Ujian Kecil, UTS / UAS, Laporan Praktikum, Umum*.
* **Prioritas & Urgensi Deadline**:
  * `low`, `medium`, `high`.
  * Indikator tenggat waktu otomatis: Merah (*Overdue* / $\le 24$ jam), Kuning ($\le 3$ hari), dan Hijau (Selesai).
* **Sub-tugas & Checklist Progres**:
  * Setiap tugas dapat dipecah menjadi daftar `SubTask` (`id`, `title`, `isCompleted`) dengan kalkulasi progres otomatis.
* **Lampiran Berkas & Foto Offline (`attachments`)**:
  * Mendukung pengambilan foto catatan papan tulis langsung dari **Kamera**, pemilihan multi-foto dari **Galeri**, dokumen **PDF Soal/Materi**, serta tautan URL eksternal.
  * Berkas lokal disalin ke penyimpanan internal aplikasi (`task_attachments`) dan dapat dibuka melalui **Penampil Gambar Interaktif** (`AttachmentImageViewerScreen`) maupun **Pembaca PDF Tersemat** (`AttachmentPdfViewerScreen`).

### 2.2 Pengingat Deadline Multi-Tier (`TaskReminderService`)

* Menjadwalkan alarm pengingat otomatis 3 tingkat untuk setiap tugas yang belum selesai:
  * **H-1 Hari (Pukul 19:00)**: Pengingat persiapan malam hari sebelum tenggat.
  * **H-3 Jam**: Peringatan darurat 3 jam sebelum batas pengumpulan.
  * **H-30 Menit**: Peringatan kritis menjelang penutupan pengumpulan.
* Menggunakan banner notifikasi layar kunci (*native lock screen banner* dengan `fullScreenIntent: false`), saluran audio alarm khusus (`task_alarm.mp3`), dan dukungan *in-app floating banner* pada desktop/foreground.

### 2.3 Manajemen Mata Kuliah, Matriks Jadwal & Attendance Sentinel (`Subject` & `AttendanceRecord`)

* Menyimpan atribut mata kuliah: `id`, `name`, `code`, `lecturer` (dosen pengampu), `room` (ruangan), `colorValue` (label warna ARGB), `creditHours` (bobot SKS), `dayOfWeek` (Senin–Minggu), `timeRange` (jam perkuliahan), `totalMeetings` (default 16), dan riwayat `absences`.
* **Pengurutan Kronologis Otomatis**: Daftar mata kuliah diurutkan berdasarkan hari perkuliahan (Senin–Minggu) dan jam mulai kuliah (`startMinutes`), disusul abjad nama mata kuliah.
* **Matriks Jadwal Mingguan (`TimetableMatrixView`)**: Menampilkan kisi visual jadwal kuliah Senin–Sabtu (`06:00–16:00`) serta mendeteksi slot waktu belajar kosong (*Free Study Window*).
* **Attendance Sentinel**: Melacak status kehadiran 16 pertemuan (*Hadir, Sakit, Izin, Alfa*), menghitung persentase kehadiran terhadap batas minimal 75%, dan menampilkan sisa kuota absen.

### 2.4 Kalender Bulanan Penuh, Strip Mingguan & Garis Waktu 24 Jam (`CalendarScreen` & `MonthlyCalendarGrid`)

* **Sakelar Tampilan `Strip` | `Bulanan`**:
  * **Mode Strip**: Pita tanggal horizontal 45 hari dengan pemusatan otomatis (*auto-center*) pada tanggal hari ini.
  * **Mode Bulanan (`MonthlyCalendarGrid`)**: Kisi kalender 1 bulan penuh berbasis awal pekan Senin (`SEN`–`MIN`), navigasi bulan (`<` / `>` & *horizontal swipe*), hingga 3 titik warna semantik deadline tugas, hingga 2 batang warna mata kuliah aktif per tanggal, legenda ringkas, dan penghitung total tugas bulanan.
* **Garis Waktu Harian 24 Jam (`00:00–24:00`)**:
  * Menampilkan blok jadwal kuliah dan kartu tenggat tugas secara proporsional per jam, sakelar format **24 Jam** / **12 Jam (AM/PM)**, garis penanda waktu berjalan (*live current time line*), dan aksi *tap-to-schedule* pada setiap slot jam.

### 2.5 Studio Ekspor Jadwal (`ScheduleExportScreen` & `ScheduleExportService`)

* **Wallpaper Lockscreen 9:16 PNG (`WallpaperScheduleWidget`)**: Merender jadwal kuliah dan tugas ke kanvas `1080×1920` bertema Obsidian Gelap (tata letak Otomatis, 2 Kolom, atau 1 Kolom) dan menyimpannya langsung ke Galeri perangkat (`Pictures/TaskApp`).
* **Dokumen Ringkasan Studi PDF A4**: Menghasilkan dokumen PDF standar cetak berisi identitas mahasiswa, tabel jadwal kuliah, dan *checklist* tugas.

### 2.6 FinTrack Mahasiswa (`FinanceProvider` & `FinanceScreen`)

* **Kalkulator *Safe-to-Spend Today***: Menghitung batas aman pengeluaran harian mahasiswa berdasarkan total saldo aktif, alokasi anggaran, dan sisa hari di bulan berjalan, dilengkapi kartu ringkas `FinanceHomeCard` di beranda yang terhubung langsung ke tab Keuangan (`MainScreen.switchTab`).
* **Multi-Dompet (`FinanceWallet`)**: Mengelola saldo *Tunai*, *Bank*, dan *E-Wallet* dengan pemformatan titik ribuan Rupiah otomatis (*Live Currency Input Formatter*).
* **Amplop Anggaran Bulanan (`FinanceEnvelope`)**: Mengatur batas dan memantau penyerapan anggaran per kategori kebutuhan mahasiswa.
* **Pencatat Patungan & Piutang Teman (`FinanceLoan`)**: Mencatat piutang (*Saya Talangi*) dan hutang (*Saya Pinjam*) beserta penyelesaian 1-klik **Tandai Lunas**.

### 2.7 Mode Fokus Belajar: Timer Pomodoro & Multi-Track Ambient Sounds (`PomodoroScreen`, `AmbientSoundsView` & `AmbientSoundService`)

* **Tab `Timer Pomodoro`**:
  * Timer fokus 25 menit dan rehat 5 menit yang dapat ditautkan ke tugas spesifik.
  * Terintegrasi dengan `PomodoroAlertService` (bunyi lonceng `focus_complete.wav` & `break_complete.wav`, getaran haptik, dan notifikasi sistem) serta pencatatan statistik sesi fokus.
* **Tab `Ambient Sounds` Terpisah (Multi-Track FocEase Mixer)**:
  * Menyediakan **9 lanskap suara alam & suasana offline** (*Rain, Fireplace, River, Wind, Cafe Ambience, Morning Birds, Thunderstorm, Nature Night, Ocean Waves*).
  * **Pemutaran Simultan (Multi-Track Mixer)**: Seluruh 9 suara dapat diputar bersamaan dengan slider volume individual (`0%–100%`) yang mengubah amplitudo secara real-time tanpa mengulang posisi audio dari awal.
  * Dilengkapi **Master Volume Slider**, **Sleep Timer** (`No Timer`, `15 Minutes`, `30 Minutes`, `45 Minutes`, `1 Hour`), tombol **`Play All` / `Pause All`**, dan **`Reset`**.

---

## 3. Spesifikasi Kedaulatan Data: Full-State JSON Export & Import

Fitur **Cadangan & Kedaulatan Data** (`StorageService.exportBackupJson` & `StorageService.importBackupJson`) menjamin **seluruh data pengguna tanpa terkecuali** dapat diekspor ke teks JSON terstruktur dan dipulihkan kembali 100% utuh di perangkat mana pun.

### 3.1 Cakupan Data Tanpa Terkecuali (100% State Coverage)

1. **Identitas & Profil Akademik (`user_profile`)**:
   * `name`, `campus`, `studyProgram`, dan `semester`.
2. **Pengaturan Aplikasi, Preferensi Kalender, Alarm & Ambient Mixer (`settings`)**:
   * `is_dark_mode`, `completed_pomodoro_sessions`, `total_focus_minutes`, `has_seeded_v1`, serta `raw_settings` (mencakup format waktu 24 jam, mode kalender bulanan, pengaturan pengingat H-1/H-3h/H-30m, Master Volume, Sleep Timer, dan volume 9 track Ambient Sounds).
3. **Seluruh Daftar Mata Kuliah & Riwayat Presensi (`subjects` dari `subjects_box_v1`)**:
   * Mencakup `id`, `name`, `code`, `lecturer`, `room`, `colorValue`, `creditHours`, `dayOfWeek`, `timeRange`, `totalMeetings`, dan daftar `absences`.
4. **Seluruh Daftar Tugas, Sub-tugas & Lampiran (`tasks` dari `tasks_box_v1`)**:
   * Mencakup `id`, `title`, `description`, `subjectId`, `dueDate`, `isCompleted`, `completedAt`, `priority`, `category`, `taskType`, `attachments`, `notes`, `createdAt`, serta array `subtasks`.
5. **Seluruh Data Keuangan FinTrack (`finance_wallets`, `finance_transactions`, `finance_envelopes`, `finance_loans`, `finance_settings`)**:
   * Mencakup seluruh saldo dompet, riwayat transaksi pemasukan/pengeluaran, amplop anggaran bulanan, dan catatan piutang/hutang teman.

### 3.2 Skema JSON Cadangan Lengkap

```json
{
  "app": "TaskApp",
  "version": 2,
  "exportedAt": "2026-11-22T16:00:00.000",
  "summary": {
    "subjects_count": 1,
    "total_credit_hours": 3,
    "tasks_count": 1,
    "completed_tasks_count": 0,
    "pending_tasks_count": 1,
    "subtasks_count": 2,
    "completed_pomodoro_sessions": 4,
    "total_focus_minutes": 100,
    "finance_wallets_count": 3,
    "finance_transactions_count": 1,
    "finance_loans_count": 0
  },
  "user_profile": {
    "name": "Mahasiswa Juara",
    "campus": "Universitas Indonesia",
    "studyProgram": "Teknik Informatika",
    "semester": 5
  },
  "settings": {
    "is_dark_mode": true,
    "completed_pomodoro_sessions": 4,
    "total_focus_minutes": 100,
    "has_seeded_v1": true,
    "raw_settings": {
      "is_dark_mode": true,
      "calendar_is_monthly_view": true,
      "ambient_master_volume": 1.0,
      "ambient_timer_duration": 0
    }
  },
  "subjects": [
    {
      "id": "uuid-subject-1",
      "name": "Algoritma & Struktur Data",
      "code": "IF-201",
      "lecturer": "Dr. Budi",
      "room": "Lab 1",
      "colorValue": 4283385573,
      "creditHours": 3,
      "dayOfWeek": 1,
      "timeRange": "08:00 - 10:30",
      "totalMeetings": 16,
      "absences": []
    }
  ],
  "tasks": [
    {
      "id": "uuid-task-1",
      "title": "Implementasi Red-Black Tree",
      "description": "Kerjakan dalam bahasa Dart beserta unit test",
      "subjectId": "uuid-subject-1",
      "dueDate": "2026-11-25T23:59:00.000",
      "isCompleted": false,
      "completedAt": null,
      "priority": 2,
      "category": 0,
      "taskType": 4,
      "subtasks": [
        {
          "id": "uuid-sub-1",
          "title": "Buat operasi rotasi kiri & kanan",
          "isCompleted": true
        },
        {
          "id": "uuid-sub-2",
          "title": "Tulis pengujian penambahan node",
          "isCompleted": false
        }
      ],
      "attachments": [
        "https://github.com/example/rbt"
      ],
      "notes": "Kumpulkan sebelum tengah malam",
      "createdAt": "2026-11-20T10:00:00.000"
    }
  ],
  "finance_wallets": [],
  "finance_transactions": [],
  "finance_envelopes": [],
  "finance_loans": [],
  "finance_settings": {}
}
```

### 3.3 Alur Kerja Ekspor & Impor Reaktif

* **Alur Ekspor (`Ekspor JSON`)**:
  1. Mengambil seluruh state terbaru dari keenam box Hive (`_subjectsBox`, `_tasksBox`, `_settingsBox`, `_financeBox`, `_financeTransactionsBox`, `_financeLoansBox`).
  2. Mengonversi seluruh data menjadi JSON terformat rapi (*pretty-printed* 2 spasi) dan menyalinnya otomatis ke *Clipboard*.
  3. Menampilkan dialog ringkasan data beserta pratinjau JSON yang dapat diseleksi dan disalin ulang.
* **Alur Impor (`Impor JSON`)**:
  1. Menyediakan tombol cepat **Tempel dari Clipboard** (*1-Click Paste*) maupun input teks manual.
  2. Memvalidasi struktur JSON dan memulihkan seluruh mata kuliah, tugas, profil, pengaturan, serta data keuangan FinTrack ke Hive.
  3. Memicu pembaruan state reaktif seketika pada seluruh provider tanpa perlu me-restart aplikasi.
