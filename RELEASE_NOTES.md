# TaskApp v2.3.4 — Hotfix Notifikasi Mengambang & Audio Alarm Mandiri

> **TaskApp v2.3.4** menghadirkan perbaikan tuntas (*hotfix*) pada sistem notifikasi pengingat deadline dan timer: menyelesaikan kendala referensi ikon drawable native yang sebelumnya memicu pengecualian (*silent crash*), memisahkan alur eksekusi floating banner in-app dan pemutar audio langsung, serta menambahkan ikon notifikasi resmi (`app_icon.png` & `ic_notification.png`) ke direktori drawable Android.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** yang sama, sehingga Anda dapat **langsung mengunduh dan menekan "Update" tanpa perlu menghapus aplikasi dan seluruh data Anda tetap aman 100%**.

---

## ✨ Apa yang Diperbaiki di Versi 2.3.4 (Changelog)

### 1. 🛠️ Perbaikan Ikon Notifikasi Native (`app_icon` di `res/drawable`)
- **Akar Masalah**: Sebelumnya, plugin notifikasi Android memvalidasi string `'@mipmap/ic_launcher'` di folder `drawable`, yang memicu kegagalan sistem internal Android (*PlatformException: Invalid drawable resource*) sehingga notifikasi sistem dan floating banner tidak sempat muncul.
- **Solusi**: Menyalin dan mendaftarkan berkas `app_icon.png` serta `ic_notification.png` ke dalam direktori native `android/app/src/main/res/drawable/` dan menginisialisasi plugin menggunakan referensi drawable resmi.

### 2. 🪟 Jaminan Munculnya Banner Mengambang (*Floating Banner In-App*)
- Alur pemanggilan **Floating Banner** kini dijalankan secara independen di awal dengan blok penanganan mandiri, menjamin banner melayang di atas layar selalu muncul saat tombol uji coba ditekan di aplikasi.

### 3. 🔊 Pemutar Suara Alarm Ganda (Direct Audio & System Alarm)
- Menambahkan pemutar audio langsung (`AudioPlayer`) untuk tombol **"Tes H-1"** dan **"Tes H-3 Jam"** sehingga nada alarm langsung berbunyi nyaring di speaker ponsel saat Anda berada di dalam aplikasi.
- Saluran sistem operasi Android tetap membunyikan berkas alarm mandiri `task_alarm.mp3` saat notifikasi dipicu.

### 4. ⚡ Pembaruan Langsung Tanpa Uninstall (In-Place Update)
- Berkas APK **v2.3.4** ditandatangani dengan **Kunci Rilis Resmi Permanen (`taskapp-release.jks`)** yang identik.
- Anda dapat **langsung mengunduh dan menekan "Update"** tanpa perlu menghapus versi lama.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.3.4.apk`** dari daftar **Assets** di bawah.
2. Buka berkas APK dan tekan tombol **"Update"**.
3. Buka **Profil & Pengaturan** -> tekan **"Tes H-1"** atau **"Tes H-3 Jam"**. Banner mengambang dan bunyi lonceng alarm kini langsung muncul dan bersuara seketika!
4. *(Khusus pengguna Xiaomi/MIUI/HyperOS, Samsung, & Oppo)*: Tekan tombol **"Buka Setelan Notifikasi HP"** untuk memastikan opsi **Notifikasi Mengambang** aktif.

---

### 📦 Berkas Unduhan
- **`TaskApp-v2.3.4.apk`** — Berkas rilis resmi mandiri siap pasang di semua ponsel Android (Android 7.0 / API 24 ke atas).
- **`app-release.apk`** — Berkas biner rilis Flutter standar.
