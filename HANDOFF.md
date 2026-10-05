# Outline Handoff — Aplikasi Teknisi AAG

Dokumen ini untuk orang yang baru menerima proyek. Baca dari atas ke bawah. Bagian 1–4 cukup untuk mulai jalan. Bagian 5–10 untuk memahami alur kerja. Bagian 11–12 untuk tahu apa yang masih mentah.

---

## 1. Proyek ini apa?

Aplikasi **mobile Flutter** untuk teknisi pest control **AAG / Atrindo**.

Teknisi login, melihat jadwal kunjungan klien hari ini, absen (check-in / check-out) dengan foto + GPS, lalu mengisi laporan lapangan:

1. Dokumentasi treatment
2. Dokumentasi temuan & rekomendasi
3. Checklist area / pest / trap
4. Chemical yang dipakai
5. Tanda tangan klien + stempel foto

Selain itu ada request chemical (keranjang barang), history kunjungan, daftar klien, scan QR, dan profil.

Backend **bukan bagian repo ini**. App hanya konsumsi API:

| Server | URL | Dipakai untuk |
|---|---|---|
| Report API | `https://report.atrindo.network/api` | Hampir semua fitur (login, jadwal, absen, task, chemical) |
| App API | `https://app.atrindo.network/api` | Dideklarasikan di kode, **belum dipakai** |

Versi app: `1.0.0+1`  
Package Android: `com.example.teknisi_aag` (masih contoh, belum production ID)

---

## 2. Siapa penggunanya?

Hanya **teknisi**. Role disimpan di Hive setelah login (`level_label`).

Perilaku layar Beranda tergantung field `job` dari API login:

| Nilai `job` | Arti di app | Perilaku |
|---|---|---|
| `0` atau `1` | Visit | Kartu progres tugas hari ini. Tombol jadwal: Mulai → check-in → isi 4 laporan → tanda tangan → check-out |
| `2` (default jika kosong) | Standby | Kartu absen Check In / Check Out. Bisa absen tanpa alur visit lengkap |

Kalau ragu, lihat `loginBox.job` dan fungsi `_isVisitJob()` / `_isStandbyJob()` di `lib/BottomNavbar/beranda.dart`.

---

## 3. Stack & requirement

| Item | Nilai |
|---|---|
| Framework | Flutter |
| Dart SDK | `^3.8.1` |
| State | StatefulWidget (tidak pakai Riverpod / Bloc / GetX) |
| HTTP | `http` |
| Local storage | Hive (`hive` + `hive_flutter`) |
| Kamera | `image_picker`, `camera` |
| QR | `mobile_scanner` |
| GPS | `geolocator` + `geocoding` |
| Peta | `flutter_map` (OpenStreetMap, gratis). Package `google_maps_flutter` ada di `pubspec.yaml` tapi **tidak dipakai** di halaman maps |
| Tanda tangan | `syncfusion_flutter_signaturepad` |
| Kalender | `table_calendar` |
| PDF | `pdf` + `printing` |
| Locale tanggal | `id_ID` (Indonesia) |

**Yang harus terpasang di mesin penerima:**

1. Flutter SDK yang kompatibel dengan Dart 3.8.1
2. Android Studio / SDK (untuk Android)
3. Xcode (hanya jika build iOS; saat ini permission iOS belum lengkap)
4. Device/emulator dengan kamera + GPS untuk tes absen

Perintah cek:

```bash
flutter doctor -v
flutter --version
```

---

## 4. Cara menjalankan (hari pertama)

Di folder root proyek (`teknisi_aag`):

```bash
flutter pub get
flutter run
```

Pilih device Android. Login pakai akun teknisi yang valid di server Atrindo (akun tidak ada di repo).

Lihat mockup UI (HTML, bukan Flutter):

```bash
# buka file ini di browser
mockup/index.html
```

Screenshot mockup ada di `mockup/images/` (login, beranda, jadwal, profile, history, check-in, detail tugas, dll).

---

## 5. Peta folder (yang perlu dibaca)

```
teknisi_aag/
├── lib/                          ← SEMUA KODE APP
│   ├── main.dart                 ← entry: init Hive + routes
│   ├── loginPage.dart            ← login
│   ├── homepage.dart             ← shell + 5 tab bottom nav
│   ├── services/api_service.dart ← SATU-SATUNYA file API yang dipakai
│   ├── constants/                ← warna, ukuran, text style
│   ├── BottomNavbar/             ← 4 tab: beranda, jadwal, pesan, profil
│   ├── BerandaPage/              ← halaman yang dibuka dari beranda
│   │   ├── Checkin&Checkout/     ← check-in & check-out
│   │   ├── TugasTeknisiPage/     ← alur laporan 4 langkah + ttd
│   │   └── qrcodepage/           ← hasil scan QR (tenant / trap / area)
│   └── Page/editProfile.dart     ← belum terhubung ke alur utama
├── assets/icons/                 ← logo & ikon menu
├── mockup/                       ← HTML mockup + screenshot iPhone
├── android/  ios/  web/ ...      ← platform native
└── pubspec.yaml
```

**File yang jangan dikira “sumber API”:**

- `lib/BerandaPage/api_service.dart` → kosong (`TODO`), tidak dipakai
- API yang benar: `lib/services/api_service.dart`

**Nama file yang menyesatkan:**

| File | Nama terasa seperti | Kenyataan |
|---|---|---|
| `BottomNavbar/pesan.dart` | Chat / pesan | Generator PDF dokumentasi (lokal, belum kirim ke server) |
| `BottomNavbar/cart.dart` | Keranjang | Scanner QR (duplikat `qrCode.dart`) |
| `BerandaPage/chemical.dart` | Daftar chemical lapangan | Keranjang **request chemical** (tambah/ubah qty, kirim request) |
| `requestChenical.dart` | Form request | History request chemical + status approval |
| `TugasTeknisiPage/chemicalUsed.dart` | — | Chemical yang dipakai **saat tugas** (beda fitur) |

---

## 6. Navigasi aplikasi (peta layar)

```
LoginPage
   └── homePage  (bottom navigation, 5 tab)
         ├── [0] Beranda
         │      ├── History Client
         │      ├── My Client
         │      ├── Data Chemical          → ChemicalPage (keranjang request)
         │      ├── Absensi
         │      ├── Scan QR
         │      │      ├── QR Tenant
         │      │      ├── QR Trap
         │      │      └── QR Area
         │      ├── Notifikasi             → data dummy, belum API
         │      └── Kartu jadwal hari ini
         │             ├── CheckinPage     (kamera + GPS)
         │             ├── DetailTask      (4 laporan wajib)
         │             │      ├── Dokumentasi Treatment
         │             │      ├── Dokumentasi Temuan & Rekomendasi
         │             │      ├── Checklist
         │             │      └── Chemical Used
         │             ├── SignaturePage   (ttd + foto stempel)
         │             └── CheckOut        (kamera + GPS)
         ├── [1] Jadwal                    → kalender pekerjaan
         ├── [2] Request Chemical          → history request (tombol tengah)
         ├── [3] Pesan                     → buat PDF dari foto + keterangan
         └── [4] Akun / Profile            → lihat data + logout
```

Routes di `main.dart`: `/`, `/homepage`, `/beranda`, `/profile`, `/jadwal`, `/chemical`.  
Mayoritas halaman **tidak** pakai named route — mereka di-push dengan `MaterialPageRoute`.

---

## 7. Alur kerja utama (wajib dipahami)

Ini jantung aplikasi. Semua tombol “Mulai / Proses / Absen-out / Selesai” di Beranda diarahkan lewat `handleBerandaScheduleTap()` di `lib/BerandaPage/TugasTeknisiPage/detailtask.dart`.

### 7.1 Status tombol di kartu jadwal

Sumber status: `GET /task/active-visit` → model `TaskAktif`.

| Kondisi | Teks tombol | Artinya |
|---|---|---|
| Belum ada task aktif | **Mulai** | Belum check-in |
| Ada task, `tugas != 4` | **Proses** | Masih isi 4 laporan |
| `tugas == 4` dan belum `sign_in` | **Proses** | Laporan selesai, belum tanda tangan |
| `tugas == 4`, sudah `sign_in`, belum `absen_out` | **Absen-out** | Tinggal check-out |
| Sudah check-out, atau client di cache hari ini | **Selesai** (disabled) | Selesai hari ini |

`tugas == 4` artinya keempat laporan (treatment, temuan, checklist, chemical) sudah lengkap di server.

### 7.2 Alur Visit (`job` 0 atau 1)

```
Tekan Mulai
  → Check-in (foto + lat/long)  POST /absen/store
  → Server buat task_id
  → Detail Tugas
       1. POST /doc-treat          (task_name: TREATMENT)
       2. POST /doc-temuan         (task_name: AKSES)
       3. POST /checklist          (task_name: CHECKLIST)
       4. POST /chemical-used      (task_name: CHEMICAL)
  → Tombol "Lanjut" muncul jika keempatnya selesai
  → SignaturePage  POST /task/sign-in  (photo ttd + stamp)
  → Check-out  POST /absen/store  (kirim task_id)
  → Client ditandai selesai di cache lokal hari ini
```

Setelah check-in, app menunggu `GET /task/active-visit` sampai `task_id` muncul (retry beberapa kali), baru buka `DetailTask`.

### 7.3 Alur Standby (`job` 2)

Kartu absen di Beranda: Check In / Check Out. Tidak memaksa 4 laporan dulu. Check-out butuh `currentTask` (task aktif dari API).

### 7.4 Cache “sudah selesai hari ini”

File: `lib/BerandaPage/TugasTeknisiPage/task_completion_cache.dart`

Kenapa ada: setelah check-out, API kadang tidak lagi mengembalikan task aktif, jadi tombol bisa kembali jadi “Mulai”. Cache lokal (`loginBox`, key `completed_clients_YYYY-M-D`) menahan tombol di **Selesai** sampai ganti hari.

---

## 8. Penjelasan per modul

### 8.1 Login & sesi

**File:** `lib/loginPage.dart`

- POST `https://report.atrindo.network/api/login` body `{ email, password }`
- Sukses jika `result['success'] == true`
- Disimpan ke Hive `loginBox`:

| Key | Isi |
|---|---|
| `isLoggedIn` | `true` |
| `id` | ID teknisi (dipakai ambil cart) |
| `name`, `email`, `photo` | Profil |
| `level_label` | Role (teks) |
| `token` | Bearer token semua API |
| `job` | 0/1 visit, 2 standby |

Logout: `loginBox.clear()` lalu kembali ke LoginPage (`lib/BottomNavbar/profiile.dart`).

**Bug yang harus diketahui:** di `main.dart`, `isLoggedIn` dibaca tapi **tidak dipakai**. Route `'/'` selalu `LoginPage()`. Jadi setiap buka app, user harus login ulang.

### 8.2 Beranda

**File:** `lib/BottomNavbar/beranda.dart` (file besar)

Isi layar:

1. Halo + foto teknisi
2. Kartu progres (visit) atau kartu absen (standby)
3. Grid menu 6 item
4. Daftar tugas hari ini (dari `GET /jadwal`, di-cache Hive `jadwalBox` untuk hari yang sama)

Model `JadwalModel` di file ini **berbeda** dengan `JadwalModel` di tab Jadwal. Jangan campur.

### 8.3 Check-in / Check-out

| | Check-in | Check-out |
|---|---|---|
| File | `BerandaPage/Checkin&Checkout/checkIn.dart` | `.../checkOut.dart` |
| Endpoint | `POST /absen/store` | `POST /absen/store` (sama, plus `task_id`) |
| Input | `client_id`, `info`, foto base64, `lat`, `long` | + `task_id` |

Kamera langsung terbuka saat halaman load. Foto di-compress (quality rendah) lalu di-encode base64. Lokasi lewat `geolocator`, alamat lewat reverse geocoding.

Hasil check-in juga dicatat di Hive `checkinBox` (success / failed / error) untuk jejak lokal.

### 8.4 Empat laporan di Detail Tugas

Semua status “sudah selesai” dicek ulang ke server lewat `GET /{endpoint}/{taskId}` + helper `ApiService.hasTaskName()`.

| Menu UI | File | POST | `task_name` | GET status |
|---|---|---|---|---|
| Dokumentasi Treatment | `dokumentasiTreatment.dart` | `/doc-treat` | `TREATMENT` | `/doc-treat/{taskId}` |
| Temuan & Rekomendasi | `dokumentasiRekomendasi.dart` | `/doc-temuan` | `AKSES` | `/doc-temuan/{taskId}` |
| Checklist | `checklist.dart` | `/checklist` | `CHECKLIST` | `/checklist/{taskId}` |
| Chemical Used | `chemicalUsed.dart` | `/chemical-used` | `CHEMICAL` | `/chemical-used/{taskId}` |

**Treatment & rekomendasi:** foto + keterangan. Draft disimpan Hive (`dokumentasitreatmentBox`, `dokumentasirekomendasiBox`) sebelum upload.

**Checklist:** multi area. Tiap baris: pest (`GET /pest`) + trap (`GET /trap`) + jumlah. Minimal 1 area.

**Chemical used:** pilih dari `GET /chemical-used` (katalog), lalu kirim `items` berisi `chemical_id`.

Kartu yang sudah selesai **tidak bisa dibuka lagi** (`onTap` dinonaktifkan).

### 8.5 Tanda tangan

**File:** `TugasTeknisiPage/signature.dart`

Wajib dua hal: coretan signature pad **dan** foto stempel dari kamera.  
POST `/task/sign-in` `{ task_id, photo, stamp }`.

Catatan teknis: POST ini **tidak** pakai `http.post` biasa. Pakai `_postJsonPreserveMethod()` karena redirect 301/302 di Laravel bisa mengubah POST jadi GET dan dapat error 405.

### 8.6 Request chemical (dua layar)

1. **Keranjang** — `BerandaPage/chemical.dart` (menu “Data Chemical” di beranda)
   - `GET /teknisiRequest/getChemical`
   - `POST /teknisiRequest/addCart`
   - `POST /teknisiRequest/addQty`
   - `POST /teknisiRequest/delCart`
   - `GET /teknisiRequest/getCart/{userId}`
   - `POST /teknisiRequest/sendRequest` body `{ area }`

2. **History + status approval** — `BerandaPage/requestChenical.dart` (tab tengah bottom nav)
   - `GET /teknisiRequest/history`
   - Status bertingkat: teknisi → SPV → MS → GA → Dirut (`spv_qty`, `ms_qty`, `ga_qty`, `dirut_qty`)

### 8.7 Tab lain

| Tab | File | Status |
|---|---|---|
| Jadwal | `BottomNavbar/jadwal.dart` | Jalan. Kalender `table_calendar` + `GET /jadwal`. Hanya tampil, tidak mulai tugas |
| Pesan | `BottomNavbar/pesan.dart` | Jalan lokal. User foto + ketik, generate PDF. **Tidak ada API** |
| Profile | `BottomNavbar/profiile.dart` | Jalan. Baca Hive, logout. Edit profil ada file terpisah tapi **belum dipasang** |

### 8.8 Menu beranda lain

| Menu | File | API | Status |
|---|---|---|---|
| History | `history.dart` | `GET /history` | Jalan. Cache opsional di `historyBox` |
| My Client | `myClient.dart` | `GET /me/clients` | Jalan. Cari nama/lokasi |
| Absensi | `absensi.dart` | `GET /history` (dipakai ulang, dikelompokkan per tanggal) | Jalan |
| QR Code | `qrCode.dart` | Scanner saja | Routing URL: `/tenant/`, `/trap/`, `/index/`. Halaman isi data masih banyak placeholder |
| Notifikasi | `notifikasi.dart` | Tidak ada | **Dummy data** |
| Maps | `maps.dart` | OSM via flutter_map | Ada, jarang terhubung dari beranda |
| Lapor Bug | `laporBug.dart` | Tidak ada | Placeholder teks |
| Edit Profile | `Page/editProfile.dart` | Tidak ada | Form lokal, belum tersambung |
| Upload Form | `upload_form.dart` | Tidak ada | Halaman tes picker gambar |
| Detail History | `detailHistory.dart` | — | Hampir seluruhnya di-comment |

---

## 9. API — daftar endpoint

Base: `https://report.atrindo.network/api`  
Header umum: `Authorization: Bearer {token}`, `Accept: application/json`  
Token diambil dari `Hive.box('loginBox').get('token')`.

### Auth & master data

| Method | Path | Dipakai di |
|---|---|---|
| POST | `/login` | Login |
| GET | `/jadwal` | Beranda + tab Jadwal |
| GET | `/history` | History + Absensi |
| GET | `/me/clients` | My Client |
| GET | `/task/active-visit` | Cek task aktif / status tombol |

### Absensi

| Method | Path | Body penting |
|---|---|---|
| POST | `/absen/store` | `client_id`, `info`, `data` (data-URI base64), `lat`, `long`, optional `task_id` |

### Laporan tugas

| Method | Path | `task_name` |
|---|---|---|
| POST | `/doc-treat` | `TREATMENT` |
| GET | `/doc-treat/{taskId}` | — |
| POST | `/doc-temuan` | `AKSES` |
| GET | `/doc-temuan/{taskId}` | — |
| POST | `/checklist` | `CHECKLIST` |
| GET | `/checklist/{taskId}` | — |
| GET | `/pest` | Opsi checklist |
| GET | `/trap` | Opsi checklist |
| POST | `/chemical-used` | `CHEMICAL` |
| GET | `/chemical-used` | Katalog |
| GET | `/chemical-used/{taskId}` | Status per task |
| POST | `/task/sign-in` | `photo`, `stamp` |

### Request chemical

| Method | Path |
|---|---|
| GET | `/teknisiRequest/getChemical` |
| POST | `/teknisiRequest/addCart` |
| POST | `/teknisiRequest/addQty` |
| POST | `/teknisiRequest/delCart` |
| GET | `/teknisiRequest/getCart/{id}` |
| POST | `/teknisiRequest/sendRequest` |
| GET | `/teknisiRequest/history` |

Semua implementasi ada di `lib/services/api_service.dart`. Foto dikompres dulu (`quality: 40`, max 800px) lalu base64 — ini sengaja supaya tidak 422 dari server.

---

## 10. Penyimpanan lokal (Hive)

Dibuka di `main.dart`:

| Box | Isi |
|---|---|
| `loginBox` | Sesi user + token + cache client selesai hari ini |
| `tokenBox` | Dibuka, **tidak dipakai** (token ada di `loginBox`) |
| `checkinBox` | Log check-in lokal |
| `dokumentasirekomendasiBox` | Draft foto temuan |
| `dokumentasitreatmentBox` | Draft foto treatment |
| `jadwalBox` | Cache jadwal **hari ini saja** |

`historyBox` dibuka on-demand di halaman History, tidak di `main()`.

Tidak ada model Hive TypeAdapter. Data disimpan sebagai Map/List biasa.

---

## 11. Desain & konstanta

- Warna: `lib/constants/app__Colors.dart` — primary `#0051FF`, secondary hijau, background `#F5F5F5`
- Ukuran: `lib/constants/app_responsive.dart` (`AppSizes`)
- Banyak halaman juga memakai `MediaQuery.size.width * 0.xx` langsung
- Aset ikon: `assets/icons/` (didaftarkan satu-satu di `pubspec.yaml`)
- Mockup visual: `mockup/index.html` + `mockup/images/*-iphone.png`

Kalau ubah UI, cocokkan dulu dengan mockup beranda / detail tugas / history.

---

## 12. Hal yang belum beres / jebakan

Baca ini sebelum “memperbaiki” sesuatu secara acak.

### Wajib diketahui

1. **Session login tidak persist.** `isLoggedIn` dihitung di `main.dart` lalu dibuang. App selalu ke LoginPage.
2. **Google Maps API key placeholder** di `android/app/src/main/AndroidManifest.xml`: `API_KEY_KAMU`. Halaman maps memakai OSM, jadi key ini belum krusial — tapi jangan commit key asli ke git.
3. **Application ID masih `com.example.teknisi_aag`.** Harus diganti sebelum rilis Play Store.
4. **Release Android masih sign debug** (`android/app/build.gradle.kts`).
5. **iOS belum siap production.** `Info.plist` tidak punya `NSCameraUsageDescription` / `NSLocationWhenInUseUsageDescription`. Kamera & GPS akan crash di iOS.
6. **AndroidManifest tidak menulis permission CAMERA** secara eksplisit (plugin mungkin menambahkannya). Location & storage sudah ada.

### Fitur setengah jadi

- Notifikasi: dummy
- QR tenant/trap/area: UI ada, data masih banyak hardcode
- Pesan: PDF lokal, tidak terhubung backend
- Lapor bug, edit profile, upload form, detail history: tidak masuk alur
- `baseApp` (`app.atrindo.network`) tidak dipakai

### Kualitas kode (bukan blocker, tapi membingungkan)

- Dua class `JadwalModel` berbeda (beranda vs tab jadwal)
- Dua class `ChemicalModel` berbeda (request vs chemical used)
- Scanner QR duplikat (`qrCode.dart` dan `cart.dart`)
- `print()` debug masih banyak di API
- Tidak ada layer model/repository terpisah; parsing JSON ada di UI
- `lib/BerandaPage/api_service.dart` kosong — bisa dihapus nanti
- Typo nama file: `profiile.dart`, `requestChenical.dart`, `app__Colors.dart`

### Tes yang harus dijalankan penerima

Tidak ada test berarti (`test/widget_test.dart` masih default). Tes manual yang paling penting:

1. Login sukses / gagal
2. Visit: Mulai → check-in kamera → 4 laporan → Lanjut → ttd+stempel → check-out → tombol jadi Selesai
3. Tutup app, buka lagi di hari yang sama: tombol klien itu tetap Selesai
4. Standby: check-in / check-out dari kartu absen
5. Request chemical: tambah cart, ubah qty, kirim, lihat history approval
6. History, My Client, Absensi terisi dari API
7. Logout lalu login akun lain

---

## 13. Checklist onboarding penerima (urut)

- [ ] Install Flutter, jalankan `flutter doctor`
- [ ] `flutter pub get` lalu `flutter run` di Android
- [ ] Minta akun teknisi visit (`job` 0/1) dan standby (`job` 2) ke pemilik API
- [ ] Baca `lib/services/api_service.dart` (kontrak backend)
- [ ] Baca `handleBerandaScheduleTap` + `TaskAktif` di `detailtask.dart`
- [ ] Baca `Beranda` (`beranda.dart`) — layar paling kompleks
- [ ] Buka `mockup/index.html` supaya UI tidak “dinebak”
- [ ] Catat backend contact: siapa yang pegang `report.atrindo.network`
- [ ] Jangan ubah alur visit dulu sebelum bisa reproduce end-to-end di device fisik (kamera + GPS)

---

## 14. Kalau mau lanjut kerja, urutan yang masuk akal

1. Perbaiki persist login (pakai `isLoggedIn` di `MaterialApp.home`)
2. Rapikan permission Android/iOS (kamera, lokasi)
3. Sambungkan Notifikasi ke API, atau sembunyikan menu
4. Selesaikan halaman hasil scan QR
5. Ganti `applicationId` + signing release
6. (Opsional) pecah `beranda.dart` dan samakan model `JadwalModel`

---

## 15. Kontak konteks (isi sendiri saat serah terima)

| Item | Isi |
|---|---|
| Repo ini | Client Flutter teknisi |
| Backend | `report.atrindo.network` (bukan di repo ini) |
| Akun uji visit | _(isi)_ |
| Akun uji standby | _(isi)_ |
| PIC desain / mockup | Folder `mockup/` |
| PIC API | _(isi)_ |

Kalau ada yang tidak cocok antara dokumen ini dan kode, **percaya kode**. File paling berwibawa: `lib/services/api_service.dart` dan `lib/BerandaPage/TugasTeknisiPage/detailtask.dart`.
