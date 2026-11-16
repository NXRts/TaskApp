# TaskApp v2.3.9 — Pengingat Kritis Deadline H-30 Menit & Sinkronisasi Otomatis

> **TaskApp v2.3.9** menghadirkan fitur **Pengingat Kritis H-30 Menit** untuk tugas-tugas dengan deadline yang sangat dekat atau saat waktu pengumpulan sudah mendesak. Pembaruan ini juga menyertakan fitur **Auto-Sync Reminders saat Startup**, memastikan seluruh jadwal alarm tugas aktif yang belum selesai otomatis terdaftar ulang ke sistem Android saat aplikasi dibuka.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** yang sama, sehingga Anda dapat **langsung mengunduh dan menekan "Update" tanpa perlu menghapus aplikasi dan seluruh data Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.3.9 (Changelog)

### 1. 🚨 Pengingat Kritis Deadline H-30 Menit
- **Alarm Kritis 30 Menit Sebelum Deadline**: Menyediakan peringatan mendesak tepat 30 menit sebelum batas waktu pengumpulan tugas berakhir.
- **Dukungan Penuh Tugas Jangka Pendek**: Tugas yang baru dibuat dengan deadline singkat (misalnya 35 menit lagi) kini dijamin dapat memicu alarm karena alarm H-30 menit dijadwalkan di masa depan (5 menit setelah pembuatan tugas).
- **Pengaturan & Uji Coba Mandiri**: Dilengkapi dengan toggle pengaktifan di halaman **Profil & Pengaturan** serta tombol pengujian **"Tes H-30m"** untuk memverifikasi suara dan notifikasi mengambang seketika.

### 2. 🔄 Auto-Sync Jadwal Alarm saat Startup
- **Sinkronisasi Otomatis**: Saat aplikasi dibuka, `TaskProvider` secara otomatis memanggil `syncReminders()` untuk memindai seluruh tugas yang belum selesai dan mendaftarkan alarm H-1, H-3 Jam, serta H-30 Menit ke sistem Android AlarmManager.

### 3. 🖥️ Dukungan Precision Timer untuk Linux Desktop & Foreground
- **In-Memory Precision Scheduler**: Menambahkan penjadwal timer presisi di memori untuk desktop (Linux/Windows) dan saat aplikasi aktif di latar depan, memastikan notifikasi alarm berdering tepat waktu tanpa tergantung pada background daemon sistem operasi.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.3.9.apk`** dari daftar **Assets** di halaman rilis.
2. Buka berkas APK dan tekan tombol **"Update"**.
3. Buka **Profil & Pengaturan**, aktifkan toggle **"🚨 Pengingat Kritis H-30 Menit"**, dan uji coba dengan tombol **"Tes H-30m"**.

---

### 📦 Berkas Unduhan
- **`TaskApp-v2.3.9.apk`** — Berkas rilis resmi mandiri siap pasang di semua ponsel Android (Android 7.0 / API 24 ke atas).
- **`app-release.apk`** — Berkas biner rilis Flutter standar.
