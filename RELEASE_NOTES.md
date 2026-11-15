# TaskApp v2.3.3 — Floating Notifications & Audible Task Deadline Alarms

> **TaskApp v2.3.3** menghadirkan pembaruan besar pada sistem pengingat deadline akademik: audio alarm kustom yang nyaring (`task_alarm`), integrasi **Notifikasi Mengambang (*Floating Banner / Heads-up Notification*)** baik saat aplikasi sedang dibuka maupun ditutup, keandalan pemicuan saat layar terkunci (*Wake Lock & AlarmClock Mode*), serta tombol pintas satu-sentuh untuk setelan notifikasi sistem HP (khusus pengguna Xiaomi MIUI/HyperOS, Samsung, & Oppo).
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** yang sama, sehingga Anda dapat **langsung mengunduh dan mengupdate tanpa perlu menghapus aplikasi dan seluruh data Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.3.3 (Changelog)

### 1. 🪟 Notifikasi Mengambang (*Floating Banner / Heads-up Notification*)
- **Saat Aplikasi Dibuka (*In-App Floating Banner*)**: Ketika notifikasi pengingat atau tombol tes ditekan saat aplikasi aktif, muncul kartu banner animasi elegan yang melayang di bagian atas layar (*slide & fade-in*). Dilengkapi indikator urgensi (*DARURAT / PENGINGAT*), judul tugas, rincian waktu, serta gestur *swipe-up* atau tombol silang untuk menutup.
- **Saat Aplikasi Ditutup / Sedang Membuka Aplikasi Lain**: Notifikasi kini dikonfigurasi dengan visibilitas publik dan prioritas maksimal (`Importance.max` & `Priority.max`) agar sistem Android menampilkan *heads-up banner* melayang di atas layar aplikasi lain.
- **Pintas Setelan Notifikasi HP**: Tombol interaktif **"Buka Setelan Notifikasi HP"** langsung di menu Profil & Pengaturan memudahkan pengguna perangkat Xiaomi MIUI/HyperOS, Samsung OneUI, dan Oppo ColorOS untuk mengaktifkan izin *Notifikasi Mengambang* dan *Mulai Otomatis* dalam sekali sentuh.

### 2. 🔔 Audio Alarm Kustom Mandiri (`task_alarm`)
- **Nada Alarm Nyaring & Jelas**: Menambahkan berkas audio alarm mandiri `task_alarm.mp3` ke dalam *resource* native Android dan menautkannya dengan atribut `AudioAttributesUsage.alarm`.
- **Channel Notifikasi Baru (`task_deadline_alarms_v2`)**: Memperbarui saluran notifikasi dengan dukungan getaran ganda (*dual-burst vibration*) dan membersihkan konfigurasi hening lama di sistem operasi.
- **Uji Coba Langsung Bersuara**: Tombol **"Tes H-1"** dan **"Tes H-3 Jam"** di menu Pengaturan kini langsung memicu suara alarm kustom dan getaran secara instan.

### 3. ⏰ Pemicu Andal Saat Aplikasi Ditutup / Layar Terkunci
- **Mode `AndroidScheduleMode.alarmClock`**: Memanfaatkan prioritas alarm tertinggi di sistem Android setingkat jam beker bawaan HP, yang terbukti menembus mode hemat daya (*Doze Mode*).
- **Izin `WAKE_LOCK`**: Menjaga CPU ponsel tetap terjaga sesaat untuk membunyikan audio alarm pengingat meskipun layar HP sedang mati atau terkunci.

### 4. ⚡ Pembaruan Langsung Tanpa Uninstall (In-Place Update)
- Berkas APK **v2.3.3** ditandatangani dengan **Kunci Rilis Resmi Permanen (`taskapp-release.jks`)** yang identik.
- Anda dapat **langsung menekan "Update"** tanpa perlu menghapus versi lama terlebih dahulu. Seluruh basis data jadwal kuliah, riwayat presensi, mata kuliah, dan tugas Anda dijamin tetap utuh 100%.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.3.3.apk`** dari daftar **Assets** di bawah.
2. Buka berkas APK dan tekan tombol **"Update"**.
3. Buka **Profil & Pengaturan** -> tekan **"Buka Setelan Notifikasi HP"** untuk memastikan toggle **Notifikasi Mengambang** aktif.
4. Selesai! Nikmati pengingat tugas kuliah yang akurat, bersuara nyaring, dan melayang di layar.

---

### 📦 Berkas Unduhan
- **`TaskApp-v2.3.3.apk`** — Berkas rilis resmi mandiri siap pasang di semua ponsel Android (Android 7.0 / API 24 ke atas).
- **`app-release.apk`** — Berkas biner rilis Flutter standar.
