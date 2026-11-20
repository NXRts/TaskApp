# TaskApp v2.5.0 — Lampiran Berkas & Foto Tugas Lokal (Offline Camera & PDF Attachments)

> **TaskApp v2.5.0** menghadirkan fitur **Lampiran Berkas & Foto Tugas Lokal** yang bekerja **100% offline-first**: ambil foto catatan papan tulis langsung dari kamera, pilih beberapa foto dari galeri, atau lampirkan dokumen PDF soal tugas serta membukanya langsung di dalam aplikasi tanpa bergantung koneksi internet.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** (`taskapp-release.jks`), sehingga Anda dapat **langsung mengunduh berkas APK dan menekan "Update" tanpa perlu mencopot aplikasi sebelumnya. Seluruh data perkuliahan, tugas, presensi, dan buku kas FinTrack Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.5.0 (Changelog)

### 1. 📎 Lampiran Kamera, Galeri & PDF Soal Offline
- **Ambil Foto Langsung dari Kamera**:
  - Foto catatan papan tulis atau penjelasan dosen langsung dari modal tambah/edit tugas maupun modal detail tugas.
  - Berkas foto disalin aman ke direktori privat internal aplikasi (`task_attachments`) agar tetap tersedia secara offline.
- **Pilih Multi-Foto dari Galeri**:
  - Mendukung pemilihan satu atau beberapa gambar sekaligus dari galeri perangkat untuk lampiran kisi-kisi atau materi kuliah.
- **Lampirkan Dokumen PDF Tugas / Soal**:
  - Pilih berkas `.pdf` lembar soal, modul praktikum, atau panduan tugas langsung dari penyimpanan perangkat.
- **Dukungan Tautan URL Tetap Tersedia**:
  - Tetap dapat menempelkan tautan eksternal seperti Google Drive, LMS/Spada, atau link Zoom berdampingan dengan berkas lokal.

### 2. 🖼️ Penampil Gambar & Pembaca PDF Tersemat
- **Penampil Gambar Internal (`AttachmentImageViewerScreen`)**:
  - Mendukung gesture *pinch-to-zoom* (skala `0.5x` s/d `5.0x`), *double-tap* untuk zoom 2.5x / reset, *pan*, tombol **Reset Skala**, dan tombol **Bagikan Foto**.
- **Pembaca PDF Tersemat (`AttachmentPdfViewerScreen`)**:
  - Membaca dokumen PDF soal/materi langsung di dalam aplikasi via `PdfPreview` lengkap dengan pratinjau halaman, cetak langsung, dan tombol **Bagikan Berkas PDF**.
- **Integrasi Menyeluruh di Kartu & Modal Tugas**:
  - Tombol cepat `[ Kamera ]`, `[ Galeri ]`, dan `[ PDF Soal ]` pada modal Tambah/Edit Tugas, daftar lampiran lengkap di Detail Tugas (dengan aksi tambah, buka, bagikan, dan hapus), serta indikator jumlah lampiran di Kartu Tugas beranda.
  - Berkas lampiran lokal otomatis dibersihkan dari penyimpanan aplikasi saat lampiran atau tugas dihapus.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.5.0.apk`** dari daftar **Assets** di bawah.
2. Buka berkas APK di ponsel Android Anda dan pilih tombol **"Update"**.
3. Aplikasi akan langsung terbarukan ke **v2.5.0**. Seluruh data tugas, catatan akademik, dan keuangan Anda tetap utuh 100%.
