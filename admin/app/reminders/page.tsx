'use client';
import {useState} from 'react';
import {call} from '@/lib/firebase';
import {useDocs} from '@/lib/hooks';

const GROUPS = ['akhirah', 'reminder', 'tawbah', 'night'];
const EMPTY = {group: 'reminder', category: '', bn: '', lessonBn: ''};

export default function Reminders() {
  const {docs, loading, error, reload} = useDocs('reminders', {order: 'updatedAt'});
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

  return (
    <>
      <h1>Reminders</h1>
      <p className="muted">
        Reminders added here are <b>original reflections</b> (kind “original”) and are shown to users as
        “not a Hadith or verse”. To quote a Hadith, publish it in the Hadith section instead.
      </p>
      {msg && <div className="ok" role="status">{msg}</div>}
      {(err || error) && <div className="err" role="alert">{err || error}</div>}

      <div className="row" style={{marginBottom: 12}}>
        <button onClick={() => { setForm({...EMPTY}); setEditId(''); }}>Add reminder</button>
      </div>

      {form && (
        <div className="card">
          <h2 style={{marginTop: 0}}>{editId ? 'Edit reminder' : 'New reminder'}</h2>
          <label>Group</label>
          <select value={form.group} onChange={(e) => set('group', e.target.value)}>
            {GROUPS.map((group) => <option key={group}>{group}</option>)}
          </select>
          <label>Category</label>
          <input value={form.category} onChange={(e) => set('category', e.target.value)} />
          <label>Bengali text</label>
          <textarea value={form.bn} onChange={(e) => set('bn', e.target.value)} />
          <label>Practical lesson (Bengali)</label>
          <textarea value={form.lessonBn} onChange={(e) => set('lessonBn', e.target.value)} />
          <p className="row">
            <button onClick={() => run(async () => {
              await call('saveContent', {collection: 'reminders', id: editId, data: {...form, kind: 'original'}});
              setForm(null);
              setEditId('');
            }, 'Saved as pending.')}>Save as pending</button>
            <button className="sec" onClick={() => { setForm(null); setEditId(''); }}>Cancel</button>
          </p>
        </div>
      )}

      <div className="card scroll">
        <table>
          <thead><tr><th>Text</th><th>Group</th><th>Status</th><th>Actions</th></tr></thead>
          <tbody>
            {loading ? <tr><td colSpan={4}>Loading…</td></tr> :
              docs.length === 0 ? <tr><td colSpan={4} className="muted">No reminders yet.</td></tr> :
              docs.map((reminder) => (
                <tr key={reminder.id}>
                  <td style={{maxWidth: 420}}>{reminder.bn}</td>
                  <td>{reminder.group}</td>
                  <td><span className={`badge ${reminder.status}`}>{reminder.status}</span></td>
                  <td className="row">
                    <button className="sec" onClick={() => {
                      setEditId(reminder.id);
                      setForm({...EMPTY, ...reminder});
                    }}>Edit</button>
                    {reminder.status !== 'verified' && (
                      <button onClick={() => run(
                        () => call('setContentStatus', {collection: 'reminders', id: reminder.id, status: 'verified'}),
                        'Approved.',
                      )}>Approve</button>
                    )}
                    {reminder.status !== 'rejected' && (
                      <button className="sec" onClick={() => run(
                        () => call('setContentStatus', {collection: 'reminders', id: reminder.id, status: 'rejected'}),
                        'Rejected.',
                      )}>Reject</button>
                    )}
                    <button className="bad" onClick={() =>
                      window.confirm('Delete this reminder?') && run(
                        () => call('deleteContent', {collection: 'reminders', id: reminder.id}),
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
