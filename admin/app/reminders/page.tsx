'use client';
import {useState} from 'react';
import {call} from '@/lib/firebase';
import {useDocs} from '@/lib/hooks';

const GROUPS = ['akhirah', 'reminder', 'tawbah', 'night'];

export default function Reminders() {
  const {docs, loading, error, reload} = useDocs('reminders', {order: 'updatedAt'});
  const [f, setF] = useState({group: 'reminder', category: '', bn: '', lessonBn: ''});
  const [msg, setMsg] = useState('');
  const [err, setErr] = useState('');
  async function run(fn: () => Promise<any>, ok: string) {
    setMsg(''); setErr('');
    try { await fn(); setMsg(ok); await reload(); } catch (e: any) { setErr(e?.message ?? 'Failed'); }
  }
  return (
    <>
      <h1>Reminders</h1>
      <p className="muted">Reminders added here are <b>original reflections</b> (kind “original”) and are shown to users as “not a Hadith or verse”. To quote a Hadith, publish it in the Hadith section instead.</p>
      {msg && <div className="ok">{msg}</div>}{(err || error) && <div className="err">{err || error}</div>}
      <div className="card">
        <label>Group</label><select value={f.group} onChange={(e) => setF({...f, group: e.target.value})}>{GROUPS.map((g) => <option key={g}>{g}</option>)}</select>
        <label>Category</label><input value={f.category} onChange={(e) => setF({...f, category: e.target.value})} />
        <label>Bengali text</label><textarea value={f.bn} onChange={(e) => setF({...f, bn: e.target.value})} />
        <label>Practical lesson (Bengali)</label><textarea value={f.lessonBn} onChange={(e) => setF({...f, lessonBn: e.target.value})} />
        <p><button onClick={() => run(async () => { await call('saveContent', {collection: 'reminders', data: {...f, kind: 'original'}}); setF({...f, bn: '', lessonBn: ''}); }, 'Saved as pending.')}>Save reminder</button></p>
      </div>
      <div className="card scroll"><table>
        <thead><tr><th>Text</th><th>Group</th><th>Status</th><th>Actions</th></tr></thead>
        <tbody>{loading ? <tr><td colSpan={4}>Loading…</td></tr> : docs.map((r) => (
          <tr key={r.id}><td style={{maxWidth: 420}}>{r.bn}</td><td>{r.group}</td><td><span className={`badge ${r.status}`}>{r.status}</span></td>
            <td className="row">
              {r.status !== 'verified' && <button onClick={() => run(() => call('setContentStatus', {collection: 'reminders', id: r.id, status: 'verified'}), 'Approved.')}>Approve</button>}
              {r.status !== 'rejected' && <button className="sec" onClick={() => run(() => call('setContentStatus', {collection: 'reminders', id: r.id, status: 'rejected'}), 'Rejected.')}>Reject</button>}
              <button className="bad" onClick={() => confirm('Delete?') && run(() => call('deleteContent', {collection: 'reminders', id: r.id}), 'Deleted.')}>Delete</button>
            </td></tr>))}</tbody></table></div>
    </>
  );
}
