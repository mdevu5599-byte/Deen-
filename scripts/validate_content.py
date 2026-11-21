#!/usr/bin/env python3
"""Lint bundled content. Fails if any record marked 'verified' lacks mandatory fields."""
import json, sys, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
D = os.path.join(ROOT, "apps/mobile/assets/data")
BOOKS = ["Sahih al-Bukhari","Sahih Muslim","Sunan Abu Dawud","Jami' at-Tirmidhi","Sunan an-Nasa'i","Sunan Ibn Majah"]
bad = 0
for r in json.load(open(f"{D}/hadith.json", encoding="utf-8")):
    if r.get("status") != "verified": continue
    miss = [k for k in ("arabic","bn","book","number","grade","category") if not str(r.get(k,"")).strip()]
    if r.get("book") not in BOOKS: miss.append("book(not canonical)")
    if miss: print("hadith", r.get("id"), "missing", miss); bad += 1
for r in json.load(open(f"{D}/duas.json", encoding="utf-8")):
    if r.get("status") != "verified": continue
    miss = [k for k in ("arabic","bn","reference") if not str(r.get(k,"")).strip()]
    if miss: print("dua", r.get("id"), "missing", miss); bad += 1
for r in json.load(open(f"{D}/reminders.json", encoding="utf-8")):
    if r.get("kind") != "original": print("reminder", r.get("id"), "must be kind=original in bundled file"); bad += 1
print("content problems:", bad); sys.exit(1 if bad else 0)
