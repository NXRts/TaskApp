# 📖 Product Requirements Document (PRD) — TaskApp v2.0
**Modern Editorial Productivity & Offline-First Academic Planner**

---

## 1. Visi & Filosofi Produk
**TaskApp** dirancang khusus untuk mahasiswa dan pelajar aktif yang membutuhkan sistem manajemen tugas perkuliahan, jadwal mata kuliah, serta perencanaan harian yang cepat, bebas distraksi, dan bekerja **100% secara lokal (Offline-First)**.

### Prinsip Desain Utama (*Modern Editorial × Premium Minimalism*)
1. **Zero-Latency & 100% Offline**: Seluruh operasi baca/tulis menggunakan database lokal NoSQL (**Hive**) dengan waktu muat di bawah 1 detik tanpa ketergantungan jaringan maupun akun cloud.
2. **Visual Tenang (*Anti-AI Slop*) & Sinkronisasi System UI**: Menggunakan palet kertas hangat (*Warm Bone Paper* `#FBFBF9`) untuk mode terang dan obsidian hangat (*Warm Obsidian* `#0E0F12`) untuk mode gelap, garis batas tipis (*hairline border* `0.8px`), indikator warna semantik yang terkendali, serta sinkronisasi penuh dengan **Status Bar & Android System Navigation Bar** (`SystemUiOverlayStyle`) agar bilah navigasi bawah Android menyatu sempurna tanpa blok warna putih yang mengganggu di mode gelap.
3. **Navigasi Lintas Perangkat**: Mendukung interaksi penuh melalui layar sentuh (*touch*), klik-tahan-geser kursor (*mouse drag*), *trackpad*, dan *stylus* (`AppScrollBehavior`).
4. **Kedaulatan Data Penuh (*100% Data Sovereignty*)**: Pengguna memegang kendali penuh atas seluruh data mereka melalui fitur **Full-State JSON Export & Import** tanpa terkecuali.

---

## 2. Arsitektur Data & Modul Fitur

### 2.1 Manajemen Tugas Dual-Mode (`TaskItem` & `SubTask`)
* **Kategori**: Akademik (`academic`) dan Pribadi (`personal`).
* **Tipe Tugas Akademik**: *Tugas Individu, Tugas Kelompok, Kuis / Ujian Kecil, UTS / UAS, Laporan Praktikum, Umum*.
* **Prioritas & Urgensi Deadline**:
  * `low`, `medium`, `high`.
  * Indikator tenggat waktu otomatis: Merah (*Overdue* / $\le 24$ jam), Kuning ($\le 3$ hari), dan Hijau (Selesai).
* **Sub-tugas & Template Anti-Prokrastinasi**:
  * Setiap tugas dapat dipecah menjadi daftar `SubTask` (`id`, `title`, `isCompleted`) dengan kalkulasi progres otomatis.
  * Mendukung lampiran tautan (`attachments`) dan catatan tambahan (`notes`).

### 2.2 Manajemen Mata Kuliah (`Subject`)
* Menyimpan atribut mata kuliah: `id`, `name`, `code`, `lecturer` (dosen pengampu), `room` (ruangan), `colorValue` (label warna ARGB), `creditHours` (bobot SKS), `dayOfWeek` (Senin–Minggu), dan `timeRange` (jam perkuliahan).
* Menghitung total beban SKS semester aktif secara otomatis.

### 2.3 Kalender & Timeline Pintar (`CalendarScreen`)
* Menampilkan deretan tanggal horizontal (*45 hari*: 14 hari ke belakang, hari ini, dan 30 hari ke depan).
* **Auto-Center Tanggal Sekarang**: Secara otomatis menempatkan tanggal hari ini tepat di posisi paling tengah layar saat dibuka maupun saat terjadi pergantian hari (ketika tanggal sebelumnya sudah terlewat).
* Mendukung geser bebas (*drag/swipe*) ke kiri/kanan serta animasi pemusatan halus ketika tanggal dipilih.

### 2.4 Mode Fokus Belajar (`PomodoroScreen`)
* Timer fokus bergaya Zen (25 menit sesi fokus / 5 menit istirahat) yang dapat ditautkan ke tugas spesifik.
* Mencatat dan menyimpan akumulasi sesi fokus (`completed_pomodoro_sessions`) dan total menit fokus (`total_focus_minutes`) secara permanen di penyimpanan lokal.

---

## 3. Spesifikasi Kedaulatan Data: Full-State JSON Export & Import

Fitur **Cadangan & Kedaulatan Data** (`StorageService.exportBackupJson` & `StorageService.importBackupJson`) menjamin **seluruh data pengguna tanpa terkecuali** dapat diekspor ke teks JSON terstruktur dan dipulihkan kembali 100% utuh di perangkat mana pun.

### 3.1 Cakupan Data Tanpa Terkecuali (100% State Coverage)
1. **Identitas & Profil Akademik (`user_profile`)**:
   * `name` (Nama lengkap mahasiswa)
   * `campus` (Nama universitas/institusi)
   * `studyProgram` (Program studi/jurusan)
   * `semester` (Semester aktif)
2. **Pengaturan Aplikasi & Statistik Fokus (`settings`)**:
   * `is_dark_mode` (Preferensi tema Gelap / Terang)
   * `completed_pomodoro_sessions` (Total sesi fokus Pomodoro yang diselesaikan)
   * `total_focus_minutes` (Total durasi fokus dalam menit)
   * `has_seeded_v1` (Status inisialisasi penyimpanan lokal)
   * `raw_settings` (Seluruh pasangan *key-value* mentah di dalam `settings_box_v1` tanpa terkecuali)
3. **Seluruh Daftar Mata Kuliah (`subjects` dari `subjects_box_v1`)**:
   * Setiap entri mencakup: `id`, `name`, `code`, `lecturer`, `room`, `colorValue`, `creditHours`, `dayOfWeek`, `timeRange`.
4. **Seluruh Daftar Tugas & Sub-tugas (`tasks` dari `tasks_box_v1`)**:
   * Setiap entri mencakup: `id`, `title`, `description`, `subjectId`, `dueDate`, `isCompleted`, `completedAt`, `priority`, `category`, `taskType`, `attachments`, `notes`, `createdAt`, serta seluruh array `subtasks` (`id`, `title`, `isCompleted`).
5. **Metadata & Ringkasan Ekspor (`summary`)**:
   * Menyertakan versi skema (`version: 2`), waktu ekspor (`exportedAt`), jumlah mata kuliah, total SKS, jumlah tugas (selesai & tertunda), total sub-tugas, dan statistik sesi fokus.

### 3.2 Skema JSON Cadangan Lengkap
```json
{
  "app": "TaskApp",
  "version": 2,
  "exportedAt": "2026-11-09T17:05:00.000",
  "summary": {
    "subjects_count": 1,
    "total_credit_hours": 3,
    "tasks_count": 1,
    "completed_tasks_count": 0,
    "pending_tasks_count": 1,
    "subtasks_count": 2,
    "completed_pomodoro_sessions": 4,
    "total_focus_minutes": 100
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
      "user_profile": {
        "name": "Mahasiswa Juara",
        "campus": "Universitas Indonesia",
        "studyProgram": "Teknik Informatika",
        "semester": 5
      },
      "is_dark_mode": true,
      "completed_pomodoro_sessions": 4,
      "has_seeded_v1": true
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
      "timeRange": "08:00 - 10:30"
    }
  ],
  "tasks": [
    {
      "id": "uuid-task-1",
      "title": "Implementasi Red-Black Tree",
      "description": "Kerjakan dalam bahasa Dart beserta unit test",
      "subjectId": "uuid-subject-1",
      "dueDate": "2026-11-12T23:59:00.000",
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
      "createdAt": "2026-11-09T10:00:00.000"
    }
  ]
}
```

### 3.3 Alur Kerja Ekspor & Impor Reaktif
* **Alur Ekspor (`Ekspor JSON`)**:
  1. Mengambil seluruh state terbaru dari `_subjectsBox`, `_tasksBox`, dan `_settingsBox`.
  2. Mengonversi seluruh data menjadi JSON terformat rapi (*pretty-printed* 2 spasi) dan menyalinnya otomatis ke *Clipboard*.
  3. Menampilkan dialog ringkasan data beserta pratinjau JSON yang dapat diseleksi dan disalin ulang.
* **Alur Impor (`Impor JSON`)**:
  1. Menyediakan tombol cepat **Tempel dari Clipboard** (*1-Click Paste*) maupun input teks manual.
  2. Memvalidasi struktur JSON (mendukung penuh skema `v2` sekaligus *backward-compatible* dengan skema `v1`).
  3. Menyimpan ulang seluruh `subjects`, `tasks` (beserta `subtasks`, `attachments`, `notes`), `user_profile`, dan `settings` (`is_dark_mode`, `completed_pomodoro_sessions`, `raw_settings`) ke Hive.
  4. Memicu pembaruan state reaktif seketika pada `TaskProvider.loadTasks()`, `SubjectProvider.loadSubjects()`, dan `SettingsProvider.reloadSettings()` sehingga seluruh tampilan (termasuk tema gelap/terang, form profil, daftar tugas, SKS, dan sesi fokus) langsung ter-update tanpa perlu me-restart aplikasi.

