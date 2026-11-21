'use client';
import {useEffect, useState} from 'react';
import {count} from '@/lib/hooks';
import {CATEGORIES} from '@/lib/constants';

export default function Categories() {
  const [c, setC] = useState<Record<string, number>>({});
  useEffect(() => { (async () => {
    const r: Record<string, number> = {};
    for (const k of CATEGORIES) r[k] = await count('hadith', ['category', '==', k]);
    setC(r);
  })(); }, []);
  return (
    <>
      <h1>Categories</h1>
      <p className="muted">The 20 Hadith categories are fixed in code and validated server-side. Counts include all statuses.</p>
      <div className="card"><table><thead><tr><th>Category</th><th>Hadith</th></tr></thead>
        <tbody>{CATEGORIES.map((k) => <tr key={k}><td>{k}</td><td>{c[k] === undefined ? '…' : c[k] < 0 ? 'n/a' : c[k]}</td></tr>)}</tbody></table></div>
    </>
  );
}
