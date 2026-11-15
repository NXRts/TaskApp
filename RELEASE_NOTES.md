# TaskApp v2.3.8 — Fix Resource Shrinking & Guaranteed Native Notification Delivery

> **TaskApp v2.3.8** mengatasi tuntas galat `PlatformException(invalid_icon)` yang disebabkan oleh proses *Resource Shrinking & Optimization* pada kompilasi rilis Android Gradle Plugin (AGP). Aset notifikasi kini dilindungi secara permanen di tabel sumber daya sistem (`resources.arsc`) melalui deklarasi manifes, aturan retensi R8/AAPT2 (`keep.xml`), dan penonaktifan *resource shrinking*.
>
> Pembaruan ini ditandatangani dengan **Keystore Resmi Permanen** yang sama, sehingga Anda dapat **langsung mengunduh dan menekan "Update" tanpa perlu menghapus aplikasi dan seluruh data Anda tetap aman 100%**.

---

## ✨ Apa yang Baru di Versi 2.3.8 (Changelog)

### 1. 🛡️ Solusi Tuntas Galat `invalid_icon` pada Berkas Rilis APK
- **Akar Masalah Teridentifikasi & Teratasi**: Pada versi rilis (`flutter build apk --release`), Android Gradle Plugin (AGP) secara otomatis membuang (*strip*) sumber daya gambar yang tidak dipanggil secara eksplisit di berkas Java/Manifes dari tabel `resources.arsc`. Akibatnya fungsi `context.getResources().getIdentifier("app_icon", "drawable", ...)` menghasilkan nilai `0`.
- **Perlindungan Aset Permanen**:
  - Menambahkan deklarasi `<meta-data android:resource="@drawable/app_icon" />` di `AndroidManifest.xml`.
  - Mendaftarkan aturan retensi AAPT2 `res/raw/keep.xml` (`tools:keep="@drawable/app_icon,@drawable/ic_notification,@raw/task_alarm"`).
  - Menetapkan `isShrinkResources = false` dan `isMinifyEnabled = false` pada konfigurasi build rilis Gradle.
  - Memastikan `app_icon`, `ic_notification`, dan `task_alarm` hadir 100% di tabel biner `resources.arsc` pada APK rilis.

---

## 📲 Panduan Instalasi & Pembaruan

1. Unduh berkas **`TaskApp-v2.3.8.apk`** dari daftar **Assets** di halaman rilis.
2. Buka berkas APK dan tekan tombol **"Update"**.
3. Buka **Profil & Pengaturan** -> tekan **"Tes H-1"** atau **"Tes H-3 Jam"**. Notifikasi resmi akan langsung melayang di atas layar dan menetap di bilah status / panel kontrol HP Anda tanpa ada galat!

---

### 📦 Berkas Unduhan
- **`TaskApp-v2.3.8.apk`** — Berkas rilis resmi mandiri siap pasang di semua ponsel Android (Android 7.0 / API 24 ke atas).
- **`app-release.apk`** — Berkas biner rilis Flutter standar.
