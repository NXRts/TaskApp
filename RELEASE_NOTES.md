# TaskApp v2.3.11 — Notifikasi Murni Tanpa Buka Aplikasi (Native Lock Screen Banner)

> **TaskApp v2.3.11** menyempurnakan alur pengingat batas waktu ketika layar ponsel mati/terkunci. Notifikasi kini tampil murni sebagai **Banner Notifikasi / Heads-Up Lock Screen** standar dengan audio alarm nyaring dan getaran, **tanpa membuka paksa aplikasi ke layar penuh**.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** yang sama, sehingga Anda dapat **langsung mengunduh dan menekan "Update" tanpa perlu menghapus aplikasi dan seluruh data Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.3.11 (Changelog)

### 1. 🔔 Notifikasi Murni Tanpa Buka Aplikasi Otomatis
- **Akar Masalah Teratasi**: Penggunaan `fullScreenIntent` pada versi sebelumnya menyebabkan sistem Android meluncurkan aktivitas aplikasi secara otomatis saat layar mati/terkunci, alih-alih hanya menampilkan kartu notifikasi.
- **Standar Notifikasi Android**: `fullScreenIntent` kini dinonaktifkan (`fullScreenIntent: false`) dan konfigurasi `showWhenLocked`/`turnScreenOn` pada aktivitas utama dilepaskan.
- **Hasil**: Ketika deadline tiba saat HP mati/terkunci, ponsel akan membunyikan alarm dan memunculkan kartu notifikasi elegan di layar kunci (lock screen) persis seperti aplikasi pengingat modern lainnya (seperti Google Calendar / Todoist) tanpa membuka antarmuka aplikasi. Aplikasi baru akan terbuka hanya jika Anda mengetuk notifikasi tersebut.

### 2. 🔊 Saluran Audio Alarm Mandiri v6 (`task_deadline_alarms_v6`)
- Mempertahankan alur audio **STREAM_ALARM** dan nada lonceng `task_alarm.mp3` dengan ID channel baru `v6`, memastikan nada tetap berdering nyaring di saluran alarm.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.3.11.apk`** dari daftar **Assets** di halaman rilis.
2. Buka berkas APK dan tekan tombol **"Update"**.
3. Buka **Profil & Pengaturan** -> tekan tombol **"Tes H-30m"** atau **"Tes H-3 Jam"**, lalu matikan layar HP Anda:
   - Kartu notifikasi akan muncul di layar kunci beserta suara alarm dan getaran, tanpa membuka aplikasi secara paksa.
