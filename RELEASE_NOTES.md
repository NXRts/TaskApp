# TaskApp v2.4.0 — FinTrack Mahasiswa: Pengelola Keuangan Mandiri & Uang Harian Anak Kos (Offline Student Financial Hub)

> **TaskApp v2.4.0** menghadirkan modul besar terbaru: **FinTrack Mahasiswa**, solusi buku kas dan pengelola uang harian mandiri yang dirancang khusus untuk mengatasi masalah klasik mahasiswa dan anak kos (*"Kaya di awal bulan, krisis di akhir bulan"*).
>
> Mengusung filosofi **100% Offline-First, Zero-Ad, & Tanpa Login Cloud**, seluruh catatan finansial, dompet, dan amplop anggaran Anda tersimpan aman secara lokal di database Hive NoSQL dan terintegrasi penuh ke dalam sistem pencadangan Full-State JSON Backup TaskApp.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** yang sama, sehingga Anda dapat **langsung mengunduh dan menekan "Update" tanpa perlu menghapus aplikasi dan seluruh data tugas/matkul/jadwal Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.4.0 (Changelog)

### 1. 💡 FinTrack Mahasiswa: Offline Student Financial Hub
- **Kalkulator "Safe-to-Spend Today" (Batas Belanja Aman Harian)**:
  - Otomatis menghitung jatah belanja harian/makan yang aman berdasarkan total saldo bebas dibagi sisa hari kalender di bulan berjalan (tanpa perlu repot konfigurasi manual).
  - Status visual cerdas:
    - 🟢 **Aman**: Pengeluaran harian terkontrol di bawah kuota.
    - 🟡 **Waspada**: Pengeluaran mendekati batas belanja harian.
    - 🔴 **Overbudget**: Peringatan jika melebihi jatah hari ini.
    - ⚪ **Netral**: Status tenang saat saldo awal masih Rp 0 (mencegah peringatan palsu overbudget).
  - Bar progres real-time penyerapan kuota harian.

### 2. ⚡ Pencatatan Cepat & Antarmuka Grid Kompak (< 3 Detik)
- **Grid Kategori 3 Kolom Kompak**: Memilih kategori pengeluaran dan pemasukan dengan satu ketukan tanpa harus menggulir daftar panjang.
- **Kategori Spesifik Kehidupan Kampus & Anak Kos**:
  - *Pengeluaran*: Makan Harian, Bayar Kos, Token Listrik, Galon/Laundry, Bensin, Print/ATK, Buku Materi, Kas Kelas, UKT/SPP, Ngopi, Hiburan, Belanja Online, Lainnya.
  - *Pemasukan*: Kiriman Orang Tua, Beasiswa, Gaji Magang/Part-time, Joki Tugas/Freelance, Hadiah Lomba, Lainnya.
- **Preset Nominal Instan**: Tombol cepat `+5k`, `+10k`, `+20k`, `+50k`, `+100k` untuk mempercepat pengisian nominal.
- **Pengalih Tipe Dinamis**: Pilihan cepat `[ 🔴 Pengeluaran ]` (Rose Red) dan `[ 🟢 Pemasukan ]` (Emerald Sage).

### 3. 💵 Multi-Dompet / Kantong Saldo Terintegrasi
- 3 Kantong saldo proporsional seimbang:
  - 💵 *Tunai di Dompet*
  - 💳 *Rekening Bank / ATM*
  - 📱 *E-Wallet (GoPay, ShopeePay, Dana, OVO)*
- Penyesuaian saldo awal mudah melalui dialog ketuk dompet dan kalkulasi saldo real-time matematis tanpa drift.

### 4. ✉️ Amplop Anggaran Bulanan (Digital Envelope Budgeting)
- 4 Amplop digital berbatas untuk alokasi dana:
  - 🏠 *Kos & Tagihan Tetap*
  - 🍲 *Makan & Kebutuhan Pokok*
  - 📚 *Print & Kebutuhan Kuliah*
  - ☕ *Self-Reward & Nongkrong*
- Indikator penyerapan anggaran dengan bar persentase dan dialog penyesuaian batas anggaran per amplop.

### 5. 🤝 Pencatat Patungan & Piutang Teman (Split Bill & IOU Tracker)
- Pencatatan uang yang ditalangi untuk teman (Piutang) dan pinjaman ke teman (Hutang).
- Ringkasan total piutang yang belum dibayar teman beserta tombol 1-klik **"Tandai Lunas"**.

### 6. 📊 Visualisasi Arus Kas & Analisis Bocor Halus
- Diagram batang proporsi pengeluaran per kategori untuk mendeteksi pemborosan bulanan (seperti jajan kopi berlebih).
- Ringkasan bulanan: Pemasukan, Pengeluaran, dan Net Cash Flow (Surplus/Defisit).

### 7. 🎨 Estetika Modern Editorial & Tata Letak Mobile Rapi
- Tab switcher berdesain matte charcoal dengan kontras tinggi, elevasi bersih, dan indikator aktif kobalt tegas.
- Tombol cepat `+ Catat` di kanan atas layar FinTrack.
- Tombol Floating Action Button (FAB `+`) di navigasi bawah otomatis menyesuaikan: membuka form tambah transaksi ketika di tab Keuangan, dan membuka form tambah tugas ketika di tab lainnya.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.4.0.apk`** dari daftar **Assets** di halaman rilis.
2. Buka berkas APK di ponsel Anda dan tekan tombol **"Update"**.
3. Aplikasi akan langsung terbarukan ke **v2.4.0** dengan menu **Keuangan (FinTrack)** baru di navigasi bawah. Seluruh data perkuliahan, jadwal, dan tugas Anda tetap aman 100%.
