# TaskApp v2.5.2 — Perapian Navigasi FinTrack, Garis Waktu Kalender & Kartu Dukungan Pengembang

> **TaskApp v2.5.2** menghadirkan penyempurnaan UX dan perbaikan penting pada navigasi kartu **Safe-to-Spend** beranda menuju halaman **Keuangan**, perapian tata letak garis waktu **Kalender & Jadwal** (`00:00–24:00`), serta penambahan fitur **Dukung Pengembang (Support Me)** di layar Profil & Pengaturan.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** (`taskapp-release.jks`), sehingga Anda dapat **langsung mengunduh berkas APK dan menekan "Update" tanpa perlu mencopot aplikasi sebelumnya. Seluruh data perkuliahan, tugas, lampiran, presensi, dan buku kas FinTrack Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.5.2 (Changelog)

### 1. 🧭 Perbaikan Navigasi Kartu Keuangan Beranda (`FinanceHomeCard` & `MainScreen`)
- **Bilah Navigasi Bawah & FAB Tetap Aktif**:
  - Mengetuk kartu **Safe-to-Spend Hari Ini** di halaman awal kini langsung memindahkan tab aktif ke tab **Keuangan** melalui `MainScreen.switchTab`, sehingga bilah navigasi bawah (*Tugas, Matkul, Kalender, Keuangan, Fokus*) dan tombol `+` tetap tampil dan dapat digunakan untuk berpindah halaman.
- **Pengaman Mode Standalone (`FinanceScreen`)**:
  - Jika `FinanceScreen` dibuka di luar `MainScreen`, halaman otomatis menampilkan tombol **Kembali** pada header serta tombol `+` lokal, dengan proteksi teks header agar tetap bebas *overflow*.

### 2. 🗓️ Perapian Garis Waktu Kalender & Jadwal (`CalendarScreen`)
- **Tugas Larut Malam (`23:59`) Tetap Rapi di Blok `23:00–24:00`**:
  - Posisi kartu tugas diklem ke rentang `00:00–24:00` sehingga tugas berbatas waktu `23:59` tidak lagi meluber melewati garis batas `24:00` atau terpotong bilah navigasi bawah.
- **Penyelarasan Label Jam `00:00`–`24:00` & Ruang Gulir Bawah**:
  - Seluruh label jam `00:00` s/d `24:00` disejajarkan tepat pada garis horizontal masing-masing dengan jarak seragam, ruang gulir bawah ditambah agar aman dari tombol `+`, dan FAB duplikat pada `CalendarScreen` dibersihkan.

### 3. 💖 Kartu Dukungan Pengembang (`SupportCreatorCard`)
- **Dukung Pengembangan TaskApp di Profil & Pengaturan**:
  - Menyediakan akses cepat ke platform dukungan **Saweria** (`saweria.co/yusufarrofi`), **Ko-fi** (`ko-fi.com/yusufarrofi/`), dan **Yapp.ink** (`yapp.ink/yusufarrofi21`).
  - Mendukung pembukaan tautan langsung di browser (`ExternalLinkHelper` & handler `openExternalUrl` Android) maupun tombol 1-ketuk **Salin tautan** ke clipboard.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.5.2.apk`** dari daftar **Assets** di bawah.
2. Buka berkas APK di ponsel Android Anda dan pilih tombol **"Update"**.
3. Aplikasi akan langsung terbarukan ke **v2.5.2**. Seluruh data tugas, lampiran berkas, catatan akademik, dan keuangan Anda tetap utuh 100%.
