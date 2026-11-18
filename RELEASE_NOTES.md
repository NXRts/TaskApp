# TaskApp v2.4.4 — Penyempurnaan Tata Letak Modal Detail Tugas & Multi-Line Header (Mobile UI Polish)

> **TaskApp v2.4.4** menghadirkan pembaruan kenyamanan antarmuka pada modal **Detail Tugas (Task Detail Modal)**: mengatasi galat *overflow* pada baris metadata/judul matkul panjang dengan *multi-line text wrap* otomatis, serta mengunci posisi tombol **Edit** dan **Hapus** agar tetap kokoh di sudut kanan atas tanpa pernah terdorong keluar layar.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** (`taskapp-release.jks`), sehingga Anda dapat **langsung mengunduh berkas APK dan menekan "Update" tanpa perlu mencopot aplikasi sebelumnya. Seluruh data perkuliahan, tugas, presensi, dan buku kas FinTrack Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.4.4 (Changelog)

### 1. 📋 Desain Ulang Header Modal Detail Tugas (Bebas Overflow)
- **Pelipatan Teks Multi-Line Otomatis (Auto Multi-Line Wrap)**:
  - Menyelesaikan galat *RenderFlex right overflowed by 7.5 pixels* yang terjadi saat mata kuliah memiliki nama panjang (misalnya *English for Academic Purposes (EAP)*) bersanding dengan label jenis tugas (*Tugas Individu / Tugas Kelompok*).
  - Teks metadata kini dibungkus dengan `Expanded` dan `RichText` terpadu, sehingga teks panjang otomatis berlanjut ke baris bawahnya secara proporsional.
- **Posisi Tombol Edit & Hapus Terkunci di Kanan Atas**:
  - Tombol aksi `[ ✏️ Edit ]` dan `[ 🗑️ Hapus ]` kini ditempatkan pada kontainer terpisah yang berlabuh kuat (*pinned*) di pojok kanan atas modal.
  - Tombol tidak akan pernah bergeser, terdorong ke luar layar, atau hilang terpotong berapapun panjangnya judul tugas atau nama mata kuliah.
- **Proteksi Overflow pada Baris Tenggat Waktu**:
  - Tanggal dan jam tenggat waktu (`Tenggat: ...`) kini dilindungi dengan `Expanded` agar tetap aman pada tampilan smartphone dengan resolusi layar kompak.
- **Peningkatan Safe Area Modal**:
  - Memastikan modal terbuka dalam batas area aman layar (`useSafeArea: true`) saat diakses dari kartu tugas beranda maupun tampilan matriks kalender.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.4.4.apk`** dari daftar **Assets** di bawah.
2. Buka berkas APK di ponsel Android Anda dan pilih tombol **"Update"**.
3. Aplikasi akan langsung terbarukan ke **v2.4.4**. Seluruh data tugas, catatan akademik, dan keuangan Anda tetap utuh 100%.
