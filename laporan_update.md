# PowerLog - Ringkasan Pembaruan & Fitur Baru
*Dokumen komparasi versi lokal (Terbaru) vs Remote GitHub Repository (https://github.com/sebuahdelusi/PowerLog)*

Dokumen ini disusun untuk memudahkan Anda memperbarui **Laporan Tugas Akhir/Tugas Kuliah** dan slide **PPT Presentasi**. Semua perubahan di bawah ini dikelompokkan secara terstruktur berdasarkan komponen teknis, database, logika bisnis, dan estetika UI.

---

## 1. Ringkasan Eksekutif (Executive Summary)
Pembaruan pada aplikasi **PowerLog** berfokus pada peningkatan akurasi estimasi, fitur multi-mata uang dinamis, sistem pengingat otomatis yang lebih cerdas, dan peningkatan kualitas kode melalui pemisahan komponen UI (*Modular UI*). 

Selain itu, ditambahkan pula **Achievement Simulator** untuk mempermudah pengujian fitur pencapaian tanpa harus menunggu data penggunaan riil selama berhari-hari.

---

## 2. Perubahan Skema & Struktur Database (`sqflite`)
Untuk mendukung pelacakan waktu yang presisi secara real-time, skema penyimpanan data lokal mengalami pembaruan:

*   **Peningkatan Versi Database:** Versi database (`_dbVersion`) ditingkatkan dari **4 menjadi 5** di `database_helper.dart`.
*   **Kolom Baru pada Tabel Token (`tableTokens`):**
    *   Ditambahkan kolom `input_at` (`TEXT`) untuk merekam timestamp presisi (tanggal & jam) saat user mengonfirmasi pembelian token.
    *   *Query* data token (`getAllTokens` dan `getLatestToken`) kini diurutkan berdasarkan `input_at DESC, token_date DESC` untuk memastikan estimasi didasarkan pada token aktif yang paling baru dimasukkan.
*   **Migrasi Data Otomatis:** Menambahkan fungsi migrasi di `onUpgrade` dari versi 4 ke 5, secara otomatis mengisi nilai `input_at` dengan `token_date` untuk data token lama agar aplikasi tidak crash dan data tetap kompatibel.

---

## 3. Fitur Utama Baru & Logika Bisnis (Business Logic)

### A. Sistem Multi-Mata Uang & Konversi Kurs Real-Time
*   **Layanan Baru (`ExchangeRateService`):**
    *   Membaca kurs mata uang riil dari 5 fallback API publik berbasis CDN (menjamin kestabilan saat koneksi salah satu API terganggu).
    *   Memiliki mekanisme penyimpanan cache lokal selama 24 jam (`_cacheTtl = 24 hours`) di secure storage untuk menghemat kuota internet dan menjaga kecepatan loading.
*   **Integrasi Session (`SessionService`):**
    *   Ditambahkan penyimpanan preferensi daftar mata uang pilihan (`currency_selected`), mata uang default (`currency_default`), cache kurs, dan cache daftar kode mata uang secara terenkripsi.
*   **Konversi Laporan PDF (`PdfService`):**
    *   Fungsi ekspor PDF diperbarui untuk menerima parameter `currencyCode` dan `currencyRate`. Laporan bulanan otomatis mengonversi angka biaya estimasi dari IDR (Rupiah) ke mata uang pilihan (seperti USD, EUR, GBP) secara instan.

### B. Estimator Token Real-Time & Jam Sinkronisasi Aktif
*   **Dynamic Countdown Timer:**
    *   Ditambahkan jam aktif (`_clockTimer` berbasis `Timer.periodic`) di `HomeController` dan `AnalyticsController` yang melakukan *tick* setiap 1 menit sekali.
    *   Estimasi sisa hari token kini tidak bersifat statis, melainkan berkurang secara presisi berdasarkan menit yang telah terlewati sejak waktu input token (`input_at`).
*   **Status Expired:** Jika sisa waktu token telah habis melewati waktu saat ini, tampilan status otomatis berubah menjadi **"Expired"** menggantikan sisa durasi.
*   **Pencegahan Pengingat Lampau:** Notifikasi pengingat otomatis (`_syncAutoReminder`) kini memiliki validasi untuk tidak menjadwalkan notifikasi jika waktu habis token sudah terlewati.

### C. Eco-Achievements Simulator (Fitur Pengujian/Verifikasi)
*   **Pengenalan Fitur:** Mengatasi masalah di mana tabel `logs` penggunaan listrik harian selalu kosong karena tidak adanya input manual data log.
*   **Mekanisme Simulator (`seedMockLogs`):**
    *   Menambahkan menu simulator pengujian di Profile Controller untuk memicu 4 skenario data palsu:
        1.  **Eco Saver:** Menambahkan 1 log penggunaan rendah (`3.2 kWh` < 5.0 kWh) untuk hari ini.
        2.  **7-Day Streak:** Menambahkan 7 log berurutan dari hari ini hingga 6 hari lalu untuk menguji algoritma *streak* harian.
        3.  **Heavy Log:** Menambahkan 1 log penggunaan tinggi (`7.5 kWh`) untuk menguji penguncian lencana kembali.
        4.  **Reset:** Mengosongkan data log.
    *   Setiap skenario langsung memperbarui status badge pencapaian secara reaktif menggunakan GetX.

---

## 4. Pembaruan Antarmuka (Aesthetic & UI Refinement)

### A. Restrukturisasi Modular UI
Tampilan kode layout diperbaiki secara signifikan dengan membagi kelas UI raksasa menjadi widget-widget kecil yang mandiri (*reusable components*):
*   **Home View (`home_view.dart`):**
    *   Dipecah menjadi `_GyroHeader`, `_EstimatorCard`, `_TokenDateSelector`, `_ActiveEstimatorView`, `_TokenInputView`, dan `_ApplianceOverview`.
    *   Menambahkan tombol akses cepat PLN Terdekat (`PLN`) dan Minigame Hemat Energi (`Game`) di bagian header.
    *   Perbaikan constraint *bottom padding* dinamis menggunakan `MediaQuery` agar tombol konfirmasi token tidak terpotong saat keyboard muncul atau pada perangkat berponi.
*   **Profile View (`profile_view.dart`):**
    *   Dipecah menjadi `_ProfileCard`, `_AchievementsSection`, `_SettingsSection`, `_CompassSection`, dan `_TimezoneSection`.
    *   Menambahkan **Achievement Simulator (Testing)** di bawah badge pencapaian berupa barisan chip interaktif berwarna harmonis.

### B. Opsi Preferensi Baru di Menu Setelan (Settings)
*   **Currency Preferences:** Menambahkan sheet pop-up interaktif untuk mencentang mata uang asing yang ingin dipantau.
*   **Default Currency Dropdown:** Menambahkan dropdown pilihan mata uang utama yang akan digunakan di Dashboard Analytics dan ekspor PDF.

---

## 5. Daftar File yang Diubah & Ringkasan Perubahan Kode
Berikut detail perubahan pada 12 file aplikasi:

| Nama File | Status | Deskripsi Perubahan Utama |
| :--- | :--- | :--- |
| **`lib/services/exchange_rate_service.dart`** | **[NEW]** | Layanan konversi kurs real-time, caching secure storage 24 jam, dan format simbol mata uang internasional. |
| **`lib/data/local/database_helper.dart`** | **[MODIFY]** | Naik ke DB Version 5; penambahan kolom `input_at` pada tabel token dan modifikasi query pengurutan. |
| **`lib/data/models/token_model.dart`** | **[MODIFY]** | Penambahan field `inputAt` pada entitas model data token untuk konversi JSON/Map database. |
| **`lib/main.dart`** | **[MODIFY]** | Inisialisasi asinkron GetX untuk layanan baru `ExchangeRateService`. |
| **`lib/services/session_service.dart`** | **[MODIFY]** | Penambahan metode penyimpanan secure preferences enkripsi untuk data preferensi mata uang dan cache API. |
| **`lib/services/pdf_service.dart`** | **[MODIFY]** | Integrasi konversi biaya berbasis kurs internasional terpilih pada laporan bulanan berformat PDF. |
| **`lib/modules/home/controllers/home_controller.dart`** | **[MODIFY]** | Implementasi timer 1-menit untuk kalkulasi `remainingDays` dan rekam timestamp `inputAt` saat simpan token. |
| **`lib/modules/home/views/home_view.dart`** | **[MODIFY]** | Modularisasi total komponen UI; penambahan tombol PLN & Game, perbaikan button cutoff. |
| **`lib/modules/analytics/controllers/analytics_controller.dart`** | **[MODIFY]** | Sinkronisasi sisa durasi real-time dan pengambilan histori riwayat seluruh token. |
| **`lib/modules/analytics/views/analytics_view.dart`** | **[MODIFY]** | Penambahan widget **Token Log** (histori token) dan tombol konversi mata uang dinamis via BottomSheet. |
| **`lib/modules/profile/controllers/profile_controller.dart`** | **[MODIFY]** | Handler UI preferensi mata uang baru, interaksi export PDF berbasis mata uang dinamis, dan fungsi simulator data log. |
| **`lib/modules/profile/views/profile_view.dart`** | **[MODIFY]** | Implementasi setelan preferensi mata uang di UI, dropdown default, dan barisan tombol Achievement Simulator. |

---

## 6. Bahan untuk PPT Presentasi / Slide Kuliah
Anda dapat membagi slide presentasi berdasarkan materi pembaruan ini:

*   **Slide 1: Latar Belakang Masalah** (Akurasi estimasi token yang sebelumnya statis hanya berdasarkan hari beli, belum presisi jam-menit; Biaya listrik masih terbatas pada Rupiah, belum fleksibel untuk konversi laporan bagi user yang membutuhkan pemantauan biaya dalam mata uang global).
*   **Slide 2: Solusi Baru - Sistem Multi-Mata Uang & Real-time Countdown** (Arsitektur `ExchangeRateService` dengan CDN fallback & local cache 24 jam; Skema database naik ke versi 5 dengan timestamp `input_at`).
*   **Slide 3: Peningkatan Struktur Kode (Modular UI)** (Memecah view raksasa menjadi widget terpisah untuk performa rendering Flutter yang lebih ringan dan kode yang mudah dimaintain/clean code).
*   **Slide 4: Simulasi Pengujian (Achievement Simulator)** (Solusi kreatif untuk memverifikasi pencapaian Eco Saver & Streak menggunakan data simulasi lokal sqflite secara instan).
