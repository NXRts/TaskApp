# TaskApp v2.4.1 — Penyempurnaan Tata Letak Modal Transaksi & Desain Dialog Patungan/Piutang (Mobile UI Polish)

> **TaskApp v2.4.1** menyempurnakan kenyamanan antarmuka mobile pada modul **FinTrack Mahasiswa**: menata ulang tata letak modal transaksi agar tidak menembus status bar maupun terpotong tombol navigasi, serta mendesain ulang dialog **Catat Patungan & Piutang (Split Bill & IOU)** dengan tipografi satu baris yang elegan dan tombol preset nominal cepat.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** yang sama, sehingga Anda dapat **langsung mengunduh dan menekan "Update" tanpa perlu menghapus aplikasi dan seluruh data tugas/matkul/keuangan Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.4.1 (Changelog)

### 1. 🤝 Desain Ulang Dialog Catat Patungan & Piutang (Split Bill & IOU Tracker)
- **Switcher Satu Baris Ringkas & Elegan**:
  - Teks yang sebelumnya bertumpuk canggung menjadi 2 baris kini diperbarui menjadi label satu baris tegas:
    - `[ ↗ Saya Talangi ]` (Aksen Kobalt `#3B82F6` dengan bayangan lembut).
    - `[ ↙ Saya Pinjam ]` (Aksen Amber `#F59E0B` dengan bayangan lembut).
  - Dilengkapi transisi animasi 140ms yang responsif.
- **Kartu Edukasi Mikro Dinamis**:
  - Menjelaskan arti transaksi secara instan di bawah sakelar:
    - Saat *Saya Talangi*: `🟢 Piutang: Teman berhutang pada Anda (akan ditagih)`.
    - Saat *Saya Pinjam*: `🟡 Hutang: Anda meminjam uang teman (harus dibayar)`.
- **Kartu Nominal Cerdas dengan Preset Instan**:
  - Input nominal bergaya kas modern dengan awalan `Rp ` dan tombol cepat `+10k`, `+20k`, `+50k`, `+100k` serta tombol *Reset*.
- **Input Berpasangan & Pemilih Tanggal**:
  - Kolom nama teman berikon `person_outline`.
  - Kolom keterangan berdampingan rapi dengan tombol pemilih tanggal transaksi.
- **Interaksi Edit & Hapus**:
  - Setiap kartu piutang di tab FinTrack kini dapat diketuk langsung untuk diedit atau dihapus melalui ikon tong sampah merah di header dialog.

### 2. 📱 Penataan Ulang Posisi & Tinggi Modal Transaksi Mobile
- **Bebas Tabrakan Panel Atas & Bawah**:
  - `useSafeArea: true` diterapkan pada seluruh pemanggilan `showModalBottomSheet`.
  - Batas tinggi dinamis (`screenHeight - topPadding - 36px`) memastikan ada ruang aman ~36px di bawah status bar atas ponsel.
  - Penambahan bantalan bawah `bottomInset + 14px` mengangkat tombol **"Simpan Pengeluaran"** ke atas sehingga tidak lagi terpotong oleh bilah 3 tombol navigasi Android (*Back / Home / Recents*).
- **Pembukaan Halus Tanpa Keyboard Paksa (`autofocus: false`)**:
  - Modal terbuka dengan tenang dan mulus. Keyboard hanya muncul jika pengguna sengaja mengetuk baris input nominal.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.4.1.apk`** dari daftar **Assets** di halaman rilis.
2. Buka berkas APK di ponsel Anda dan tekan tombol **"Update"**.
3. Aplikasi akan langsung terbarukan ke **v2.4.1**. Seluruh data perkuliahan, jadwal, tugas, dan buku kas FinTrack Anda tetap aman 100%.
