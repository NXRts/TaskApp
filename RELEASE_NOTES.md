# TaskApp v2.2.1 — Calendar Daily Timetable Hours (24h & 12h AM/PM)

> **TaskApp v2.2.1** memperluas fungsionalitas manajemen waktu mahasiswa dengan menghadirkan **Garis Waktu Harian Per Jam (Daily Timetable Hours)** di menu *Kalender & Jadwal*, dilengkapi opsi format waktu **24 Jam** dan **12 Jam (AM/PM)**. Tampilan tetap rapi, bersih, dan interaktif meskipun belum ada agenda atau jadwal kuliah pada hari yang dipilih.

---

## ✨ Apa yang Baru di Versi 2.2.1 (Changelog)

### ⏱️ 1. Garis Waktu Harian Per Jam di Menu Kalender (Daily Timetable Hours)
* **Visualisasi 24 Jam Penuh (`00:00` s/d `24:00` / `12 AM` s/d `12 AM`)**:
  * Menampilkan garis waktu vertikal harian per jam yang terstruktur rapi untuk setiap tanggal yang dipilih.
  * **Tetap Tampil Bersih Walau Kosong (*Empty State Ready*)**: Meskipun tidak ada jadwal kuliah atau tugas pada hari tertentu, baris jam 24 jam tetap ditampilkan rapi sehingga mahasiswa dapat melihat gambaran blok waktu harian mereka dengan jelas.
  * **Jadwalkan Tugas Instan dari Slot Jam**: Mengetuk baris jam kosong mana pun langsung membuka modal tambah tugas dengan tanggal dan jam tenggat yang sudah terisi otomatis sesuai jam yang diketuk.
* **Integrasi Kuliah & Tenggat Tugas**:
  * **Blok Perkuliahan Hari Ini**: Menampilkan mata kuliah yang terjadwal pada hari tersebut dengan blok berwarna sesuai tema matkul, nama ruangan kelas, jumlah SKS, dan rentang jam kuliah. Mengetuk blok kuliah langsung membuka layar detail mata kuliah.
  * **Kartu Tugas Terjadwal**: Tugas dengan tenggat pada hari tersebut otomatis diposisikan pada baris jam tenggatnya, lengkap dengan checkbox centang selesai instan, indikator prioritas, dan teks coret saat tugas selesai. Mengetuk tugas membuka detail modal tugas.
  * **Penataan Berdampingan Bebas Tumpuk (*Smart Column Layout*)**: Jika jadwal kuliah dan tenggat tugas berada pada jam yang sama, sistem otomatis membagi kolom secara berdampingan sehingga keduanya tetap terbaca jelas tanpa saling menutupi.
* **Garis Waktu Real-Time (*Live Current Time Indicator*)**:
  * Garis horizontal dan titik merah aktif yang menunjukkan posisi jam dan menit sekarang secara *real-time* saat tanggal yang dibuka adalah hari ini.
* **Auto-Scroll Pintar**:
  * Saat membuka kalender hari ini, layar otomatis bergeser lembut ke jam saat ini.
  * Saat membuka tanggal lain, layar bergeser ke jam 07.00 pagi agar jadwal perkuliahan pagi langsung terlihat tanpa perlu menggulir manual dari tengah malam.

---

### 🌐 2. Pilihan Format Waktu 24 Jam & 12 Jam (AM/PM)
* **Tombol Beralih Format Waktu Instan**:
  * Tombol interaktif di header agenda kalender dengan ikon jam `24 Jam` $\leftrightarrow$ `12 Jam (AM/PM)`.
  * **Mode 24 Jam**: Label jam ditampilkan dalam format `00:00`, `01:00`, ..., `12:00`, `13:00`, ..., `24:00`.
  * **Mode 12 Jam AM/PM**: Label jam ditampilkan dalam format `12 AM`, `1 AM`, ..., `11 AM`, `12 PM`, `1 PM`, ..., `11 PM`. Rentang jam kuliah dan waktu tugas juga otomatis menyesuaikan (contoh: `8:00 AM - 9:40 AM`, `1:30 PM`).
* **Penyimpanan Preferensi Lokal (Offline Persistence)**:
  * Pilihan format waktu pengguna tersimpan secara permanen di database lokal Hive, sehingga pilihan format waktu tetap aktif saat aplikasi dibuka kembali.

---

### 🎛️ 3. Pengalih Tampilan (View Mode Switcher)
* **Dua Mode Tampilan di Layar Kalender**:
  * ⏱️ **Garis Waktu (Timeline)**: Tampilan visual per jam yang komprehensif menggabungkan jadwal kuliah dan tugas harian.
  * 📋 **Daftar (List)**: Tampilan daftar kartu tugas klasik dengan ringkasan status tenggat dan tombol jadwalkan tugas baru.
* **Indikator Jumlah Cepat**:
  * Badge ringkas di header menampilkan jumlah kuliah dan jumlah tugas pada tanggal yang dipilih.

---

### 🛠️ 4. Peningkatan Sistem & Stabilitas CI/CD
* **Upgrade Gradle & Validasi Flutter Build**:
  * Memperbarui Gradle Wrapper ke versi **9.3.1** yang kompatibel penuh dengan Flutter Gradle Plugin terbaru.
  * Menambahkan parameter `--android-skip-build-dependency-validation` pada alur GitHub Actions untuk memastikan build APK release selalu berjalan tanpa hambatan.

---

## 📥 Panduan Unduh & Instalasi (Android APK)

1. Unduh berkas **`TaskApp-v2.2.1.apk`** atau **`app-release.apk`** dari daftar **Assets** di bawah.
2. Buka berkas APK yang telah diunduh di perangkat Android Anda.
3. Jika muncul permintaan izin penginstalan dari sumber tidak dikenal, pilih **Izinkan (Allow)**.
4. Tekan **Pasang (Install)** atau **Perbarui (Update)**.
5. Selesai! Semua data tugas, mata kuliah, presensi, catatan, dan preferensi Anda tetap tersimpan utuh dan aman (100% Offline & Tanpa Ketergantungan Cloud).
