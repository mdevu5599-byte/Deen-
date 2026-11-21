'use client';
import {fmt, useDocs} from '@/lib/hooks';

export default function Audit() {
  const {docs, loading, error} = useDocs('audit_logs', {order: 'createdAt', max: 200});
  return (
    <>
      <h1>Audit logs</h1>
      <p className="muted">Append-only. Written by Cloud Functions; no client can modify entries.</p>
      {error && <div className="err">{error}</div>}
      <div className="card scroll"><table><thead><tr><th>When</th><th>Actor</th><th>Action</th><th>Target</th></tr></thead>
        <tbody>{loading ? <tr><td colSpan={4}>Loading…</td></tr> : docs.map((a) => <tr key={a.id}><td>{fmt(a.createdAt)}</td><td>{a.actor}</td><td>{a.action}</td><td>{a.target}</td></tr>)}</tbody></table></div>
    </>
  );
}
