# UMKM Copilot Indonesia

Asisten Generative AI Mobile-first berbahasa Indonesia untuk membantu pemilik Usaha Mikro, Kecil, dan Menengah (UMKM) mengelola bisnis mereka menggunakan percakapan alami.

Aplikasi ini memudahkan pencatatan transaksi melalui suara/teks, memberikan rekomendasi insight bisnis berbasis AI, mempermudah pembuatan materi pemasaran (promosi), serta menyajikan dasbor keuangan yang interaktif.

---

## Fitur Utama

1. **Pencatatan Transaksi AI**: Cukup tulis *"Saya menjual 10 kopi"* atau *"Beli gas elpiji 3kg seharga 40 ribu"*, AI akan secara otomatis mengekstrak detail produk, kuantitas, jenis transaksi (pemasukan/pengeluaran), serta harga sebelum dikonfirmasi oleh pengguna untuk disimpan ke database.
2. **AI Sales Insights**: Memberikan rekomendasi bisnis berkala, menyoroti tren penjualan produk terlaris, persediaan stok yang menipis, serta promo penjualan.
3. **Pembuat Konten Pemasaran**: Menghasilkan deskripsi produk, caption promosi Instagram, dan pesan siaran WhatsApp sesuai nada bahasa (tone) yang diinginkan.
4. **Dasbor Keuangan Premium**: Menampilkan total omset harian/bulanan, laba kotor/bersih, bagan diagram tren penjualan, serta riwayat transaksi terbaru.

---

## Struktur Folder Project

```text
umkm-copilot/
├── backend/
│   ├── app/
│   │   ├── database/
│   │   │   └── seed.py             # Script data dummy awal
│   │   ├── models/
│   │   │   └── models.py           # Model database SQLAlchemy
│   │   ├── routes/
│   │   │   ├── auth.py             # Router autentikasi & JWT
│   │   │   ├── products.py         # Router pengelolaan produk
│   │   │   ├── chat.py             # Router chat & ekstraksi AI
│   │   │   ├── marketing.py        # Router pemasaran AI
│   │   │   ├── reports.py          # Router laporan berkala
│   │   │   └── dashboard.py        # Router indikator dasbor utama
│   │   ├── schemas/
│   │   │   └── schemas.py          # Model validasi data Pydantic
│   │   ├── services/
│   │   │   ├── auth_service.py
│   │   │   ├── ai_service.py       # Integrasi SDK Google Gemini AI
│   │   │   ├── transaction_service.py
│   │   │   ├── marketing_service.py
│   │   │   ├── insight_service.py
│   │   │   └── dashboard_service.py
│   │   ├── database.py             # Koneksi engine & session DB
│   │   └── main.py                 # File inisialisasi aplikasi FastAPI
│   ├── .env.example                # Templat konfigurasi env
│   └── requirements.txt            # Dependensi Python
├── frontend/
│   └── mobile/
│       ├── lib/
│       │   ├── models/
│       │   ├── providers/          # Manajemen status (Provider)
│       │   │   ├── auth_provider.dart
│       │   │   ├── chat_provider.dart
│       │   │   ├── product_provider.dart
│       │   │   └── dashboard_provider.dart
│       │   ├── screens/            # UI Layar Utama Flutter
│       │   │   ├── splash_screen.dart
│       │   │   ├── login_screen.dart
│       │   │   ├── dashboard_screen.dart
│       │   │   ├── ai_chat_screen.dart
│       │   │   ├── reports_screen.dart
│       │   │   ├── marketing_screen.dart
│       │   │   └── profile_screen.dart
│       │   ├── services/
│       │   │   └── api_service.dart    # Klien HTTP terpusat
│       │   ├── widgets/
│       │   └── main.dart
│       └── pubspec.yaml            # Konfigurasi dependensi Flutter
├── docs/
│   └── postman_collection.json     # Koleksi API Postman untuk testing
└── README.md
```

---

## Petunjuk Instalasi & Menjalankan Aplikasi

### 1. Persiapan Backend (FastAPI)

1. Masuk ke folder backend:
   ```bash
   cd backend
   ```
2. Buat python virtual environment dan aktifkan:
   ```bash
   python -m venv venv
   # Di Windows (PowerShell):
   .\venv\Scripts\Activate.ps1
   # Di macOS/Linux:
   source venv/bin/activate
   ```
3. Pasang semua pustaka/dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Buat file konfigurasi `.env` dari templat:
   ```bash
   cp .env.example .env
   ```
   *Edit file `.env` dan masukkan `DATABASE_URL` PostgreSQL Anda serta `GEMINI_API_KEY` dari Google AI Studio.*

5. Lakukan inisialisasi skema dan seed data simulasi awal ke database:
   ```bash
   python -m app.seed
   ```

6. Jalankan server backend lokal:
   ```bash
   uvicorn app.main:app --reload
   ```
   *Aplikasi backend akan berjalan di `http://localhost:8000`. Dokumentasi OpenAPI interaktif dapat diakses pada `http://localhost:8000/docs`.*

---

### 2. Persiapan Frontend (Flutter)

1. Pastikan Anda telah memasang Flutter SDK versi `>= 3.0.0` pada komputer Anda.
2. Masuk ke folder mobile:
   ```bash
   cd ../frontend/mobile
   ```
3. Jalankan pengunduhan pustaka Flutter:
   ```bash
   flutter pub get
   ```
4. Jalankan aplikasi di Emulator Android, iOS Simulator, atau Web:
   ```bash
   flutter run
   ```

---

## Dokumentasi Endpoint API Utama

Berikut adalah daftar API penting yang digunakan oleh aplikasi:

| Deskripsi | Method | Endpoint | Authorization |
|---|---|---|---|
| Registrasi Akun Baru | `POST` | `/api/auth/register` | Tidak |
| Masuk & Dapatkan Token | `POST` | `/api/auth/login` | Tidak (OAuth2 Form) |
| Profil Pemilik UMKM | `GET` | `/api/auth/me` | Bearer Token |
| List Produk Terdaftar | `GET` | `/api/products` | Bearer Token |
| Tambah Produk Manual | `POST` | `/api/products` | Bearer Token |
| Ekstraksi Teks via AI | `POST` | `/api/chat/parse-transaction` | Bearer Token |
| Konfirmasi & Simpan Transaksi | `POST` | `/api/chat/confirm-transaction` | Bearer Token |
| Minta Insight AI Terbaru | `POST` | `/api/chat/insight` | Bearer Token |
| Ambil Rangkuman Dasbor | `GET` | `/api/dashboard` | Bearer Token |
| Buat Laporan Keuangan | `POST` | `/api/reports/generate` | Bearer Token |
| Hasilkan Materi Pemasaran | `POST` | `/api/marketing/generate` | Bearer Token |

---

## Akun Demo Default (Telah di-seed)

Setelah Anda menjalankan script `python -m app.seed`, Anda bisa langsung masuk ke aplikasi mobile atau melakukan pengetesan API dengan kredensial berikut:

* **Email**: `admin@umkmcopilot.id`
* **Password**: `password123`
* **Bisnis**: Warkop Budi Sejahtera
