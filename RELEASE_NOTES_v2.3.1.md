# TaskApp v2.3.1 — Direct Gallery Export & Seamless In-Place Updates

> **TaskApp v2.3.1** menghadirkan pembaruan penting pada kestabilan dan kemudahan pembaruan aplikasi: integrasi penyimpanan langsung ke **Galeri HP (Album TaskApp)** serta penetapan **Keystore Rilis Resmi Permanen** yang memungkinkan pembaruan aplikasi langsung (*in-place update*) dari APK GitHub Releases tanpa perlu menghapus aplikasi lama, menjamin data akademik Anda tetap 100% aman dan utuh.

---

## ✨ Apa yang Baru di Versi 2.3.1 (Changelog)

### 1. 🖼️ Simpan Wallpaper Langsung ke Galeri HP (Android MediaStore)
- **Terintegrasi Penuh dengan Galeri**: Menambahkan integrasi `gal` (v3.0.0) untuk mendaftarkan dan menyimpan berkas wallpaper beresolusi tinggi (9:16 PNG) langsung ke sistem **Android MediaStore** (`Pictures/TaskApp`).
- **Indexing Instan**: Gambar langsung terindeks dan muncul di urutan paling atas aplikasi Galeri / Google Photos ponsel Anda tanpa harus mencari di folder cache internal.
- **Aksi Cepat "Buka Galeri"**: Notifikasi SnackBar kini dilengkapi tombol aksi **"Buka Galeri"** untuk langsung meninjau hasil ekspor dalam sekali sentuh.

### 2. 🔐 Keystore Rilis Permanen & Pembaruan Tanpa Hapus Aplikasi
- **In-Place Update Resmi**: Mengonfigurasi kunci tanda tangan digital rilis resmi permanen (`taskapp-release.jks`) dengan validitas hingga tahun 2054.
- **Data Tetap Aman 100%**: Menghilangkan masalah sertifikat acak dari runner CI. Mulai versi ini dan seterusnya, Anda dapat langsung mengunduh APK dari GitHub Releases dan menekan **"Update"** tanpa perlu *uninstall* versi lama terlebih dahulu. Seluruh basis data tugas, mata kuliah, absensi, profil, dan pengaturan tersimpan utuh di perangkat Anda.

### 3. 🛡️ Penyempurnaan UI & Presisi Bebas Overflow
- Tampilan tab wallpaper dan PDF kini sepenuhnya responsif dan bebas *RenderFlex overflow* di berbagai ukuran layar ponsel.
- Dukungan pilihan tata letak fleksibel (Otomatis, 2 Kolom, dan 1 Kolom) serta sakelar penampil nama dosen.

---

## 📲 Panduan Instalasi & Pembaruan

> **PENTING (Khusus Pembaruan dari v2.3.0 ke v2.3.1)**:
> Karena versi sebelumnya masih menggunakan kunci acak dari server CI sementara versi ini menggunakan **Kunci Rilis Resmi Permanen**:
> 1. Buka versi lama Anda -> masuk ke **Profil & Pengaturan** -> tekan **"Ekspor Cadangan" (Salin JSON)**.
> 2. Hapus (uninstall) versi lama Anda untuk **terakhir kalinya**.
> 3. Pasang **`TaskApp-v2.3.1.apk`**.
> 4. Buka **Profil & Pengaturan** -> tekan **"Impor JSON"** -> tempelkan teks cadangan.
> 
> *Untuk pembaruan versi-versi berikutnya (v2.3.2, v2.4.0, dst.), Anda bisa langsung menimpa/update APK tanpa perlu uninstall dan tanpa perlu impor ulang lagi!*

---

### 📦 Berkas Unduhan
- **`TaskApp-v2.3.1.apk`** — Berkas rilis mandiri siap pasang di semua ponsel Android (Android 7.0 / API 24 ke atas).
- **`app-release.apk`** — Berkas biner rilis Flutter standar.
