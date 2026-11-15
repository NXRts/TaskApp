# TaskApp v2.3.5 — Native OS Notifications & Cross-Platform Audio Stability

> **TaskApp v2.3.5** menghadirkan penyempurnaan menyeluruh pada sistem notifikasi dan stabilitas audio lintas platform: menghadirkan notifikasi sistem native murni di luar aplikasi (terintegrasi penuh ke Panel Kontrol HP & desktop KDE Plasma / GNOME), penambahan batas waktu otomatis (*auto-dismiss timeout 5s*), penanganan audio native Linux bebas galat GStreamer, serta perbaikan assertion UI Material.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** yang sama, sehingga Anda dapat **langsung mengunduh dan menekan "Update" tanpa perlu menghapus aplikasi dan seluruh data Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.3.5 (Changelog)

### 1. 🪟 Notifikasi Sistem Native Penuh di Luar Aplikasi
- **Terbit Langsung di Panel Kontrol HP**: Notifikasi kini 100% menggunakan saluran notifikasi resmi sistem operasi Android. Saat tombol tes atau jadwal alarm terpicu, notifikasi langsung melayang di atas layar (*heads-up floating banner*) dan menetap di **Panel Kontrol / Tirai Notifikasi HP** di luar aplikasi.
- **Pembersihan Banner Tiruan**: Menghapus banner internal tiruan agar seluruh interaksi notifikasi seragam mengikuti antarmuka sistem operasi perangkat Anda.

### 2. ⏱️ Auto-Dismiss Timeout 5 Detik di Linux Desktop
- **Otomatis Menghilang**: Notifikasi desktop di Linux (KDE Plasma / GNOME) kini dikonfigurasi dengan batas waktu **5000 ms (5 detik)** dan tingkat urgensi normal, sehingga popup notifikasi otomatis meluncur dan menghilang sendiri tanpa perlu diklik tombol silang `[X]` secara manual.

### 3. 🔊 Penanganan Audio Bebas Galat GStreamer (Linux & Android)
- **Audio Native Sistem di Linux**: Mengalihkan pemutaran audio alarm di Linux ke utilitas audio native (`pw-play` / `paplay` / `aplay`), mencegah galat `LinuxAudioError: missing GStreamer plug-in` dan memastikan bunyi alarm terdengar nyaring seketika.
- **Saluran Alarm Android**: Di HP Android, nada kustom mandiri `task_alarm.mp3` dan saluran alarm presisi bekerja mulus.

### 4. 🛡️ Penyempurnaan Widget Material & Bebas Konflik Tag
- Memperbaiki konflik duplikasi `borderRadius` dan `shape` pada widget `Material` di menu Profil & Pengaturan.
- Menetapkan `heroTag` unik (`calendar_fab` dan `main_fab`) pada tombol melayang FloatingActionButton untuk mencegah konflik tag pada subtree widget.

### 5. ⚡ Pembaruan Langsung Tanpa Uninstall (In-Place Update)
- Berkas APK **v2.3.5** ditandatangani dengan **Kunci Rilis Resmi Permanen (`taskapp-release.jks`)** yang identik.
- Anda dapat **langsung mengunduh dan menekan "Update"** tanpa perlu menghapus versi lama.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.3.5.apk`** dari daftar **Assets** di bawah.
2. Buka berkas APK dan tekan tombol **"Update"**.
3. Buka **Profil & Pengaturan** -> tekan **"Tes H-1"** atau **"Tes H-3 Jam"**. Notifikasi resmi akan langsung melayang di luar aplikasi dan masuk ke Panel Kontrol HP Anda lengkap dengan nada alarm!
4. *(Khusus pengguna Xiaomi/MIUI/HyperOS, Samsung, & Oppo)*: Tekan tombol **"Buka Setelan Notifikasi HP"** untuk memastikan opsi **Notifikasi Mengambang** aktif.

---

### 📦 Berkas Unduhan
- **`TaskApp-v2.3.5.apk`** — Berkas rilis resmi mandiri siap pasang di semua ponsel Android (Android 7.0 / API 24 ke atas).
- **`app-release.apk`** — Berkas biner rilis Flutter standar.
