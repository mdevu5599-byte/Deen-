'use client';
import {useEffect, useState} from 'react';
import {count} from '@/lib/hooks';

export default function Quran() {
  const [n, setN] = useState<number | null>(null);
  useEffect(() => { count('quran_verses').then(setN); }, []);
  return (
    <>
      <h1>Quran content</h1>
      <div className="card">
        <p>Verses in Firestore: <b>{n === null ? '…' : n < 0 ? 'n/a' : n}</b></p>
        <p className="muted">Quran text is never edited by hand and never AI-generated. It is imported from the verified Tanzil.net text using <code>scripts/fetch_quran.py</code> and bundled into the mobile app. Optional Firestore import is done by an administrator with a service account from a trusted machine (see docs/CONTENT_VERIFICATION.md).</p>
      </div>
    </>
  );
}
