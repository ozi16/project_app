# Teknisi AAG

Aplikasi mobile Flutter untuk teknisi pest control **AAG / Atrindo**.

Teknisi login, melihat jadwal kunjungan klien hari ini, absen (check-in / check-out) dengan foto + GPS, lalu mengisi laporan lapangan.

Backend **tidak ada di repo ini**. App hanya konsumsi API `https://report.atrindo.network/api`.

| Item | Nilai |
|---|---|
| Versi | `1.0.0+1` |
| Package Android | `com.example.teknisi_aag` (masih ID contoh) |
| Pengguna | Teknisi (role disimpan di Hive setelah login) |

Untuk onboarding lengkap (alur kerja, endpoint, jebakan kode), baca [HANDOFF.md](HANDOFF.md).

---

## Fitur

- Login teknisi (email + password)
- Beranda: kartu progres tugas hari ini, grid menu, daftar jadwal
- Check-in / check-out dengan kamera + GPS
- Laporan tugas 4 langkah:
  1. Dokumentasi treatment
  2. Dokumentasi temuan & rekomendasi
  3. Checklist area / pest / trap
  4. Chemical yang dipakai
- Tanda tangan klien + foto stempel
- Request chemical (keranjang + history approval)
- History kunjungan, daftar klien, absensi, scan QR
- Kalender jadwal, generator PDF lokal, profil + logout

Perilaku beranda tergantung field `job` dari API login:

| Nilai `job` | Mode | Perilaku |
|---|---|---|
| `0` atau `1` | Visit | Alur lengkap: check-in → 4 laporan → tanda tangan → check-out |
| `2` (default jika kosong) | Standby | Absen Check In / Check Out tanpa alur visit lengkap |

---

## Stack

| Item | Nilai |
|---|---|
| Framework | Flutter |
| Dart SDK | `^3.8.1` |
| State | StatefulWidget |
| HTTP | `http` |
| Local storage | Hive |
| Kamera | `image_picker`, `camera` |
| QR | `mobile_scanner` |
| GPS | `geolocator` + `geocoding` |
| Peta | `flutter_map` (OpenStreetMap) |
| Tanda tangan | `syncfusion_flutter_signaturepad` |
| Kalender | `table_calendar` |
| PDF | `pdf` + `printing` |

---

## Requirement

1. Flutter SDK yang kompatibel dengan Dart 3.8.1
2. Android Studio / SDK (untuk Android)
3. Device atau emulator dengan kamera + GPS untuk tes absen

```bash
flutter doctor -v
flutter --version
```

iOS belum siap production: permission kamera dan lokasi di `Info.plist` belum lengkap.

---

## Cara menjalankan

Di folder root proyek (`teknisi_aag`):

```bash
flutter pub get
flutter run
```

Pilih device Android. Login memakai akun teknisi yang valid di server Atrindo (akun tidak ada di repo).

Lihat mockup UI (HTML, bukan Flutter):

```bash
# buka file ini di browser
mockup/index.html
```

Screenshot mockup ada di `mockup/images/`.

---

## Struktur folder

```
teknisi_aag/
├── lib/
│   ├── main.dart                 # entry: init Hive + routes
│   ├── loginPage.dart            # login
│   ├── homepage.dart             # shell + 5 tab bottom nav
│   ├── services/api_service.dart # satu-satunya file API yang dipakai
│   ├── constants/                # warna, ukuran, text style
│   ├── BottomNavbar/             # beranda, jadwal, pesan, profil
│   ├── BerandaPage/              # check-in, laporan tugas, QR, chemical
│   └── Page/editProfile.dart
├── assets/icons/
├── mockup/                       # HTML mockup + screenshot
├── android/  ios/  web/
└── pubspec.yaml
```

API yang benar: `lib/services/api_service.dart`.  
File `lib/BerandaPage/api_service.dart` kosong dan tidak dipakai.

---

## Navigasi

```
LoginPage
  └── homePage  (5 tab)
        ├── [0] Beranda
        │      ├── History Client
        │      ├── My Client
        │      ├── Data Chemical          → keranjang request
        │      ├── Absensi
        │      ├── Scan QR
        │      ├── Notifikasi             → dummy, belum API
        │      └── Kartu jadwal hari ini
        │             ├── Check-in (kamera + GPS)
        │             ├── Detail Tugas (4 laporan)
        │             ├── Tanda tangan + stempel
        │             └── Check-out (kamera + GPS)
        ├── [1] Jadwal                    → kalender pekerjaan
        ├── [2] Request Chemical          → history + status approval
        ├── [3] Pesan                     → generator PDF lokal
        └── [4] Akun / Profile            → data + logout
```

---

## Alur kerja utama (Visit)

Sumber status tombol: `GET /task/active-visit`.

```
Mulai
  → Check-in (foto + lat/long)     POST /absen/store
  → Server buat task_id
  → Detail Tugas
       1. POST /doc-treat          (TREATMENT)
       2. POST /doc-temuan         (AKSES)
       3. POST /checklist          (CHECKLIST)
       4. POST /chemical-used      (CHEMICAL)
  → SignaturePage                  POST /task/sign-in
  → Check-out                      POST /absen/store (+ task_id)
```

File kunci alur: `lib/BerandaPage/TugasTeknisiPage/detailtask.dart` (`handleBerandaScheduleTap`).

---

## API

Base: `https://report.atrindo.network/api`  
Header: `Authorization: Bearer {token}`, `Accept: application/json`  
Token diambil dari Hive box `loginBox`.

Ringkasan endpoint ada di [HANDOFF.md](HANDOFF.md#9-api--daftar-endpoint). Implementasi lengkap di `lib/services/api_service.dart`.

---

## Penyimpanan lokal (Hive)

| Box | Isi |
|---|---|
| `loginBox` | Sesi user, token, cache client selesai hari ini |
| `checkinBox` | Log check-in lokal |
| `dokumentasitreatmentBox` | Draft foto treatment |
| `dokumentasirekomendasiBox` | Draft foto temuan |
| `jadwalBox` | Cache jadwal hari ini |

---

## Hal yang perlu diketahui

1. Session login belum persist — setiap buka app user harus login ulang.
2. Application ID masih `com.example.teknisi_aag`.
3. Release Android masih sign debug.
4. iOS belum punya permission kamera / lokasi.
5. Notifikasi masih dummy; beberapa halaman QR / edit profil / lapor bug belum tersambung API.

---

## Mockup & desain

- Warna: `lib/constants/app__Colors.dart` — primary `#0051FF`
- Ikon: `assets/icons/`
- Referensi visual: `mockup/index.html` dan `mockup/images/`

Kalau mengubah UI, cocokkan dulu dengan mockup beranda / detail tugas / history.
