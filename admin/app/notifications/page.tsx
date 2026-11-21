'use client';
import {useState} from 'react';
import {call} from '@/lib/firebase';
import {fmt, useDocs} from '@/lib/hooks';

export default function Notifications() {
  const jobs = useDocs('notification_jobs', {order: 'createdAt'});
  const logs = useDocs('notification_logs', {order: 'createdAt', max: 50});
  const [f, setF] = useState({title: '', body: '', audience: 'all', scheduleAt: ''});
  const [token, setToken] = useState('');
  const [msg, setMsg] = useState('');
  const [err, setErr] = useState('');
  async function run(fn: () => Promise<any>, ok: string) {
    setMsg(''); setErr('');
    try { await fn(); setMsg(ok); jobs.reload(); logs.reload(); } catch (e: any) { setErr(e?.message ?? 'Failed'); }
  }
  return (
    <>
      <h1>Notifications</h1>
      <p className="muted">Push messages go through Firebase Cloud Messaging. Prayer-time notifications are scheduled locally on each device and are not sent from here.</p>
      {msg && <div className="ok">{msg}</div>}{err && <div className="err">{err}</div>}
      <div className="card">
        <label>Title (Bengali)</label><input value={f.title} onChange={(e) => setF({...f, title: e.target.value})} />
        <label>Message (Bengali)</label><textarea value={f.body} onChange={(e) => setF({...f, body: e.target.value})} />
        <div className="grid">
          <div><label>Audience</label><select value={f.audience} onChange={(e) => setF({...f, audience: e.target.value})}><option value="all">All users</option><option value="personal">Personal users</option><option value="public">Public users</option></select></div>
          <div><label>Schedule (leave empty to send now)</label><input type="datetime-local" value={f.scheduleAt} onChange={(e) => setF({...f, scheduleAt: e.target.value})} /></div>
        </div>
        <p><button onClick={() => run(() => call('createNotification', {...f, scheduleAt: f.scheduleAt ? new Date(f.scheduleAt).toISOString() : null}), f.scheduleAt ? 'Scheduled.' : 'Sent.')}>{f.scheduleAt ? 'Schedule' : 'Send now'}</button></p>
        <label>Send a test to one device (FCM token)</label>
        <div className="row"><input value={token} onChange={(e) => setToken(e.target.value)} style={{flex: 1}} /><button className="sec" onClick={() => run(() => call('sendTestNotification', {token}), 'Test sent.')}>Send test</button></div>
      </div>
      <h2>Jobs</h2>
      <div className="card scroll"><table><thead><tr><th>Title</th><th>Audience</th><th>Status</th><th>Scheduled</th></tr></thead>
        <tbody>{jobs.docs.map((j) => <tr key={j.id}><td>{j.title}</td><td>{j.audience}</td><td><span className="badge">{j.status}</span></td><td>{fmt(j.scheduleAt)}</td></tr>)}</tbody></table></div>
      <h2>Delivery log</h2>
      <div className="card scroll"><table><thead><tr><th>When</th><th>Title</th><th>Result</th></tr></thead>
        <tbody>{logs.docs.map((l) => <tr key={l.id}><td>{fmt(l.createdAt)}</td><td>{l.title}</td><td>{l.ok ? 'delivered to FCM' : `failed: ${l.error}`}</td></tr>)}</tbody></table></div>
    </>
  );
}
