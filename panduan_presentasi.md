# Panduan Presentasi PowerLog

> **Aplikasi Manajemen & Monitoring Penggunaan Listrik Berbasis Flutter**
> Presentasi Tugas Akhir / Tugas Kuliah — Teknologi & Pemrograman Mobile

---

## Daftar Isi Presentasi

1. [Pembukaan & Latar Belakang](#1-pembukaan--latar-belakang)
2. [Tujuan Aplikasi](#2-tujuan-aplikasi)
3. [Tech Stack & Tools](#3-tech-stack--tools)
4. [Demo Aplikasi — Langkah per Langkah](#4-demo-aplikasi--langkah-per-langkah)
5. [Fitur Unggulan](#5-fitur-unggulan)
6. [Arsitektur Kode](#6-arsitektur-kode)
7. [Skenario Pengujian](#7-skenario-pengujian)
8. [Penutup & Sesi Tanya Jawab](#8-penutup--sesi-tanya-jawab)

---

## 1. Pembukaan & Latar Belakang

**Slide 1 — Judul**
- Nama Aplikasi: **PowerLog**
- Logo & Tagline: *"Eco-friendly Electricity Management"*
- Nama Pengembang / NPM / Kelas

**Slide 2 — Latar Belakang Masalah**

| Masalah | Dampak |
|---|---|
| Pengguna token/listrik prabayar kesulitan memantau sisa token secara real-time | Sering kehabisan listrik di malam hari, tidak sempat isi ulang |
| Tidak ada estimasi kapan token akan habis berdasarkan pemakaian aktual | Pembelian token tidak terencana |
| Biaya listrik hanya tercatat dalam Rupiah, padahal beberapa pengguna perlu laporan dalam mata uang global | Sulit membuat laporan biaya untuk keperluan tertentu |
| Tidak ada pengingat otomatis untuk mengecek penggunaan listrik | Sering lupa log penggunaan harian |

**Narasi Presenter:**
> *"PowerLog hadir untuk menjawab kebutuhan monitoring token listrik yang lebih cerdas. Tidak hanya mencatat pemakaian, tetapi juga memberikan estimasi akurat, pengingat otomatis, dan laporan multi-mata uang."*

---

## 2. Tujuan Aplikasi

**Slide 3 — Tujuan & Manfaat**

1. **Memantau sisa token listrik** secara real-time dengan countdown timer
2. **Mengestimasi tanggal habis token** berdasarkan rata-rata pemakaian harian
3. **Menyediakan sistem reminder** — pengingat otomatis berbasis estimasi token + pengingat kustom
4. **Menghitung biaya pemakaian** dengan konfigurasi tarif yang fleksibel
5. **Ekspor laporan bulanan** dalam format PDF/CSV dengan konversi multi-mata uang
6. **Membantu hemat listrik** melalui fitur Eco Saver badge dan streak harian
7. **Menyediakan fitur interaktif** — kompas, senter (shake), game hemat energi, chatbot AI

---

## 3. Tech Stack & Tools

**Slide 4 — Technology Stack**

| Komponen | Teknologi |
|---|---|
| **Framework** | Flutter (SDK ^3.9.2) |
| **Bahasa** | Dart |
| **State Management** | GetX (GetxService, GetxController, routing, DI) |
| **Database Lokal** | sqflite (powerlog.db v5) |
| **Secure Storage** | flutter_secure_storage |
| **AI Chat** | Google Gemini API |
| **Notifikasi** | flutter_local_notifications + timezone |
| **Maps** | OpenStreetMap + geolocator |
| **Ekspor Laporan** | pdf (Dart), open_filex |
| **Sensor** | sensors_plus (magnetometer kompas, accelerometer shake) |

---

## 4. Demo Aplikasi — Langkah per Langkah

### ⚡ Tahap 1: Halaman Awal & Login

**Langkah-langkah di layar:**

```
1. Buka aplikasi → muncul Splash Screen (logo PowerLog)
2. Auto-redirect ke halaman Login
3. Klik "Register" untuk buat akun baru
4. Isi username & password
5. Klik "Register" → otomatis login
6. Atau login dengan akun yang sudah ada
```

**Yang bisa ditekankan:**
- Password di-hash dengan **PBKDF2-SHA256** (bukan MD5/SHA1 biasa)
- Ada opsi **biometric login** (fingerprint/face ID)

**Narasi Presenter:**
> *"Setelah splash screen, pengguna akan diarahkan ke halaman login. Keamanan jadi prioritas — password di-hash menggunakan algoritma PBKDF2-SHA256 dengan salt per-user, dan tersedia autentikasi biometrik untuk akses cepat."*

---

### ⚡ Tahap 2: Halaman Utama (Home Dashboard)

**Langkah-langkah:**

```
1. Setelah login → landing di halaman Home (tab pertama)
2. Lihat tampilan dashboard:
   [Header] — username, jam real-time, shortcut tombol (PLN, Game, Chat)
   [Estimator Card] — sisa token (hari, kWh, Rupiah)
   [Token Date Selector] — pilih tanggal pembelian token
   [Token Input] — isi nominal token (Rp)
   [Confirm Button] — simpan token
```

**Fitur yang bisa didemo:**

| Aksi | Hasil |
|---|---|
| **Shake HP** | Senter menyala (sensor accelerometer) |
| **Lihat kompas** | Heading arah utara real-time (sensor magnetometer) |
| **Tap tombol PLN** | Buka maps — lokasi PLN terdekat |
| **Tap tombol Game** | Buka game wiring puzzle |
| **Tap tombol Chat** | Buka chatbot AI (Gemini) |
| **Isi nominal token** | Estimasi sisa hari langsung ter-update |

**Narasi Presenter:**
> *"Halaman utama adalah pusat kendali PowerLog. Di sini pengguna bisa melihat estimasi sisa token, mengisi token baru, dan mengakses fitur-fitur pendukung seperti kompas, senter via shake, game hemat energi, serta chatbot AI untuk bertanya seputar listrik."*

---

### ⚡ Tahap 3: Input Token & Estimasi Real-Time

**Langkah-langkah:**

```
1. Tap tanggal (Token Date Selector) — pilih hari ini
2. Isi nominal token Rp50.000 di field
3. Tap "Confirm Token"
4. Lihat Estimator Card berubah:
   - Sisa hari: ~XX hari (berkurang real-time tiap menit)
   - Sisa kWh: terkonversi sesuai tarif
   - Status: "Active" / "Expired" (otomatis)
```

**Yang bisa ditekankan:**
- Countdown **real-time** — timer tick tiap 1 menit
- Status otomatis berubah jadi **"Expired"** saat token habis
- Estimasi berdasarkan **rata-rata pemakaian harian** dari log yang pernah dicatat

---

### ⚡ Tahap 4: Input Log Pemakaian Harian

**Langkah-langkah:**

```
1. Di halaman Home, tap "Log Usage" / input pemakaian
2. Isi pemakaian kWh (misal: 4.2 kWh)
3. Simpan
4. Data otomatis masuk ke database
5. Lihat estimasi token menyesuaikan
```

**Yang bisa ditekankan:**
- Setiap log harian **menyesuaikan estimasi token** secara dinamis
- Basis data untuk perhitungan **streak** dan **Eco Saver badge**

---

### ⚡ Tahap 5: Halaman Analytics

**Langkah-langkah:**

```
1. Tap tab "Analytics" (bottom nav)
2. Lihat:
   [Token Info] — nominal, tanggal beli, estimasi habis
   [Token Log] — histori semua token yang pernah di-input
   [Cost Breakdown] — grafik biaya pemakaian
   [Estimated End Date] — tanggal estimasi habis token
3. Tap "Convert ↔" untuk lihat konversi ke mata uang lain
4. Pilih EUR, USD, atau mata uang lain di dropdown
```

**Yang bisa ditekankan:**
- Estimasi **real-time** berkurang tiap menit
- Histori token lengkap dengan tanggal input
- Konversi multi-mata uang dengan **kurs live** (CDN fallback)

---

### ⚡ Tahap 6: Halaman Appliances

**Langkah-langkah:**

```
1. Tap tab "Appliances"
2. Lihat daftar alat elektronik (jika sudah ada)
3. Tap "+" untuk tambah alat baru
4. Isi: Nama alat, Watt, Jam pemakaian/hari
5. Simpan → lihat prediksi pemakaian bulanan
```

**Yang bisa ditekankan:**
- Perhitungan **otomatis** konsumsi kWh harian & bulanan
- Membantu memperkirakan biaya listrik per alat
- Data dipakai untuk **prediksi di laporan PDF**

---

### ⚡ Tahap 7: Halaman Profile & Pengaturan

**Langkah-langkah — Bagian 1 (Umum):**

```
1. Tap tab "Profile"
2. Lihat:
   [Profile Card] — username, avatar
   [Achievements] — streak badge, eco saver badge
   [Settings] — biometric, notification, dll.
```

**Langkah-langkah — Bagian 2 (Reminder):**

```
3. Nyalakan "Auto Reminder (Token-based)"
   → Lihat subtitle: "Remind at Mon, 15 Jun 2026 (auto)"
   → Jika belum ada token: "Daily at 20:00 (auto)"
4. Nyalakan "Custom Reminder"
   → Tap "Custom Reminder Time"
   → Pilih tanggal & jam
   → Notifikasi akan muncul sesuai jadwal
```

**Langkah-langkah — Bagian 3 (Currency):**

```
5. Tap "Currency Preferences"
   → Loading cepat (parallel request, ~1-2 detik)
   → Centang EUR, USD, GBP, JPY, dll.
   → Kembali, pilih "Default Currency" (dropdown)
6. Generate report:
   → Tap "Export PDF"
   → File terbuka dengan mata uang yang dipilih
```

**Langkah-langkah — Bagian 4 (Tariff & Timezone):**

```
7. Scroll ke "Tariff Settings"
   → Pilih golongan tarif (R1-450, R1-900, R1-1300, dll.)
   → Atur pajak (default 10%)
   → Biaya otomatis dihitung ulang
8. Pilih Timezone (WIB/WITA/WIT/London)
```

**Langkah-langkah — Bagian 5 (Achievement Simulator):**

```
9. Scroll ke "Achievement Simulator"
10. Tap chip "Eco Saver" → badge Eco Saver ON
11. Tap chip "7-Day Streak" → streak jadi 7 hari
12. Tap chip "Heavy Usage" → eco saver hilang
13. Tap chip "Clear Logs" → reset
```

**Narasi Presenter:**
> *"Halaman profil adalah pusat pengaturan. Mulai dari pengingat otomatis berbasis estimasi token, reminder kustom, preferensi mata uang dengan kurs live, hingga simulator pencapaian untuk testing. Dan untuk teman-teman yang ingin lihat (EUR/GBP) dalam laporan PDF, cukup ganti default currency di sini."*

---

### ⚡ Tahap 8: Ekspor Laporan PDF

**Langkah-langkah:**

```
1. Di Profile, tap "Export PDF"
2. File PDF tersimpan & terbuka otomatis
3. Lihat:
   [Header] — PowerLog, username, tanggal
   [Summary] — Total kWh, Total Estimated Cost
   [Appliance Breakdown] — tabel alat elektronik
   [Monthly Prediction] — prediksi bulanan
4. Biaya ditampilkan dalam mata uang yang dipilih
```

**Yang bisa ditekankan:**
- **Multi-currency**: biaya dikonversi sesuai default currency
- Simbol mata uang eksplisit (€, $, £, ¥, Rp, dll.)
- Prediksi 30 hari berdasarkan data appliances

---

### ⚡ Tahap 9: Fitur Interaktif Lainnya

**A. Game Hemat Energi (Wiring Puzzle)**

```
1. Dari Home → tap "Game" di header (atau drawer)
2. Puzzle menyambungkan kabel dengan memutar tile
3. Semakin sulit level → semakin banyak langkah acak
4. Timer & hint terbatas
```

**B. Chatbot AI (Gemini)**

```
1. Tap tombol Chat
2. Ketik pertanyaan, misal: "How can I reduce my electricity bill?"
3. AI menjawab dengan saran hemat energi
4. Bisa pakai Bahasa Indonesia atau Inggris
```

**C. Nearest PLN**

```
1. Tap tombol PLN
2. Lokasi PLN terdekat ditampilkan di peta
3. Bisa buka Google Maps untuk navigasi
```

**D. Kompas & Senter**

```
1. Pegang HP — kompas berfungsi (magnetometer)
2. Shake HP — senter menyala (accelerometer)
```

---

## 5. Fitur Unggulan

**Slide — Fitur Unggulan untuk PPT**

| # | Fitur | Keunggulan |
|---|---|---|
| 1 | **Estimator Real-Time** | Countdown presisi per menit, status expired otomatis |
| 2 | **Multi-Mata Uang** | Kurs live dari 5 CDN fallback, cache 24 jam, simbol eksplisit |
| 3 | **Auto Reminder (Token-based)** | Notifikasi otomatis di tanggal estimasi habis token |
| 4 | **Custom Reminder** | Pengguna bisa tentukan sendiri waktu notifikasi |
| 5 | **Pengingat Cerdas** | Prioritaskan token reminder, fallback ke daily reminder |
| 6 | **Eco Achievement** | Badge Eco Saver + 7-Day Streak dengan simulator testing |
| 7 | **Laporan PDF + CSV** | Multi-currency, breakdown per alat, prediksi bulanan |
| 8 | **Chatbot AI** | Integrasi Google Gemini untuk konsultasi listrik |
| 9 | **Game Wiring Puzzle** | Edukasi hemat energi lewat puzzle interaktif |
| 10 | **Multi-Platform** | Berbasis Flutter, bisa jalan di Android & iOS |

---

## 6. Arsitektur Kode

**Slide — Arsitektur untuk PPT**

### Struktur Project

```
lib/
├── main.dart                         # Entry point, inisialisasi GetX services
├── app/
│   ├── config/app_config.dart        # Konfigurasi API key, dll.
│   ├── routes/app_pages.dart         # Routing GetX pages
│   ├── routes/app_routes.dart        # Nama routes (part file)
│   ├── theme/app_colors.dart         # Warna tema dark
│   └── theme/app_theme.dart          # Dark theme (no light theme)
├── data/
│   ├── local/database_helper.dart    # sqflite (DB v5, migrasi otomatis)
│   ├── models/                       # UserModel, LogModel, TokenModel, dll.
│   ├── repositories/                 # AuthRepository, LogRepository, dll.
│   └── api/api_service.dart          # API service
├── services/                         # NotificationService, ExchangeRateService, dll.
├── modules/                          # Setiap fitur punya: bindings/, controllers/, views/
│   ├── auth/ (login, register)
│   ├── splash/
│   ├── dashboard/ (bottom nav host)
│   ├── home/ (main dashboard)
│   ├── analytics/ (chart, estimasi)
│   ├── appliances/ (manajemen alat)
│   ├── profile/ (settings, achievements)
│   ├── feedback/
│   ├── nearest_pln/ (lokasi PLN)
│   ├── chat/ (Gemini AI)
│   └── game/ (wiring puzzle)
└── utils/                            # PasswordHasher, CurrencyNames, dll.
```

### Pola Desain

| Konsep | Implementasi |
|---|---|
| **State Management** | GetX — `GetxController` + `GetxService` + reactive `.obs` |
| **Dependency Injection** | `Get.putAsync()`, `Get.find()`, `Get.lazyPut()` |
| **Routing** | Get Pages dengan named routes, part file |
| **Repository Pattern** | Repository layer memisahkan akses data dari controller |
| **Service Layer** | Service untuk notifikasi, exchange rate, tariff, PDF, session |

### Database (sqflite v5)

```
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│  tableUsers   │     │  tableLogs    │     │  tableTokens  │
├───────────────┤     ├───────────────┤     ├───────────────┤
│ id            │     │ id            │     │ id            │
│ username      │     │ date          │     │ date          │
│ password_hash │     │ kwh_usage     │     │ input_at      │
│ password_salt │     │ estimated_cost│     │ amount_idr    │
│ preferences   │     │ created_at    │     │ plan_code     │
└───────────────┘     └───────────────┘     │ rate_per_kwh  │
                                            │ tax_percent   │
┌───────────────┐                            │ include_tax   │
│ tableAppliances│                           │ fixed_fee     │
├───────────────┤                            │ include_fixed │
│ id            │                            └───────────────┘
│ name          │
│ wattage       │     ┌───────────────────┐
│ hours_per_day │     │ flutter_secure_   │
│ created_at    │     │ storage (session) │
└───────────────┘     ├───────────────────┤
                      │ notification pref │
                      │ biometric pref    │
                      │ currency pref     │
                      │ cache exchange    │
                      │ timezone, tariff  │
                      └───────────────────┘
```

---

## 7. Skenario Pengujian

### A. Skenario Manual Testing (Lengkap)

| # | Skenario | Langkah | Expected |
|---|---|---|---|
| 1 | **Register akun baru** | Buka app → Register → isi username & pass | Login otomatis setelah register |
| 2 | **Login biometrik** | Logout → Login → pilih biometric | Fingerprint/face terverifikasi |
| 3 | **Input token** | Home → isi nominal Rp50.000 → Confirm | Estimasi muncul, countdown berjalan |
| 4 | **Log pemakaian** | Home → input kWh → simpan | Estimasi sisa hari menyesuaikan |
| 5 | **Auto Reminder ON** | Profile → toggle Auto Reminder | Subtitle: estimasi tanggal habis token |
| 6 | **Custom Reminder** | Profile → toggle + set waktu 2 menit | Notifikasi muncul dalam 2 menit |
| 7 | **Ganti currency ke EUR** | Profile → Currency Preferences → centang EUR → set default | Angka pakai simbol € |
| 8 | **Generate PDF** | Profile → Export PDF | File PDF terbuka dengan € |
| 9 | **Eco Saver badge** | Profile → Achievement Simulator → tap "Eco Saver" | Badge Eco Saver ON |
| 10 | **7-Day Streak** | Profile → tap "7-Day Streak" | Streak count = 7 |
| 11 | **Chat AI** | Home → Chat → tanya "cara hemat listrik" | AI menjawab |
| 12 | **Game puzzle** | Home → Game → mainkan | Puzzle bisa dimainkan |
| 13 | **Nearest PLN** | Home → PLN → izinkan lokasi | Peta muncul dengan lokasi PLN |
| 14 | **Shake senter** | Shake HP | Senter menyala |
| 15 | **Ganti timezone** | Profile → pilih WITA/WIT | Waktu & notifikasi menyesuaikan |

### B. Unit Tests (Ada 3 file)

```
flutter test
├── tariff_service_test.dart   — test konfigurasi tarif
├── streak_test.dart            — test kalkulasi streak
└── widget_test.dart            — smoke test (butuh Gemini key)
```

### C. Code Analysis

```
flutter analyze
→ No issues found (flutter_lints standard rules)
```

---

## 8. Penutup & Sesi Tanya Jawab

**Slide — Kesimpulan**

> **PowerLog** adalah solusi monitoring token listrik yang:
> - ✅ **Akurat** — estimasi real-time dengan countdown per menit
> - ✅ **Cerdas** — reminder otomatis berbasis estimasi token
> - ✅ **Fleksibel** — multi-mata uang, tarif adjustable, timezone global
> - ✅ **Interaktif** — chatbot AI, game puzzle, kompas, senter
> - ✅ **Lengkap** — laporan PDF/CSV, achievement, simulator testing

**Slide — Saran Pengembangan ke Depan**
- Integrasi Firebase untuk backup data cloud
- Notifikasi push via FCM
- Widget Android untuk quick-view di home screen
- Apple Watch / Wear OS companion
- Integrasi smart home (IoT) langsung dengan meteran listrik

**Narasi Presenter (Penutup):**
> *"Demikian presentasi PowerLog — aplikasi monitoring listrik prabayar yang cerdas. Dengan estimasi real-time, pengingat otomatis, dan laporan multi-mata uang, PowerLog membantu pengguna mengelola pemakaian listrik lebih efisien. Terima kasih dan saya siap menerima pertanyaan."*

---

## Tips Tambahan untuk Presentasi

### Persiapan Demo (Backup Plan)
1. **Siapkan emulator atau HP fisik** dengan aplikasi sudah ter-install
2. **Siapkan screenshot/video** sebagai backup jika demo gagal
3. **Pastikan koneksi internet stabil** untuk fitur Gemini Chat & kurs mata uang
4. **Simpan Gemini API key** di environment variable atau dart-define
5. **Siapkan akun demo** (username: `demo`, password: `demo123`) untuk akses cepat

### Poin yang Sering Ditanyakan (Q&A Prep)

| Pertanyaan | Jawaban |
|---|---|
| Kenapa pilih GetX, bukan BLoC? | GetX lebih ringan untuk medium app, tanpa boilerplate, cocok untuk project individu |
| Database pake apa? Kenapa bukan Firebase? | sqflite lokal agar bisa offline penuh — keamanan data lebih terjamin tanpa cloud |
| Gimana akurasi estimasi token? | Estimasi berdasarkan rata-rata kWh harian dari log pemakaian aktual yang di-input user |
| Kurs mata uang dari mana? | Dari 5 CDN publik (jsdelivr, github, currency-api), auto-fallback jika satu sumber mati |
| Kenapa dark theme doang? | Fokus untuk penggunaan malam hari di dalam ruangan — lebih nyaman di mata |
| Bisa jalan di iOS? | Ya — Flutter cross-platform, sudah di-test di Android & iOS |

### Alokasi Waktu Presentasi (15 Menit)

| Durasi | Segmen |
|---|---|
| 2 menit | Pembukaan & latar belakang |
| 1 menit | Tech stack |
| 8 menit | Live demo (poin 4a → 4i) |
| 2 menit | Arsitektur & kode |
| 2 menit | Q&A |

---

*Dokumen ini disusun untuk keperluan presentasi — powerlog v2.0*