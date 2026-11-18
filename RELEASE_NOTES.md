# TaskApp v2.4.3 — Perbaikan Tata Letak Profil & Pembersihan Repositori (Mobile Profile Polish)

> **TaskApp v2.4.3** menghadirkan penyempurnaan antarmuka pada layar **Profil & Pengaturan**: menuntaskan masalah *overflow* pada tombol uji coba alarm notifikasi dengan tata letak chip responsif, merapikan tombol panduan optimasi baterai, serta membersihkan repositori dari berkas rilis dan artefak APK lama.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** (`taskapp-release.jks`), sehingga Anda dapat **langsung mengunduh berkas APK dan menekan "Update" tanpa perlu mencopot aplikasi lama. Seluruh data tugas, presensi, jadwal, dan buku kas FinTrack Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.4.3 (Changelog)

### 1. 📱 Perbaikan Tata Letak Profil & Pengaturan (Bebas Overflow)
- **Desain Ulang Uji Coba Alarm (`Tes H-1`, `Tes H-3 Jam`, `Tes H-30m`)**:
  - Mengatasi galat *RenderFlex right overflowed by 11 pixels* pada layar smartphone yang lebih sempit.
  - Tiga tombol uji coba kini ditata menjadi baris kartu aksi modular terdistribusi merata (*equal-width responsive chips*) dengan ikon tematik, label ringkas, dan proteksi pemotongan teks (*ellipsis*).
  - Header uji coba diberi label jelas berikon volume: `Uji Coba Suara & Notifikasi Alarm`.
- **Optimalisasi Tombol Panduan Layar Mati & Penghemat Baterai**:
  - Merapikan label tombol aksi panduan sistem menjadi `Setelan Notifikasi` dan `Hemat Baterai` dengan pembatasan baris tunggal agar tidak bertumpuk atau terpotong pada berbagai resolusi layar HP.
- **Pembaruan Kartu Tentang TaskApp**:
  - Memperbarui identitas edisi aplikasi menjadi *TaskApp Academic & Financial Student Hub* yang mencerminkan integrasi fitur FinTrack terbaru.

### 2. 🧹 Pembersihan Repositori & Optimalisasi Penyimpanan
- Menghapus berkas catatan rilis versi lama yang sudah tidak digunakan (`RELEASE_NOTES_v2.3.5.md` & `RELEASE_NOTES_v2.4.2.md`) dan memusatkan seluruh dokumentasi rilis pada berkas utama `RELEASE_NOTES.md`.
- Menghapus seluruh berkas APK rilis kedaluwarsa dari root direktori proyek untuk menghemat ruang penyimpanan.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.4.3.apk`** dari daftar **Assets** di bawah.
2. Buka berkas APK di ponsel Android Anda dan pilih tombol **"Update"**.
3. Aplikasi akan langsung terbarukan ke **v2.4.3**. Seluruh data tugas, presensi kuliah, dan catatan keuangan Anda tetap utuh 100%.
