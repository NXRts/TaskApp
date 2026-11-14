# TaskApp v2.3.0 — Visual Schedule Exporter: Shareable Wallpaper (9:16 PNG) & Study Summary Document (PDF A4)

> **TaskApp v2.3.0** menghadirkan fitur **Visual Schedule Exporter** yang memungkinkan mahasiswa mengekspor jadwal perkuliahan dan tugas dalam dua format visual siap pakai: **Wallpaper HP (9:16 PNG)** bertema Obsidian Gelap untuk lockscreen/homescreen ponsel, serta **Dokumen Ringkasan Studi (PDF A4)** siap cetak lengkap dengan checklist tugas mingguan. Seluruh proses pembuatan gambar dan dokumen berjalan 100% secara lokal (*offline-first*) tanpa ketergantungan server.

---

## ✨ Apa yang Baru di Versi 2.3.0 (Changelog)

### 📱 1. Generator Wallpaper HP (9:16 PNG Resolusi Tinggi)
* **Format Rasio 9:16 Khusus Layar Ponsel**:
  * Dirancang presisi agar pas sebagai wallpaper lockscreen atau homescreen ponsel pintar mahasiswa.
  * Menghasilkan gambar beresolusi tinggi (*crystal-clear HD*) secara instan menggunakan Flutter `RepaintBoundary`.
* **Desain Obsidian Gelap Elegan & Anti-Distraksi**:
  * Menggunakan palet obsidian gelap (`#0C0D12` – `#0A0B10`) dengan aksen kobalt dan kontras tipografi berimbang (*anti-AI slop*).
  * **Safe Area Lockscreen Clock**: Bagian atas sengaja diberi ruang bernapas (*breathing space*) proporsional agar widget jam dan persentase baterai sistem ponsel tidak menutupi daftar jadwal kuliah.
* **Informasi Akademik Lengkap & Rapi**:
  * Menampilkan identitas mahasiswa, program studi, kampus, semester, serta akumulasi total SKS dan jumlah mata kuliah.
  * Pengelompokan jadwal per hari (Senin s/d Minggu) dengan penanda warna matkul, ruangan kelas (`📍 Ruangan`), jam kuliah, dan SKS.
  * **Opsi Fleksibel**: Pilihan sakelar untuk menampilkan atau menyembunyikan nama dosen pengampu pada wallpaper.
* **Aksi Seketika**:
  * **Simpan PNG**: Menyimpan berkas gambar resolusi tinggi langsung ke penyimpanan perangkat.
  * **Bagikan Wallpaper**: Membuka share sheet native Android/iOS untuk langsung dibagikan ke WhatsApp, Telegram, Instagram Stories, atau Google Drive.

---

### 📄 2. Dokumen Ringkasan Studi & Jadwal Kuliah (PDF Standar Kertas A4)
* **Layout Cetak Profesional & Resmi**:
  * Diformat presisi untuk ukuran kertas **A4** (standar cetak printer dokumen perkuliahan).
  * Dihasilkan menggunakan engine `pdf` & `printing` murni tanpa perlu koneksi internet (*zero-latency & 100% offline*).
* **Komponen Dokumen Komprehensif**:
  * **Header Resmi**: Nama lengkap mahasiswa, program studi, kampus, semester aktif, dan tanggal cetak berformat Indonesia.
  * **Kartu Ringkasan Beban Akademik**: Metrik utama Total SKS, Jumlah Mata Kuliah Terdaftar, Tugas Aktif Menanti Penyelesaian, dan Status Akademik.
  * **Tabel Jadwal Perkuliahan Mingguan**: Disusun kronologis menurut hari dan jam kuliah (Kolom: Hari, Waktu, Mata Kuliah, SKS, Ruangan Kelas, dan Dosen Pengampu).
  * **Lembar Checklist Tugas & Proyek**: Kotak centang kosong manual (`[  ]`) yang siap dicentang menggunakan pulpen atau pensil saat dicetak fisik, memuat nama tugas, matkul terkait, tenggat waktu, dan tingkat prioritas.
  * **Kolom Catatan Mandiri**: Kotak bergaris di bagian bawah untuk mencatat arahan dosen, target nilai, atau catatan akademik penting.
* **Fitur Pratinjau & Cetak Modern**:
  * **Pratinjau Interaktif**: Layar pratinjau PDF responsif dengan fitur *pinch-to-zoom* dan navigasi halaman.
  * **Cetak Langsung (Native Print)**: Terhubung langsung ke dialog cetak sistem operasi (printer nirkabel/Wi-Fi/USB).
  * **Bagikan Berkas PDF**: Membagikan dokumen PDF langsung ke grup kelas atau dosen via aplikasi berbagi.

---

### 🚀 3. Akses Terpadu di Berbagai Sudut Aplikasi
* **Layar Mata Kuliah**: Tombol ekspor visual baru berikon bagikan (`Icons.share_outlined`) langsung di sebelah tombol beralih tampilan matriks.
* **Layar Kalender & Jadwal**: Pintasan ekspor cepat di AppBar kalender harian.
* **Layar Pengaturan Profil**: Kartu khusus *Ekspor Visual & Dokumen Cetak* untuk kemudahan akses sewaktu-waktu.

---

## 📥 Panduan Unduh & Instalasi (Android APK)

1. Unduh berkas **`TaskApp-v2.3.0.apk`** atau **`app-release.apk`** dari daftar **Assets** di bawah.
2. Buka berkas APK yang telah diunduh di perangkat Android Anda.
3. Jika muncul permintaan izin penginstalan dari sumber tidak dikenal, pilih **Izinkan (Allow)**.
4. Tekan **Pasang (Install)** atau **Perbarui (Update)**.
5. Selesai! Seluruh data tugas, mata kuliah, presensi, catatan, dan preferensi Anda tetap tersimpan utuh dan aman (100% Offline & Kedaulatan Data Terjamin).
