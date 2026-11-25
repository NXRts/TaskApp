# TaskApp v2.9.0 — Smart Daily Campus Briefing & Gapless Native Multi-Track Ambient Audio Engine

> **TaskApp v2.9.0** menghadirkan fitur **Kartu Briefing Kampus Harian & Hitung Mundur Kelas Berikutnya (*Smart Daily Campus Briefing*)** langsung di Beranda, serta meningkatkan mesin audio **Ambient Sounds** di ponsel Android dengan **Dedicated Native Kotlin `AudioTrack` PCM Mixer Thread** dan **2.5-Second Dual-Head Circular Crossfade** sehingga ke-9 suara alam dapat berbunyi secara simultan dengan perpindahan *loop* yang 100% mulus tanpa jeda.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** (`taskapp-release.jks`), sehingga Anda dapat **langsung mengunduh berkas APK dan menekan "Update" tanpa perlu mencopot aplikasi sebelumnya. Seluruh data perkuliahan, tugas, lampiran, presensi, setelan Ambient Sounds, statistik belajar, dan buku kas FinTrack Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.9.0 (Changelog)

### 1. 🌅 Kartu Briefing Kampus Harian & Hitung Mundur Kelas Terdekat (`SummaryCard` & `DailyCampusBriefingHelper`)

- **Hitung Mundur & Status Perkuliahan Real-Time di Beranda**:
  - Memaksimalkan `SummaryCard` di Beranda untuk mengevaluasi jadwal kuliah hari ini terhadap waktu saat ini secara otomatis:
    - 🟢 **Sedang Berlangsung (`sisa X mnt`)**: Menampilkan sisa waktu kuliah yang sedang berjalan beserta ruangan dan dosen pengampu.
    - 🟡 **Mulai dalam `X mnt / jam`**: Menampilkan hitung mundur menuju kelas terdekat hari ini.
    - 🟠 **Kuliah Selesai • Belum Isi Presensi** (atau **Presensi Tercatat**): Mengingatkan pengisian presensi setelah jam kuliah hari ini berakhir.
    - 🔵 **Jadwal Berikutnya**: Menampilkan jadwal kuliah hari terdekat berikutnya jika hari ini bebas perkuliahan.
  - Menampilkan badge **`N Kuliah Hari Ini`** berdampingan dengan **`X SKS Aktif`**.
- **Sorotan Tugas Prioritas & Tombol Pintasan 1-Ketuk**:
  - Menampilkan baris **`Fokus Prioritas`** untuk tugas aktif dengan tenggat paling dekat.
  - **`[ ✓ Isi Presensi (P-n) ]`**: Membuka dialog pencatatan presensi `RecordAbsenceDialog` langsung dari Beranda dengan nomor pertemuan berikutnya (`P1..P16`) yang otomatis terpilih.
  - **`[ 🎯 Fokus Tugas Ini ]`**: Langsung berpindah ke tab **Fokus Belajar (Pomodoro)** dengan tugas prioritas tersebut otomatis terpilih sebagai target fokus.

### 2. 🎧 Mesin Audio Native Multi-Track Android & Gapless Circular Crossfade (`MainActivity.kt` & `AmbientSoundService`)

- **Pemutaran Simultan 9 Suara di HP Android Tanpa Konflik *AudioFocus***:
  - Menggantikan pemutar multi-instance `MediaPlayer` dengan **Dedicated Native Kotlin `AudioTrack` (`MODE_STREAM`) Mixer Thread (`TaskAppAmbientMixerThread`)** berprioritas tinggi (`Thread.MAX_PRIORITY`).
  - Seluruh 9 suara alam dicampur secara *real-time* pada tingkat sampel 16-bit PCM (`16000 Hz`) ke dalam satu saluran output perangkat keras, sehingga menekan **`Play All`** atau menyalakan beberapa suara sekaligus di HP Android memutar seluruh suara secara bersamaan dengan kontrol volume individual dan *Master Volume* yang responsif.
- **Perpindahan *Infinite Loop* Mulus Tanpa Terputus (*2.5s Dual-Head Equal-Power Circular Crossfade*)**:
  - Saat *cursor* audio memasuki 2.5 detik terakhir sebelum ujung berkas, mesin memadukan ekor audio dan awal audio secara simultan menggunakan kurva daya konstan ($\cos/\sin$), menghasilkan perputaran tanpa hentakan, tanpa klik, dan tanpa jeda sedikit pun.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.9.0.apk`** dari daftar **Assets** di bawah.
2. Buka berkas APK di ponsel Android Anda dan pilih tombol **"Update"**.
3. Aplikasi akan langsung terbarukan ke **v2.9.0**. Seluruh data tugas, lampiran berkas, catatan akademik, statistik belajar, dan keuangan Anda tetap utuh 100%.
