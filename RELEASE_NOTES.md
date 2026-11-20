# TaskApp v2.5.1 — Mode Kalender Bulanan Penuh (Monthly Calendar Grid View)

> **TaskApp v2.5.1** menghadirkan fitur **Mode Kalender Bulanan Penuh (*Monthly Grid View*)** pada layar **Kalender & Jadwal** untuk memudahkan perencanaan akademik jangka menengah, memantau sebaran deadline tugas dalam 1 bulan penuh, serta melihat hari kuliah aktif secara sekilas.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** (`taskapp-release.jks`), sehingga Anda dapat **langsung mengunduh berkas APK dan menekan "Update" tanpa perlu mencopot aplikasi sebelumnya. Seluruh data perkuliahan, tugas, lampiran, presensi, dan buku kas FinTrack Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.5.1 (Changelog)

### 1. 🗓️ Mode Tampilan Kalender Bulanan Penuh (`MonthlyCalendarGrid`)
- **Sakelar Toggle Instan (`Strip` | `Bulanan`)**:
  - Beralih mulus dengan transisi animasi halus (`AnimatedSize`) antara pita tanggal horizontal 45 hari dan tampilan matriks kalender 1 bulan penuh berbasis awal pekan Senin (`SEN`–`MIN`).
  - Pilihan mode tampilan Anda otomatis disimpan secara lokal di Hive (`StorageService`) agar tetap konsisten saat aplikasi dibuka kembali.
- **Navigasi Bulan Semesteran & Gestur Swipe**:
  - Pindah antarbulan dengan tombol panah **`<`** / **`>`** atau cukup usap (*horizontal swipe*) pada area kisi kalender bulanan.
  - Tombol **"Hari Ini"** langsung mengembalikan fokus bulan dan tanggal terpilih ke hari berjalan.
  - Penyesuaian jangkar (*anchor*) otomatis pada pita tanggal `Strip` jika Anda memilih tanggal yang berada di luar rentang bawaan lalu beralih kembali ke mode `Strip`.

### 2. 🎯 Penanda Visual Deadline Tugas, Jadwal Kuliah & Beban Bulanan
- **Titik Warna Semantik Deadline Tugas**:
  - Menampilkan hingga **3 titik warna** pada setiap tanggal berdasarkan prioritas dan status penyelesaian:
    - **Merah (`Mendesak`)**: Tugas terlambat (*overdue*) atau prioritas tinggi yang belum selesai.
    - **Amber**: Tugas prioritas sedang yang belum selesai.
    - **Kobalt / Aksen**: Tugas prioritas rendah yang belum selesai.
    - **Hijau (`Selesai`)**: Tugas yang telah diselesaikan.
- **Penanda Hari Kuliah Aktif**:
  - Menampilkan hingga **2 batang indikator warna** mata kuliah aktif pada hari perkuliahan sesuai jadwal mingguan Anda.
- **Legenda Ringkas & Penghitung Tugas Bulanan**:
  - Dilengkapi legenda warna (`Mendesak`, `Tugas`, `Selesai`, `Kuliah`) serta ringkasan jumlah tugas pada bulan yang sedang dipantau (`<N> tugas bulan ini`).

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.5.1.apk`** dari daftar **Assets** di bawah.
2. Buka berkas APK di ponsel Android Anda dan pilih tombol **"Update"**.
3. Aplikasi akan langsung terbarukan ke **v2.5.1**. Seluruh data tugas, lampiran berkas, catatan akademik, dan keuangan Anda tetap utuh 100%.
