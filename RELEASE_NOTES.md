# TaskApp v2.7.0 — Interaksi Cepat Tugas di Beranda (Swipe Gestures: Quick Done & Reschedule)

> **TaskApp v2.7.0** menghadirkan fitur **Interaksi Cepat Tugas di Beranda (*Swipe Gestures: Quick Done & Reschedule*)** dengan animasi *recessed tray* bergaya **Modern Editorial Productivity**: memungkinkan mahasiswa menyelesaikan tugas, menunda deadline (*Besok, Akhir Pekan, Minggu Depan*), atau menghapus tugas cukup dengan satu gerakan geser tanpa perlu membuka modal detail.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** (`taskapp-release.jks`), sehingga Anda dapat **langsung mengunduh berkas APK dan menekan "Update" tanpa perlu mencopot aplikasi sebelumnya. Seluruh data perkuliahan, tugas, lampiran, presensi, setelan Ambient Sounds, dan buku kas FinTrack Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.7.0 (Changelog)

### 1. ⚡ Swipe ke Kanan: Tandai Selesai & Aktifkan Kembali Instan (`TaskCard`)

- **Aksi Geser Kanan (*Swipe Right*)**:
  - Menggeser kartu tugas ke kanan langsung menandai tugas sebagai **Selesai** (*Instant Complete*) atau mengaktifkan kembali tugas yang sudah selesai.
  - Dilengkapi getaran haptik dua tahap (`HapticFeedback.selectionClick()` tepat saat melewati ambang aktivasi dan `HapticFeedback.mediumImpact()` saat dieksekusi).
  - Menampilkan `SnackBar` melayang dengan tombol **Urungkan** (*Undo*) untuk membatalkan perubahan status dalam satu ketukan.

### 2. 📅 Swipe ke Kiri: Menu Cepat Tunda Deadline (*Quick Reschedule*) & Hapus Tugas (`TaskRescheduleHelper` & `TaskProvider`)

- **Aksi Geser Kiri (*Swipe Left*)**:
  - Menggeser kartu tugas ke kiri membuka panel bawah ringkas **Tunda Deadline atau Hapus** tanpa harus membuka formulir sunting penuh.
- **Preset Tunda 1-Ketuk (*1-Tap Reschedule Presets*)**:
  - ☀️ **Besok** (`H+1` dengan tetap mempertahankan jam & menit tenggat asli tugas).
  - 🛋️ **Akhir Pekan** (Sabtu terdekat dengan tetap mempertahankan jam & menit tenggat asli tugas).
  - 📆 **Minggu Depan (+7 Hari)** (`H+7` dengan tetap mempertahankan jam & menit tenggat asli tugas).
  - 🗓️ **Pilih Tanggal & Jam Lainnya...** (membuka pemilih tanggal dan jam kustom).
  - Setiap penjadwalan ulang otomatis memperbarui alarm pengingat H-1 & H-3 di `TaskReminderService` dan menyertakan tombol **Urungkan** (*Undo*) pada `SnackBar`.
- **Aksi Cepat Hapus Tugas**:
  - Tombol **Hapus Tugas** terintegrasi di bagian bawah panel untuk menghapus tugas secara instan.

### 3. 🎨 Animasi Geser *Recessed Tray* Penuh 1:1

- **Desain Kartu Utuh & Animasi *Action Pill* Progresif**:
  - Kartu tugas tetap mempertahankan bentuk sudut membulat (`borderRadius: 10px`) secara utuh di atas *recessed action tray* dengan bayangan halus saat digeser.
  - Mendukung pergerakan geser penuh 1:1 mengikuti jari di sepanjang lebar kartu dan memantul kembali dengan mulus (`Curves.easeOutCubic`).
  - *Action pill* **`[✓ Selesai]`** dan **`[🕒 Tunda] [🗑️]`** membesar secara progresif serta berubah menjadi warna solid penuh saat siap dilepas.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.7.0.apk`** dari daftar **Assets** di bawah.
2. Buka berkas APK di ponsel Android Anda dan pilih tombol **"Update"**.
3. Aplikasi akan langsung terbarukan ke **v2.7.0**. Seluruh data tugas, lampiran berkas, catatan akademik, dan keuangan Anda tetap utuh 100%.
