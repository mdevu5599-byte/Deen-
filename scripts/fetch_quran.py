#!/usr/bin/env python3
"""Build apps/mobile/assets/data/quran.json from verified Tanzil.net files.

Quran text is NEVER generated. Download these files yourself from https://tanzil.net
(keep their licence/attribution terms) and put them in data_sources/:

  data_sources/quran-uthmani.txt   Tanzil Quran text, "Text (with aya numbers)" format  -> sura|aya|text
  data_sources/bn.bengali.txt      Tanzil translation, TXT format sura|aya|text (Bengali)
  data_sources/en.sahih.txt        (optional) English translation, same format

Usage:  python3 scripts/fetch_quran.py
"""
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "data_sources")
OUT = os.path.join(ROOT, "apps", "mobile", "assets", "data", "quran.json")

SURAH_EN = """Al-Fatihah,Al-Baqarah,Aal-E-Imran,An-Nisa,Al-Ma'idah,Al-An'am,Al-A'raf,Al-Anfal,At-Tawbah,Yunus,Hud,Yusuf,Ar-Ra'd,Ibrahim,Al-Hijr,An-Nahl,Al-Isra,Al-Kahf,Maryam,Ta-Ha,Al-Anbiya,Al-Hajj,Al-Mu'minun,An-Nur,Al-Furqan,Ash-Shu'ara,An-Naml,Al-Qasas,Al-Ankabut,Ar-Rum,Luqman,As-Sajdah,Al-Ahzab,Saba,Fatir,Ya-Sin,As-Saffat,Sad,Az-Zumar,Ghafir,Fussilat,Ash-Shura,Az-Zukhruf,Ad-Dukhan,Al-Jathiyah,Al-Ahqaf,Muhammad,Al-Fath,Al-Hujurat,Qaf,Adh-Dhariyat,At-Tur,An-Najm,Al-Qamar,Ar-Rahman,Al-Waqi'ah,Al-Hadid,Al-Mujadila,Al-Hashr,Al-Mumtahanah,As-Saff,Al-Jumu'ah,Al-Munafiqun,At-Taghabun,At-Talaq,At-Tahrim,Al-Mulk,Al-Qalam,Al-Haqqah,Al-Ma'arij,Nuh,Al-Jinn,Al-Muzzammil,Al-Muddaththir,Al-Qiyamah,Al-Insan,Al-Mursalat,An-Naba,An-Nazi'at,Abasa,At-Takwir,Al-Infitar,Al-Mutaffifin,Al-Inshiqaq,Al-Buruj,At-Tariq,Al-A'la,Al-Ghashiyah,Al-Fajr,Al-Balad,Ash-Shams,Al-Layl,Ad-Duha,Ash-Sharh,At-Tin,Al-Alaq,Al-Qadr,Al-Bayyinah,Az-Zalzalah,Al-Adiyat,Al-Qari'ah,At-Takathur,Al-Asr,Al-Humazah,Al-Fil,Quraysh,Al-Ma'un,Al-Kawthar,Al-Kafirun,An-Nasr,Al-Masad,Al-Ikhlas,Al-Falaq,An-Nas""".split(",")
assert len(SURAH_EN) == 114, len(SURAH_EN)
AYAH_COUNTS = [7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,135,112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,53,89,59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,12,30,52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,30,20,15,21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6]
assert len(AYAH_COUNTS) == 114 and sum(AYAH_COUNTS) == 6236, sum(AYAH_COUNTS)


def read(name, required):
    path = os.path.join(SRC, name)
    if not os.path.exists(path):
        if required:
            sys.exit(f"Missing required file: {path}\nSee the docstring of this script.")
        return None
    data = {}
    for line in open(path, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line or line.startswith("#") or "|" not in line:
            continue
        s, a, t = line.split("|", 2)
        data[(int(s), int(a))] = t.strip()
    return data


def main():
    ar = read("quran-uthmani.txt", True)
    bn = read("bn.bengali.txt", True)
    en = read("en.sahih.txt", False)
    for label, d in (("Arabic", ar), ("Bengali", bn)):
        if len(d) != 6236:
            sys.exit(f"{label} file has {len(d)} verses, expected 6236. Refusing to build incomplete data.")
    surahs = []
    for i in range(114):
        no = i + 1
        ayahs = []
        for n in range(1, AYAH_COUNTS[i] + 1):
            a = {"n": n, "ar": ar[(no, n)], "bn": bn[(no, n)]}
            if en and (no, n) in en:
                a["en"] = en[(no, n)]
            ayahs.append(a)
        surahs.append({"no": no, "en": SURAH_EN[i], "ayahs": ayahs})
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump({"source": "tanzil.net", "surahs": surahs}, open(OUT, "w", encoding="utf-8"), ensure_ascii=False)
    print(f"Wrote {OUT}: 114 surahs, 6236 verses")


if __name__ == "__main__":
    main()
