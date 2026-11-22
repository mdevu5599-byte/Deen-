'use client';
import {useState} from 'react';
import {call} from '@/lib/firebase';
import {useDocs} from '@/lib/hooks';

const EMPTY = {title: '', category: '', arabic: '', pronunciationBn: '', bn: '', reference: ''};

export default function Duas() {
  const {docs, loading, error, reload} = useDocs('duas', {order: 'updatedAt'});
  const [filter, setFilter] = useState('all');
  const [form, setForm] = useState<any>(null);
  const [editId, setEditId] = useState('');
  const [msg, setMsg] = useState('');
  const [err, setErr] = useState('');
  const set = (key: string, value: string) => setForm((current: any) => ({...current, [key]: value}));

  async function run(fn: () => Promise<any>, success: string) {
    setMsg('');
    setErr('');
    try {
      await fn();
      setMsg(success);
      await reload();
    } catch (e: any) {
      setErr(e?.message ?? 'Failed');
    }
  }

  const visible = docs.filter((dua) => filter === 'all' || dua.status === filter);

  return (
    <>
      <h1>Duas</h1>
      <p className="muted">
        Add Duas only with a traceable reference. New or edited entries remain pending until reviewed.
        The app does not invent Quran or Hadith wording.
      </p>
      {msg && <div className="ok" role="status">{msg}</div>}
      {(err || error) && <div className="err" role="alert">{err || error}</div>}
      <div className="row" style={{marginBottom: 12}}>
        <button onClick={() => { setForm({...EMPTY}); setEditId(''); }}>Add Dua</button>
        <select aria-label="Status filter" style={{width: 180}} value={filter} onChange={(e) => setFilter(e.target.value)}>
          {['all', 'pending', 'verified', 'rejected'].map((status) => <option key={status}>{status}</option>)}
        </select>
      </div>

      {form && (
        <div className="card">
          <h2 style={{marginTop: 0}}>{editId ? 'Edit Dua' : 'New Dua'}</h2>
          <label>Title</label>
          <input value={form.title} onChange={(e) => set('title', e.target.value)} />
          <label>Category</label>
          <input value={form.category} onChange={(e) => set('category', e.target.value)} />
          <label>Arabic text (copy from the verified source)</label>
          <textarea className="ar" value={form.arabic} onChange={(e) => set('arabic', e.target.value)} />
          <label>Bengali pronunciation (optional)</label>
          <textarea value={form.pronunciationBn} onChange={(e) => set('pronunciationBn', e.target.value)} />
          <label>Bengali meaning</label>
          <textarea value={form.bn} onChange={(e) => set('bn', e.target.value)} />
          <label>Source / reference</label>
          <input value={form.reference} onChange={(e) => set('reference', e.target.value)} />
          <p className="row">
            <button onClick={() => run(async () => {
              await call('saveContent', {collection: 'duas', id: editId, data: form});
              setForm(null);
              setEditId('');
            }, 'Saved as pending.')}>Save as pending</button>
            <button className="sec" onClick={() => { setForm(null); setEditId(''); }}>Cancel</button>
          </p>
        </div>
      )}

      <div className="card scroll">
        <table>
          <thead><tr><th>Dua</th><th>Reference</th><th>Status</th><th>Actions</th></tr></thead>
          <tbody>
            {loading ? <tr><td colSpan={4}>Loading…</td></tr> :
              visible.length === 0 ? <tr><td colSpan={4} className="muted">No Duas in this status.</td></tr> :
              visible.map((dua) => (
                <tr key={dua.id}>
                  <td style={{maxWidth: 420}}>
                    <b>{dua.title}</b>
                    <div>{dua.bn}</div>
                  </td>
                  <td>{dua.reference}</td>
                  <td><span className={`badge ${dua.status}`}>{dua.status}</span></td>
                  <td className="row">
                    <button className="sec" onClick={() => { setEditId(dua.id); setForm({...EMPTY, ...dua}); }}>Edit</button>
                    {dua.status !== 'verified' && (
                      <button onClick={() => run(
                        () => call('setContentStatus', {collection: 'duas', id: dua.id, status: 'verified'}),
                        'Verified.',
                      )}>Verify</button>
                    )}
                    {dua.status !== 'rejected' && (
                      <button className="sec" onClick={() => run(
                        () => call('setContentStatus', {collection: 'duas', id: dua.id, status: 'rejected'}),
                        'Rejected.',
                      )}>Reject</button>
                    )}
                    <button className="bad" onClick={() =>
                      window.confirm('Delete this Dua?') && run(
                        () => call('deleteContent', {collection: 'duas', id: dua.id}),
                        'Deleted.',
                      )
                    }>Delete</button>
                  </td>
                </tr>
              ))
            }
          </tbody>
        </table>
      </div>
    </>
  );
}
