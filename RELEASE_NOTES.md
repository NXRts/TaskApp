# TaskApp v2.3.10 — Audio Stream Alarm, Layar Terkunci & Bangun Layar (Doze Exemption)

> **TaskApp v2.3.10** mengatasi masalah audio notifikasi di ponsel Android dan memastikan notifikasi tetap menyala dan bersuara keras meskipun **layar ponsel mati/terkunci** atau **aplikasi ditutup total di latar belakang**.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** yang sama, sehingga Anda dapat **langsung mengunduh dan menekan "Update" tanpa perlu menghapus aplikasi dan seluruh data Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.3.10 (Changelog)

### 1. 🔊 Saluran Audio Alarm Keras (`AudioAttributesUsage.alarm`)
- **Akar Masalah Teratasi**: Sebelumnya berkas notifikasi Android tidak secara eksplisit mereferensikan sumber daya audio `task_alarm` pada saluran sistem, sehingga sistem ponsel memperlakukannya sebagai nada hening/default yang teredam saat ponsel dalam mode getar.
- **Dedicated Alarm Audio Stream**: Channel notifikasi kini diperbarui ke `task_deadline_alarms_v5` yang secara eksplisit memutar `raw/task_alarm` melalui **STREAM_ALARM** (alur suara alarm jam dinding/becker). Suara alarm dipastikan berbunyi nyaring bahkan ketika nada notifikasi umum sedang hening atau senyap.

### 2. 📱 Tampil Saat Layar Mati & Bangunkan Layar (`fullScreenIntent` & `showWhenLocked`)
- Menambahkan izin `android.permission.USE_FULL_SCREEN_INTENT` dan konfigurasi `android:showWhenLocked="true"` serta `android:turnScreenOn="true"` pada AndroidManifest.
- Ketika waktu deadline tiba (H-1, H-3 Jam, H-30 Menit), layar ponsel akan otomatis menyala dan menampilkan banner pengingat mendesak langsung di atas lock screen.

### 3. 🔋 Pengecualian Penghemat Baterai (Doze Mode Exemption)
- Menambahkan izin `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` dan tombol pintasan **"Abaikan Hemat Baterai"** di halaman **Profil & Pengaturan**.
- Mencegah sistem Android (terutama Xiaomi MIUI/HyperOS, Samsung, & Oppo) menidurkan atau mematikan background timer aplikasi saat layar HP dimatikan.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.3.10.apk`** dari daftar **Assets** di halaman rilis.
2. Buka berkas APK dan tekan tombol **"Update"**.
3. Buka **Profil & Pengaturan**:
   - Tekan tombol **"Abaikan Hemat Baterai"** -> pilih Izinkan / Tanpa Pembatasan.
   - Tekan tombol **"Tes H-3 Jam"** atau **"Tes H-30m"**: Notifikasi akan langsung berdering dengan suara lonceng alarm keras dan banner mengambang!
