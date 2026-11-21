'use client';
import {useCallback, useEffect, useState} from 'react';
import {collection, getCountFromServer, getDocs, limit, orderBy, query, where, QueryConstraint} from 'firebase/firestore';
import {db} from './firebase';

export type Doc = {id: string; [k: string]: any};

export function useDocs(name: string, opts: {order?: string; dir?: 'asc' | 'desc'; max?: number; where?: [string, any, any]} = {}) {
  const [docs, setDocs] = useState<Doc[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const reload = useCallback(async () => {
    setLoading(true); setError('');
    try {
      const c: QueryConstraint[] = [];
      if (opts.where) c.push(where(opts.where[0], opts.where[1], opts.where[2]));
      if (opts.order) c.push(orderBy(opts.order, opts.dir ?? 'desc'));
      c.push(limit(opts.max ?? 200));
      const snap = await getDocs(query(collection(db(), name), ...c));
      setDocs(snap.docs.map((d) => ({id: d.id, ...d.data()})));
    } catch (e: any) {
      setError(e?.message ?? 'Failed to load');
    } finally { setLoading(false); }
  }, [name, opts.order, opts.dir, opts.max, opts.where?.[0], opts.where?.[2]]); // eslint-disable-line react-hooks/exhaustive-deps
  useEffect(() => { reload(); }, [reload]);
  return {docs, loading, error, reload};
}

export async function count(name: string, w?: [string, any, any]): Promise<number> {
  try {
    const q = w ? query(collection(db(), name), where(w[0], w[1], w[2])) : collection(db(), name);
    return (await getCountFromServer(q)).data().count;
  } catch { return -1; }
}

export const fmt = (v: any) => {
  if (!v) return '';
  const d = typeof v.toDate === 'function' ? v.toDate() : new Date(v);
  return isNaN(d.getTime()) ? '' : d.toLocaleString();
};
