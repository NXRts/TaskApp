# TaskApp v2.6.0 — Multi-Track Offline Ambient Sounds Mixer & Pemisahan Tab Fokus

> **TaskApp v2.6.0** menghadirkan fitur **Multi-Track Offline Ambient Sounds Mixer** pada menu **Fokus**: menyediakan **9 lanskap suara alam & suasana asli** yang bekerja **100% offline** dan dapat **diputar secara bersamaan (simultan)** untuk menciptakan suasana belajar yang tenang di kos maupun perpustakaan tanpa kuota internet.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** (`taskapp-release.jks`), sehingga Anda dapat **langsung mengunduh berkas APK dan menekan "Update" tanpa perlu mencopot aplikasi sebelumnya. Seluruh data perkuliahan, tugas, lampiran, presensi, dan buku kas FinTrack Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.6.0 (Changelog)

### 1. 🎧 Multi-Track Ambient Sounds Mixer (9 Suara Alam & Suasana Offline)

- **9 Lanskap Suara Alam & Suasana Asli (`AmbientSoundTrack`)**:
  - 🌧️ **Rain** (Hujan rintik alami • Biru `#3B82F6`)
  - 🔥 **Fireplace** (Perapian kayu hangat • Oranye `#F97316`)
  - 🌊 **River** (Aliran sungai tenang • Cyan `#06B6D4`)
  - 🍃 **Wind** (Desir angin pepohonan • Teal `#14B8A6`)
  - ☕ **Cafe Ambience** (Suasana kedai kopi & ruang baca • Amber `#F59E0B`)
  - 🐦 **Morning Birds** (Kicau burung pagi hari • Hijau `#22C55E`)
  - ⚡ **Thunderstorm** (Gemuruh petir kejauhan • Kuning `#EAB308`)
  - 🌙 **Nature Night** (Suasana malam alam tenang • Indigo `#6366F1`)
  - 🌊 **Ocean Waves** (Deburan ombak pantai • Sky `#0EA5E9`)
- **Pemutaran Simultan & Campuran Bebas**:
  - Seluruh 9 suara dapat dinyalakan bersamaan dalam kombinasi apa pun dengan slider volume individual (`0%`–`100%`) dan indikator warna aktif masing-masing.
  - Dilengkapi *equal-power circular crossfade* sehingga setiap suara berputar berulang (*infinite loop*) dengan mulus tanpa jeda.

### 2. 🎚️ Master Volume, Sleep Timer & Mesin Audio Real-Time (`AmbientSoundService`)

- **Kontrol Master & Sleep Timer Terpadu**:
  - **Master Volume Slider (`0%`–`100%`)**: Mengatur tingkat keras suara keseluruhan campuran audio secara proporsional.
  - **Sleep Timer Otomatis**: Pilihan waktu henti otomatis (`No Timer`, `15 Minutes`, `30 Minutes`, `45 Minutes`, `1 Hour`) lengkap dengan hitung mundur waktu nyata (`MM:SS`).
  - **Aksi Cepat `Play All` / `Pause All` & `Reset`**: Menyalakan/menjeda seluruh suara sekaligus atau mengembalikan seluruh volume ke setelan awal (`50%` per suara & `100%` Master) dalam satu ketukan.
- **Perubahan Volume Real-Time Tanpa Mengulang dari Awal**:
  - Menggeser slider volume suara maupun Master Volume langsung menyesuaikan amplitudo di posisi waktu yang sedang berjalan tanpa mengulang audio dari detik `0:00`, serta otomatis menghentikan pemutaran saat aplikasi ditutup.
- **Penyimpanan Preferensi Lokal (`StorageService`)**:
  - Volume masing-masing dari 9 suara, Master Volume, dan durasi Sleep Timer tersimpan otomatis di Hive dan tercakup dalam *Full-State JSON Backup*.

### 3. 🗂️ Pemisahan Tab di Menu Fokus & Pembaruan Dokumentasi (`PomodoroScreen` & `AmbientSoundsView`)

- **Sakelar Tab `Timer Pomodoro` | `Ambient Sounds`**:
  - Tampilan **Ambient Sounds** kini dipisahkan ke dalam tab khusus berdampingan dengan **Timer Pomodoro** di dalam menu **Fokus**, dilengkapi badge jumlah suara yang sedang aktif (`N Aktif`).
- **Pembaruan Dokumentasi Proyek**:
  - Memperbarui `README.md` dan `PRD_TaskApp_Redesign.md` dengan arsitektur serta spesifikasi fitur terbaru.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.6.0.apk`** dari daftar **Assets** di bawah.
2. Buka berkas APK di ponsel Android Anda dan pilih tombol **"Update"**.
3. Aplikasi akan langsung terbarukan ke **v2.6.0**. Seluruh data tugas, lampiran berkas, catatan akademik, dan keuangan Anda tetap utuh 100%.
