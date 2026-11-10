# TaskApp v2.0.6 — Pomodoro Audio Chimes, System Notifications, & Robust Cross-Platform Alert System

> **TaskApp v2.0.6** menghadirkan sistem alarm dan notifikasi pintar untuk **Timer Pomodoro (Fokus Belajar)**. Dilengkapi harmoni audio lonceng zen alami saat sesi fokus maupun rehat selesai, notifikasi push sistem operasi, getaran haptic, serta arsitektur pemutaran audio lintas platform yang tangguh.

---

## ✨ Apa yang Baru di Versi 2.0.6 (Changelog)

### 🔔 1. Audio Lonceng Zen & Getaran Haptik Pomodoro
* **Harmoni Audio Lonceng Zen Alami**:
  * **Selesai Sesi Fokus (25 Menit)**: Memutar harmoni lonceng zen 3-nada (*C5 – E5 – C6*) yang lembut dan menenangkan.
  * **Selesai Sesi Rehat (5 Menit)**: Memutar nada lonceng segar (*G5 – B5 – E6*) penanda kesiapan kembali belajar.
* **Getaran Haptik**: Memberikan umpan balik getaran lembut pada smartphone saat timer mencapai `00:00`.
* **Arsitektur Pemutar Audio Tangguh (Multi-Platform)**:
  * **Android & iOS**: Menggunakan `audioplayers` native yang ringan dan efisien.
  * **Linux Desktop**: Dilengkapi fallback audio server native (`pw-play` PipeWire / `aplay` ALSA) sehingga bebas dari ketergantungan plugin pihak ketiga (GStreamer).

### 📱 2. Notifikasi Push Sistem Operasi (`flutter_local_notifications`)
* Menampilkan notifikasi push lokal pada Android, iOS, dan desktop saat sesi belajar/istirahat selesai.
* Pengguna tetap mendapatkan pengingat tepat waktu meskipun aplikasi sedang diminimalkan atau membuka aplikasi lain.
* Mendukung izin notifikasi Android 13+ (`POST_NOTIFICATIONS`) secara terintegrasi.

### 🧘 3. Pengalaman Pengguna (UX) Minimalis & Dialog Interaktif
* **Dialog Penyelesaian Sesi**: Menampilkan modal bottom sheet interaktif yang mengapresiasi sesi belajar Anda dan menyediakan tombol 1-klik untuk langsung beralih ke rehat 5 menit atau memulai sesi fokus berikutnya.
* **Tombol Toggle Suara & Notifikasi**: Ikon kontrol on/off di bilah navigasi atas (*AppBar*) layar Pomodoro untuk mematikan atau mengaktifkan alarm lonceng dan notifikasi sistem dengan cepat.
* **Antarmuka Bersih**: Tampilan timer fokus dipertahankan tetap elegan, bersih, dan bebas distraksi (*zen minimalism*).

---

## 📥 Panduan Instalasi (Android APK)

1. Unduh file **`TaskApp-v2.0.6.apk`** atau **`app-release.apk`** dari bagian **Assets** di bawah.
2. Buka file APK yang telah diunduh di smartphone Android Anda.
3. Jika diminta izin instalasi dari sumber tak dikenal, pilih **Izinkan (Allow)**.
4. Tekan **Pasang (Install)** / **Perbarui (Update)**.
5. Selesai! Data tugas, mata kuliah, riwayat sesi fokus, dan profil Anda akan tetap tersimpan aman.

---

## 📱 Spesifikasi Sistem
* **Sistem Operasi**: Android 6.0 (Marshmallow, API 23) ke atas
* **Arsitektur**: `arm64-v8a`, `armeabi-v7a`, `x86_64`
* **Kebutuhan Jaringan**: 100% Offline (Bekerja penuh tanpa koneksi internet)
* **Ukuran File**: ~20 MB

---

**Full Changelog**: https://github.com/NXRts/TaskApp/compare/v2.0.5...v2.0.6
