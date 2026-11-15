# TaskApp v2.3.2 — Scheduled Task Deadline Alarms & Seamless In-Place Updates

> **TaskApp v2.3.2** menghadirkan fitur **Pengingat Deadline Cerdas Terjadwal (Scheduled Task Alarms)** yang memanfaatkan alarm presisi sistem operasi untuk mengingatkan mahasiswa pada **H-1 Hari (Pukul 19:00)** dan **Darurat H-3 Jam** sebelum batas akhir pengumpulan tugas akademik. Pembaruan ini ditandatangani dengan Keystore Resmi Permanen yang sama dengan v2.3.1, sehingga Anda dapat **langsung mengunduh dan mengupdate tanpa perlu menghapus aplikasi dan seluruh data Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.3.2 (Changelog)

### 1. 🔔 Pengingat Deadline Cerdas Terjadwal (Scheduled Task Alarms)
- **Alarm H-1 Hari (Pukul 19:00 WIB/lokal)**: Sistem otomatis menjadwalkan notifikasi pengingat pada malam hari sebelum batas waktu pengumpulan tugas dengan mencantumkan judul tugas, nama mata kuliah, serta jam batas pengumpulan.
- **Alarm Darurat H-3 Jam**: Peringatan mendesak tepat 3 jam sebelum batas akhir pengumpulan tugas untuk mencegah keterlambatan pengumpulan tugas kuliah.
- **Siklus Hidup Pintar & Auto-Cancel**: Alarm otomatis dibuat saat tugas ditambahkan atau diperbarui, dan **langsung dibatalkan secara otomatis saat tugas ditandai selesai** agar tidak mengganggu Anda.
- **Kendali Penuh di Profil & Pengaturan**: Dilengkapi sakelar master, pilihan jenis alarm, serta tombol **Uji Coba Alarm ("Tes H-1" & "Tes H-3 Jam")** untuk memastikan notifikasi bersuara dan bergetar sempurna di ponsel.
- **Kesiapan Boot & Zona Waktu**: Notifikasi tetap terjaga saat ponsel di-restart berkat dukungan `RECEIVE_BOOT_COMPLETED` dan integrasi zona waktu lokal (`flutter_timezone`).

### 2. ⚡ Pembaruan Langsung Tanpa Uninstall (In-Place Update)
- Bagi pengguna yang sudah memasang **TaskApp v2.3.1**, berkas **v2.3.2** ini ditandatangani dengan **Kunci Rilis Resmi Permanen (`taskapp-release.jks`)** yang identik.
- Anda dapat **langsung mengunduh dan menekan "Update"** tanpa perlu *uninstall* versi lama terlebih dahulu. Seluruh jadwal, riwayat presensi, mata kuliah, dan tugas Anda dijamin tetap utuh 100%.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.3.2.apk`** dari daftar **Assets** di bawah.
2. Buka berkas APK dan tekan tombol **"Update"**.
3. Selesai! Aplikasi langsung terbarui tanpa kehilangan data apa pun.

---

### 📦 Berkas Unduhan
- **`TaskApp-v2.3.2.apk`** — Berkas rilis resmi mandiri siap pasang di semua ponsel Android (Android 7.0 / API 24 ke atas).
- **`app-release.apk`** — Berkas biner rilis Flutter standar.
