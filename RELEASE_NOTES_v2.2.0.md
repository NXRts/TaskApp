# TaskApp v2.2.0 — Campus Companion: Attendance Sentinel & Visual Weekly Timetable Matrix

> **TaskApp v2.2.0 "Campus Companion"** membawa transformasi besar dalam pengalaman akademik mahasiswa. Memperkenalkan dua pilar fitur utama: **Attendance Sentinel** (monitor presensi kuliah 16 pertemuan & kuota bolos 75%) dan **Visual Weekly Timetable Matrix** (jadwal kuliah mingguan bentuk matriks 06.00–16.00 dengan deteksi jeda waktu kosong/free study window).

---

## ✨ Apa yang Baru di Versi 2.2.0 (Changelog)

### 🛡️ 1. Monitor Presensi Kuliah & Kuota Bolos 75% (Attendance Sentinel)
* **Kalkulasi Batas Aman 75% Otomatis**:
  * Menghitung sisa kuota izin/alfa per semester (default batas maksimal 4x absen dari 16 pertemuan) agar mahasiswa terhindar dari pencekalan Ujian Akhir Semester (UAS).
  * Preset jumlah pertemuan fleksibel (dapat diatur 12, 14, 16, 18, hingga 20 pertemuan).
* **Matriks Visual 16 Pertemuan (P1 - P16) Interaktif**:
  * 🟢 **Hadir (`P1 (H)`)**: Tombol berubah warna hijau saat mahasiswa menghadiri perkuliahan.
  * 🔵 **Sakit (`P1 (S)`)**: Tombol berubah biru untuk pencatatan izin sakit.
  * 🟡 **Izin (`P1 (I)`)**: Tombol berubah kuning saat izin keperluan mendesak atau delegasi lomba.
  * 🔴 **Alfa (`P1 (A)`)**: Tombol berubah merah saat tidak hadir tanpa keterangan.
  * ⚪ **Belum Terlaksana**: Tampilan netral untuk pertemuan mendatang yang dapat di-reset kapan saja.
* **Tingkat Status Sentinel Dinamis**:
  * 🟢 **Aman**: 0–1 kali alfa/izin (tingkat kehadiran tinggi).
  * 🟡 **Waspada**: 2–3 kali alfa/izin (*"Sisa kuota izin Anda tinggal 1 kali"*).
  * 🔴 **Kritis**: $\ge 4$ kali alfa (*"Batas 75% terlampaui! Anda berisiko dilarang ikut UAS"*).
* **Riwayat Catatan Presensi Terintegrasi**: Log kronologis tanggal berformat Indonesia, tipe ketidakhadiran, serta catatan materi atau alasan.
* **Chip Indikator Langsung**: Setiap kartu mata kuliah menampilkan status presensi secara instan (`🟢 100% Hadir`, `🟡 2x Absen`, atau `🔴 4x Absen`).

---

### 🗓️ 2. Jadwal Kuliah Mingguan Bentuk Matriks Visual (Timetable Visual Matrix)
* **Grid Visual Jam 6 Pagi s/d Jam 4 Sore (`06:00` – `16:00`)**:
  * Menampilkan jadwal perkuliahan dalam bentuk tabel matriks mingguan (Senin s/d Sabtu, otomatis adaptif bila ada kuliah hari Minggu).
  * Kolom penunjuk waktu *sticky* di sebelah kiri tersinkronisasi sempurna dengan pengguliran (*scroll*) vertikal dan horizontal.
  * Dilengkapi **Auto-scroll Pintar**: Saat dibuka di siang hari, layar otomatis bergeser lembut ke jam perkuliahan yang sedang aktif.
* **Blok Warna Mata Kuliah Informatif**:
  * Kotak jadwal berwarna sesuai tema mata kuliah, menampilkan nama mata kuliah, kode/SKS, ruangan kelas (`Icons.meeting_room_outlined`), dan jam kuliah.
  * 1-Klik pada blok langsung membuka halaman detail mata kuliah.
* **Deteksi Cerdas Slot Jeda Kosong (*Free Study Window*)**:
  * Otomatis mengidentifikasi waktu luang di antara dua kelas kuliah pada hari yang sama (misal: jeda jam 10.30–13.20 $\rightarrow$ `☕ Jeda 2j 50m`).
  * Desain elegan, bersih, dan tidak mendominasi layar.
  * Mengetuk jeda kosong memunculkan lembar rekomendasi produktivitas dengan tombol cepat **Mulai Fokus Pomodoro** atau **Buat Tugas Baru**.
* **Garis Waktu Berjalan Real-time (*Live Current Time Indicator*)**:
  * Penunjuk waktu langsung berwarna merah (*live red dot & line*) pada kolom hari ini untuk melihat posisi jam sekarang secara seketika.
* **Filter Cepat Per Hari**: Tab chip `[Semua (Grid)]`, `[Senin]`, `[Selasa]`, `[Rabu]`, `[Kamis]`, `[Jumat]`, `[Sabtu]` dengan label penanda `(Hari ini)`.
* **Notifikasi Jadwal Belum Lengkap**: Menampilkan banner pengingat ramah untuk mata kuliah yang belum diisi jadwal hari/jamnya dengan 1-klik pengaturan.

---

### 🎨 3. Peningkatan Antarmuka & Navigasi (UI/UX)
* **Tab Navigasi Fleksibel di Layar Mata Kuliah**: Tombol beralih instan antara mode **Daftar Mata Kuliah** dan **Matriks Jadwal Mingguan**.
* **Perbaikan Tampilan Waktu (*Clipping Fix*)**: Menghilangkan masalah teks jam yang terpotong di bagian atas dan bawah layar.
* **Editorial Minimalist Aesthetic**: Tetap setia pada palet Obsidian Gelap `#0E0F12` dan aksen kobalt `#3B82F6` yang matang dan bebas distraksi.

---

## 📥 Panduan Instalasi (Android APK)

1. Unduh berkas **`TaskApp-v2.2.0.apk`** atau **`app-release.apk`** dari daftar **Assets** di bawah.
2. Buka berkas APK yang telah diunduh di perangkat Android Anda.
3. Jika muncul permintaan izin penginstalan dari sumber tidak dikenal, pilih **Izinkan (Allow)**.
4. Tekan **Pasang (Install)** atau **Perbarui (Update)**.
5. Selesai! Semua data tugas, mata kuliah, presensi, catatan, dan pengaturan Anda akan tetap tersimpan aman (100% Offline & No Data Loss).

---

## 📱 Spesifikasi Sistem
* **Sistem Operasi**: Android 6.0 (Marshmallow, API 23) ke atas
* **Arsitektur**: `arm64-v8a`, `armeabi-v7a`, `x86_64`
* **Kebutuhan Jaringan**: 100% Offline (Bekerja penuh tanpa koneksi internet)
* **Ukuran File**: ~21 MB

---

**Full Changelog**: https://github.com/NXRts/TaskApp/compare/v2.0.6...v2.2.0
