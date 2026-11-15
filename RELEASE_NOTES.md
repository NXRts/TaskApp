# TaskApp v2.3.6 — Smart Notification Permissions & OS Panel Delivery

> **TaskApp v2.3.6** menghadirkan peningkatan cerdas pada sistem pengiriman notifikasi di luar aplikasi: validasi izin sistem runtime Android proaktif (`areNotificationsEnabled`), deteksi otomatis pemblokiran notifikasi OS dengan tombol pintasan langsung ke pengaturan sistem HP, serta panduan interaktif untuk pengguna Xiaomi (HyperOS / MIUI) agar notifikasi mengambang (*floating banner*) dan suara alarm bekerja maksimal.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** yang sama, sehingga Anda dapat **langsung mengunduh dan menekan "Update" tanpa perlu menghapus aplikasi dan seluruh data Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.3.6 (Changelog)

### 1. 🔔 Validasi Izin Notifikasi Sistem Android Proaktif
- **Pemeriksaan Izin Runtime Otomatis**: Sebelum menembakkan notifikasi pengingat, aplikasi kini secara otomatis memvalidasi apakah izin notifikasi telah diberikan di sistem Android (`areNotificationsEnabled()`).
- **Feedback Status Jelas & Interaktif**:
  - **Status Hijau**: Konfirmasi langsung bahwa notifikasi berhasil dikirimkan ke panel kontrol / bilah status HP.
  - **Status Merah**: Jika izin sistem dinonaktifkan (misalnya tidak sengaja ditolak atau dibatasi oleh sistem hemat daya HP), aplikasi menampilkan peringatan jelas lengkap dengan tombol **"Setelan"** yang sekali ketuk langsung membuka halaman pengaturan perizinan aplikasi di HP.

### 2. 🪟 Panduan Khusus Pengguna Xiaomi (HyperOS / MIUI) & Android Modern
- Penambahan kartu panduan cepat untuk mengaktifkan opsi **"Notifikasi Mengambang" (*Floating Notifications*)** yang secara default sering dinonaktifkan oleh sistem keamanan Xiaomi untuk file APK unduhan.
- Tombol **"Buka Setelan Notifikasi HP"** memudahkan pengaktifan izin suara, getaran, dan notifikasi mengambang tanpa perlu mencari manual di menu setelan HP.

### 3. 🛡️ Stabilitas Pengingat Deadline & Audio Lintas Platform
- Memastikan notifikasi pengingat H-1 dan H-3 jam tetap berjalan presisi melalui alarmClock & exact alarm receiver saat aplikasi tertutup.
- Bebas dari galat GStreamer pada Linux desktop dan bebas galat resource icon pada perangkat Android.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.3.6.apk`** dari daftar **Assets** di bawah.
2. Buka berkas APK dan tekan tombol **"Update"**.
3. Buka **Profil & Pengaturan** -> tekan **"Tes H-1"** atau **"Tes H-3 Jam"**. Notifikasi resmi akan langsung melayang di luar aplikasi dan masuk ke Panel Kontrol HP Anda lengkap dengan nada alarm!
4. *(Pastikan Mode Jangan Ganggu / Ikon Bulan Sabit 🌙 di HP tidak aktif saat menguji suara alarm)*.

---

### 📦 Berkas Unduhan
- **`TaskApp-v2.3.6.apk`** — Berkas rilis resmi mandiri siap pasang di semua ponsel Android (Android 7.0 / API 24 ke atas).
- **`app-release.apk`** — Berkas biner rilis Flutter standar.
