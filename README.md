# 🍎 MagangHub - iOS Edition (Flutter)

Aplikasi asisten dan generator logbook MagangHub berbasis Flutter dengan **otentik Apple iOS Design System (Cupertino)**, memiliki fitur 100% setara (*exact feature parity*) dengan versi `React/absen-maganghub`.

---

## ✨ Fitur Utama (Feature Parity)

1. **Otomatisasi Git Commit Hari Ini (Multi-Repo Support)**
   - Mendeteksi commit hari ini dari hingga 5 repository sekaligus.
   - Pilihan interaktif repo chips dengan selector iOS segmented style.
   - Modal detail diff commit interaktif ala iOS Sheet (`CommitDiffModal`) dengan sintaks highlight diff `+` dan `-`.

2. **AI Logbook Draft Generator (3 Mode)**
   - **Mode Commit:** AI merangkum commit harian menjadi draft terstruktur (*Aktivitas*, *Pembelajaran*, *Kendala*).
   - **Mode Manual:** Input catatan kerja manual jika tidak ada commit hari ini.
   - **Mode Kombinasi (Merged):** Menggabungkan git commits dan catatan manual menjadi satu laporan padu.
   - Switcher AI Provider instan di dalam editor draft: **Local LLM** (Ollama/LM Studio) vs **Google Gemini**.
   - Tombol *Ulangi* (Regenerate) dan *Simpan Logbook*.

3. **Validasi Karakter & Autosave Realtime**
   - Karakter counter dinamis dengan visual progress bar (Target: **100 – 5000 karakter** per field).
   - Indikator kepatuhan (*Compliant Badge*) hijau bercahaya.
   - Autosave draft lokal otomatis ke `SharedPreferences` sehingga progres penulisan tidak pernah hilang.

4. **Riwayat Logbook & Kalender Kerja**
   - **Tampilan Kalender Matrix:** Menampilkan status kehadiran per hari:
     - 🟢 **Terisi** (Sudah ada logbook)
     - 🔴 **Bolong / Terlewat** (Hari kerja tanpa logbook)
     - ⚪ **Hari Ini** (Cincin biru khas iOS Calendar)
     - ▫️ **Weekend / Mendatang** (Pudar)
   - **Tampilan List:** Rincian kartu logbook yang dapat di-edit dan di-delete.
   - **Yearly Activity Heatmap:** GitHub-style activity grid visual.
   - **Export Excel (.xlsx / CSV):** Fitur ekspor riwayat logbook untuk arsip resmi.

5. **Rekap AI Mingguan & Bulanan**
   - Tab Rekap AI otomatis dari entri logbook periode terpilih.
   - Analisis pencapaian, evaluasi kendala, dan rekomendasi langkah selanjutnya.
   - Tombol salin ke clipboard (*Haptic feedback*) dan tombol *Share* iOS native.

6. **Pengaturan Lengkap**
   - Konfigurasi URL backend lokal (`http://localhost:4174` atau custom IP).
   - Pilihan LLM Provider (Local LLM vs Gemini API Key).
   - Uji koneksi LLM langsung dengan pengukuran latensi milidetik (*ping/latency*).
   - Manajemen multi-repository (Tambah, lihat path, hapus).
   - Pemicu instan background auto-draft (`/api/auto-draft/run`).

---

## 🎨 iOS Aesthetic Highlights

- **Apple Inset Grouped Styling:** Background berlapis kontras halus (`systemGroupedBackground` `#000000` / `#F2F2F7`).
- **Typography:** SF Pro font hierarchy dengan weight, tracking, dan letter-spacing presisi.
- **Cupertino Controls:** Segmented controls, Cupertino action sheets, iOS spring physics, and rounded buttons with haptics.
- **Dynamic Island Toasts:** Floating toast banner dengan border radius 30px dan subtle glow.
- **Glowing Status Badges:** Pulsing status dot indikator hijau/kuning/merah.

---

## 🚀 Cara Menjalankan

### 1. Jalankan Backend Server
Pastikan backend Express dari `React/absen-maganghub` berjalan di port `4174`:
```bash
cd /home/alif/projects/React/absen-maganghub
npm run dev
# Server running at http://localhost:4174
```

### 2. Jalankan Aplikasi Flutter
```bash
cd /home/alif/projects/Flutter/absen_maganghub

# Install dependencies jika belum
flutter pub get

# Jalankan di Linux Desktop, Chrome/Web, atau Simulator iOS/Android
flutter run -d chrome
# atau
flutter run -d linux
```

*(Catatan: Jika dijalankan di Android Emulator, ubah URL Server di tab Pengaturan menjadi `http://10.0.2.2:4174`)*

---

## 🧪 Testing & Analisis Kode

```bash
flutter analyze
flutter test
```
Semua static analysis dan widget test berstatus **0 issues** dan **All tests passed!**.
