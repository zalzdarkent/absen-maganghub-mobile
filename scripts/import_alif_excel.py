#!/usr/bin/env python3
"""
Skrip otomatis untuk mengimpor seluruh data dari Logbook_MagangHub.xlsx
ke dalam database SQLite untuk user dengan username == 'alif'.

Cara penggunaan:
    python3 scripts/import_alif_excel.py [path_ke_database.db]

Jika path database tidak disertakan, skrip akan mencari file maganghub_logbook.db
secara otomatis di lokasi standar aplikasi atau membuat/mengupdate di direktori lokal.
"""

import sys
import os
import glob
import hashlib
import sqlite3
import datetime
import zipfile
import xml.etree.ElementTree as ET

def hash_password(password: str) -> str:
    return hashlib.sha256(password.strip().encode('utf-8')).hexdigest()

def parse_excel_logbook(excel_path: str):
    if not os.path.exists(excel_path):
        raise FileNotFoundError(f"File Excel tidak ditemukan: {excel_path}")

    with zipfile.ZipFile(excel_path, 'r') as z:
        sst_root = ET.fromstring(z.read('xl/sharedStrings.xml'))
        ns = {'main': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
        strings = [elem.text or '' for elem in sst_root.findall('.//main:t', ns)]

        sheet_root = ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
        rows = sheet_root.findall('.//main:row', ns)
        entries = []

        # Lewati header (baris pertama)
        for r in rows[1:]:
            cells = []
            for c in r.findall('main:c', ns):
                t = c.get('t')
                v = c.find('main:v', ns)
                val = v.text if v is not None else ''
                if t == 's' and val.isdigit():
                    idx = int(val)
                    val = strings[idx] if idx < len(strings) else ''
                cells.append(val)
            if len(cells) >= 5:
                try:
                    no_val = int(cells[0])
                except ValueError:
                    continue
                entries.append({
                    'no': no_val,
                    'tanggal': cells[1].strip(),
                    'aktivitas': cells[2].strip(),
                    'pembelajaran': cells[3].strip(),
                    'kendala': cells[4].strip(),
                })
        return entries

def find_candidate_databases():
    candidates = []
    # 1. Direktori saat ini
    if os.path.exists('maganghub_logbook.db'):
        candidates.append(os.path.abspath('maganghub_logbook.db'))

    # 2. Lokasi standar sqflite di Linux
    home = os.path.expanduser('~')
    patterns = [
        os.path.join(home, '.local/share/**/maganghub_logbook.db'),
        os.path.join(home, 'projects/**/maganghub_logbook.db'),
    ]
    for pattern in patterns:
        for p in glob.glob(pattern, recursive=True):
            if p not in candidates:
                candidates.append(p)
    return candidates

def import_for_alif(db_path: str, excel_path: str = 'Logbook_MagangHub.xlsx', target_username: str = 'alif'):
    target_username = target_username.strip().lower()
    if target_username != 'alif':
        print(f"[SKIP] Username '{target_username}' bukan 'alif'. Skrip ini khusus menangani user 'alif'.")
        return

    print(f"\n=======================================================")
    print(f"🚀 Memproses impor data Logbook untuk user: '{target_username}'")
    print(f"📁 Database: {db_path}")
    print(f"📊 Excel: {excel_path}")
    print(f"=======================================================")

    entries = parse_excel_logbook(excel_path)
    print(f"✅ Berhasil membaca {len(entries)} entri dari {excel_path}")

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Pastikan tabel users dan logbook_entries ada
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            name TEXT,
            created_at TEXT NOT NULL
        )
    ''')

    cursor.execute('''
        CREATE TABLE IF NOT EXISTS logbook_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            no INTEGER NOT NULL,
            tanggal TEXT NOT NULL,
            row_number INTEGER NOT NULL,
            aktivitas TEXT NOT NULL,
            pembelajaran TEXT NOT NULL,
            kendala TEXT NOT NULL,
            created_at TEXT NOT NULL,
            UNIQUE(user_id, tanggal)
        )
    ''')

    now_iso = datetime.datetime.now().isoformat()

    # Cek user 'alif'
    cursor.execute('SELECT id, username, email FROM users WHERE LOWER(username) = ?', (target_username,))
    user_row = cursor.fetchone()

    if user_row:
        user_id = user_row[0]
        print(f"👤 User '{target_username}' ditemukan dengan ID: {user_id}")
    else:
        # Buat user 'alif' otomatis jika belum ada
        pwd_hash = hash_password('alif123')
        cursor.execute('''
            INSERT INTO users (username, email, password_hash, name, created_at)
            VALUES (?, ?, ?, ?, ?)
        ''', (target_username, f'{target_username}@maganghub.local', pwd_hash, 'Alif', now_iso))
        user_id = cursor.lastrowid
        print(f"👤 Berhasil membuat akun baru untuk '{target_username}' dengan ID: {user_id}")

    # Masukkan seluruh data logbook untuk user alif
    inserted_count = 0
    for e in entries:
        cursor.execute('''
            INSERT INTO logbook_entries (user_id, no, tanggal, row_number, aktivitas, pembelajaran, kendala, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(user_id, tanggal) DO UPDATE SET
                no = excluded.no,
                row_number = excluded.row_number,
                aktivitas = excluded.aktivitas,
                pembelajaran = excluded.pembelajaran,
                kendala = excluded.kendala
        ''', (
            user_id,
            e['no'],
            e['tanggal'],
            e['no'],
            e['aktivitas'],
            e['pembelajaran'],
            e['kendala'],
            now_iso
        ))
        inserted_count += 1

    conn.commit()

    # Verifikasi jumlah data yang tersimpan
    cursor.execute('SELECT COUNT(*) FROM logbook_entries WHERE user_id = ?', (user_id,))
    total = cursor.fetchone()[0]
    conn.close()

    print(f"🎉 SUKSES! {inserted_count} entri dari {excel_path} berhasil dimasukkan ke user '{target_username}'.")
    print(f"📊 Total entri aktif untuk '{target_username}' sekarang: {total} entri.")
    print(f"=======================================================\n")

def main():
    excel_path = 'Logbook_MagangHub.xlsx'
    if not os.path.exists(excel_path):
        excel_path = os.path.join(os.path.dirname(__file__), '../Logbook_MagangHub.xlsx')

    if len(sys.argv) > 1:
        db_path = sys.argv[1]
        import_for_alif(db_path, excel_path=excel_path)
    else:
        candidates = find_candidate_databases()
        if not candidates:
            # Gunakan default maganghub_logbook.db
            db_path = 'maganghub_logbook.db'
            import_for_alif(db_path, excel_path=excel_path)
        else:
            for db in candidates:
                import_for_alif(db, excel_path=excel_path)

if __name__ == '__main__':
    main()
