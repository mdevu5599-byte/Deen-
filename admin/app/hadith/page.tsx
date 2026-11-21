'use client';
import {useState} from 'react';
import {call} from '@/lib/firebase';
import {Doc, useDocs} from '@/lib/hooks';
import {CATEGORIES} from '@/lib/constants';

const BOOKS = ['Sahih al-Bukhari', 'Sahih Muslim', 'Sunan Abu Dawud', "Jami' at-Tirmidhi", "Sunan an-Nasa'i", 'Sunan Ibn Majah'];
const EMPTY = {category: CATEGORIES[0], arabic: '', bn: '', en: '', explanationBn: '', lessonBn: '', book: BOOKS[0], number: '', narrator: '', grade: ''};

export default function Hadith() {
  const {docs, loading, error, reload} = useDocs('hadith', {order: 'updatedAt'});
  const [filter, setFilter] = useState('all');
  const [form, setForm] = useState<any>(null);
  const [editId, setEditId] = useState('');
  const [msg, setMsg] = useState('');
  const [err, setErr] = useState('');
  const set = (k: string, v: string) => setForm((f: any) => ({...f, [k]: v}));

  async function run(fn: () => Promise<any>, ok: string) {
    setMsg(''); setErr('');
    try { await fn(); setMsg(ok); await reload(); } catch (e: any) { setErr(e?.message ?? 'Failed'); }
  }
  const list = docs.filter((d: Doc) => filter === 'all' || d.status === filter);

  return (
    <>
      <h1>Hadith</h1>
      <p className="muted">New or edited records are saved as <b>pending</b>. A second admin must verify them. Verification is refused unless Arabic text, Bengali translation, a canonical book, a hadith number and a grade are present.</p>
      {msg && <div className="ok" role="status">{msg}</div>}
      {(err || error) && <div className="err" role="alert">{err || error}</div>}
      <div className="row" style={{marginBottom: 12}}>
        <button onClick={() => { setForm({...EMPTY}); setEditId(''); }}>Add Hadith</button>
        <select style={{width: 180}} value={filter} onChange={(e) => setFilter(e.target.value)} aria-label="Status filter">
          {['all', 'pending', 'verified', 'rejected'].map((s) => <option key={s}>{s}</option>)}
        </select>
      </div>

      {form && (
        <div className="card">
          <h2 style={{marginTop: 0}}>{editId ? 'Edit Hadith' : 'New Hadith'}</h2>
          <label>Category</label>
          <select value={form.category} onChange={(e) => set('category', e.target.value)}>{CATEGORIES.map((c) => <option key={c}>{c}</option>)}</select>
          <label>Arabic text (copy from the verified source)</label><textarea className="ar" value={form.arabic} onChange={(e) => set('arabic', e.target.value)} />
          <label>Bengali translation</label><textarea value={form.bn} onChange={(e) => set('bn', e.target.value)} />
          <label>English translation (optional)</label><textarea value={form.en} onChange={(e) => set('en', e.target.value)} />
          <label>Bengali explanation</label><textarea value={form.explanationBn} onChange={(e) => set('explanationBn', e.target.value)} />
          <label>Practical lesson (Bengali)</label><textarea value={form.lessonBn} onChange={(e) => set('lessonBn', e.target.value)} />
          <div className="grid">
            <div><label>Book</label><select value={form.book} onChange={(e) => set('book', e.target.value)}>{BOOKS.map((b) => <option key={b}>{b}</option>)}</select></div>
            <div><label>Hadith number</label><input value={form.number} onChange={(e) => set('number', e.target.value)} /></div>
            <div><label>Narrator (if verified)</label><input value={form.narrator} onChange={(e) => set('narrator', e.target.value)} /></div>
            <div><label>Grade and grader (e.g. Sahih – al-Albani)</label><input value={form.grade} onChange={(e) => set('grade', e.target.value)} /></div>
          </div>
          <p className="row">
            <button onClick={() => run(async () => { await call('saveContent', {collection: 'hadith', id: editId, data: form}); setForm(null); }, 'Saved as pending.')}>Save</button>
            <button className="sec" onClick={() => setForm(null)}>Cancel</button>
          </p>
        </div>
      )}

      <div className="card scroll">
        <table>
          <thead><tr><th>Bengali translation</th><th>Source</th><th>Status</th><th>Actions</th></tr></thead>
          <tbody>
            {loading ? <tr><td colSpan={4}>Loading…</td></tr> : list.length === 0 ? <tr><td colSpan={4} className="muted">No Hadith yet. Use “Add Hadith”.</td></tr> : list.map((h) => (
              <tr key={h.id}>
                <td style={{maxWidth: 420}}>{String(h.bn ?? '').slice(0, 160)}</td>
                <td>{h.book} {h.number}</td>
                <td><span className={`badge ${h.status}`}>{h.status}</span></td>
                <td className="row">
                  <button className="sec" onClick={() => { setEditId(h.id); setForm({...EMPTY, ...h}); }}>Edit</button>
                  {h.status !== 'verified' && <button onClick={() => run(() => call('setContentStatus', {collection: 'hadith', id: h.id, status: 'verified'}), 'Verified.')}>Verify</button>}
                  {h.status !== 'rejected' && <button className="sec" onClick={() => run(() => call('setContentStatus', {collection: 'hadith', id: h.id, status: 'rejected'}), 'Rejected.')}>Reject</button>}
                  <button className="bad" onClick={() => confirm('Delete this Hadith?') && run(() => call('deleteContent', {collection: 'hadith', id: h.id}), 'Deleted.')}>Delete</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
