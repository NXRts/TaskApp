# TaskApp v2.8.0 — Statistik & Heatmap Belajar Akademik (Pomodoro Academic Analytics)

> **TaskApp v2.8.0** menghadirkan fitur **Statistik & Heatmap Belajar Akademik (*Pomodoro Academic Analytics*)** pada tab **`Statistik`** di menu **Fokus Belajar**: memungkinkan mahasiswa mengevaluasi konsistensi belajar harian, *streak* hari beruntun, grafik batang menit fokus Senin–Minggu, *heatmap* 4 minggu (28 hari), serta *breakdown* alokasi jam belajar per mata kuliah secara privat **100% offline**.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** (`taskapp-release.jks`), sehingga Anda dapat **langsung mengunduh berkas APK dan menekan "Update" tanpa perlu mencopot aplikasi sebelumnya. Seluruh data perkuliahan, tugas, lampiran, presensi, setelan Ambient Sounds, statistik belajar, dan buku kas FinTrack Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.8.0 (Changelog)

### 1. 📊 Tab `Statistik` & Pencatatan Sesi Fokus Kontekstual (`PomodoroSessionRecord`)

- **Navigasi 3 Tab Ringkas di Menu Fokus (`Pomodoro` | `Ambient` | `Statistik`)**:
  - Menambahkan tab **`Statistik`** khusus di samping tab **`Pomodoro`** dan **`Ambient`** dengan tata letak proporsional bebas terpotong di layar ponsel.
- **Pencatatan Riwayat Sesi Fokus Kontekstual 100% Offline**:
  - Setiap sesi fokus 25 menit yang selesai kini mencatat riwayat lengkap (`completedAt`, `durationMinutes`, `taskId`, `taskTitle`, dan `subjectId` mata kuliah terkait) ke dalam penyimpanan Hive lokal dan otomatis disertakan dalam *Full-State JSON Backup & Restore*.

### 2. 🔥 Penghitung Streak Belajar & Grafik Batang Harian (`PomodoroAnalyticsView`)

- **Kartu Streak Belajar & Total Jam Fokus**:
  - Menampilkan jumlah hari belajar fokus berturut-turut (*Current Streak*) beserta rekor terbaik (*Longest Streak*).
  - Menampilkan total akumulasi jam & menit fokus keseluruhan beserta jumlah sesi dan ringkasan waktu fokus minggu ini.
- **Grafik Batang Menit Fokus Harian (Senin–Minggu)**:
  - Visualisasi batang vertikal proporsional untuk menit fokus setiap hari dari `Sen` hingga `Min` pada minggu berjalan, dengan penanda warna hijau (`AppTheme.successSage`) untuk hari ini.

### 3. 🟩 Heatmap Konsistensi 4 Minggu & Breakdown Jam Belajar per Mata Kuliah (`PomodoroAnalyticsHelper`)

- **Heatmap Konsistensi Belajar (4 Minggu / 28 Hari)**:
  - Matriks kalender 4 baris minggu × 7 hari (Senin–Minggu) dengan 5 tingkatan intensitas warna (`0m`, `1–25m`, `26–50m`, `51–100m`, `100m+`), indikator jumlah hari aktif (`X/28 hari aktif`), serta *tooltip* detail tanggal dan menit belajar.
- **Alokasi Jam Belajar per Mata Kuliah**:
  - Mengelompokkan dan mengurutkan total durasi belajar, jumlah sesi, serta persentase porsi waktu belajar untuk setiap mata kuliah (dan kategori *Fokus Umum & Mandiri*), dilengkapi *progress bar* berwarna sesuai warna mata kuliah masing-masing.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.8.0.apk`** dari daftar **Assets** di bawah.
2. Buka berkas APK di ponsel Android Anda dan pilih tombol **"Update"**.
3. Aplikasi akan langsung terbarukan ke **v2.8.0**. Seluruh data tugas, lampiran berkas, catatan akademik, statistik belajar, dan keuangan Anda tetap utuh 100%.
