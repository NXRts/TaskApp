# TaskApp v2.3.7 — Bulletproof Native Android Notifications & Xiaomi HyperOS Optimization

> **TaskApp v2.3.7** menghadirkan pembaruan total pada subsistem notifikasi Android: regenerasi Notification Channel bersih (`task_deadline_alarms_v3`), penyediaan aset ikon notifikasi di seluruh varian densitas layar (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`), penghapusan ketergantungan raw sound parameter yang memicu penolakan sistem, serta sistem fallback notifikasi tangguh dengan penanganan pesan galat transparan.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** yang sama, sehingga Anda dapat **langsung mengunduh dan menekan "Update" tanpa perlu menghapus aplikasi dan seluruh data Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.3.7 (Changelog)

### 1. 🔔 Regenerasi Saluran Notifikasi Segar (`task_deadline_alarms_v3`)
- **Pembersihan Cache Saluran Sistem Android**: Pada Android 8.0+ dan Xiaomi HyperOS/MIUI, konfigurasi saluran (*Notification Channel*) dibekukan saat pertama kali dibuat. Versi ini secara otomatis membersihkan saluran usang dan meregenerasi saluran baru dengan prioritas maksimal (`Importance.max`), getaran, dan visibilitas publik.
- **Kategori Notifikasi di Xiaomi**: Mengoptimalkan saluran baru agar langsung dikenali oleh sistem kontrol notifikasi Xiaomi tanpa bentrok dengan status lama.

### 2. 🖼️ Pustaka Ikon Notifikasi Lengkap Semua Densitas Layar
- Menyediakan berkas `app_icon.png` dan `ic_notification.png` di seluruh folder densitas drawable Android (`drawable-mdpi`, `drawable-hdpi`, `drawable-xhdpi`, `drawable-xxhdpi`, `drawable-xxxhdpi`).
- Menetapkan `icon: 'app_icon'` secara eksplisit pada setiap payload notifikasi sehingga sistem Android tidak lagi mengalami galat pembacaan ikon kecil (*small icon*).

### 3. 🛡️ Arsitektur Notifikasi Bertingkat (Bulletproof Fallback)
- **Fallback Otomatis**: Jika perangkat tertentu membatasi atribut audio atau parameter warna kustom, sistem secara otomatis melakukan *fallback* instan untuk mengirimkan notifikasi esensial berprioritas tinggi.
- **Umpan Balik Transparan**: Tombol pengujian kini menampilkan pesan status aktual dari sistem operasi alih-alih pesan umum.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.3.7.apk`** dari daftar **Assets** di bawah.
2. Buka berkas APK dan tekan tombol **"Update"**.
3. Buka **Profil & Pengaturan** -> tekan **"Tes H-1"** atau **"Tes H-3 Jam"**. Notifikasi resmi akan langsung melayang di atas layar dan menetap di panel kontrol / bilah status HP Anda!
4. *(Pastikan Mode Jangan Ganggu / Ikon Bulan Sabit 🌙 di HP tidak aktif saat menguji)*.

---

### 📦 Berkas Unduhan
- **`TaskApp-v2.3.7.apk`** — Berkas rilis resmi mandiri siap pasang di semua ponsel Android (Android 7.0 / API 24 ke atas).
- **`app-release.apk`** — Berkas biner rilis Flutter standar.
