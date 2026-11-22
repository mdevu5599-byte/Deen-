'use client';
import {useState} from 'react';
import {auth, call} from '@/lib/firebase';
import {fmt, useDocs} from '@/lib/hooks';
import {useRole} from '@/components/Shell';

export default function Users() {
  const {docs, loading, error, reload} = useDocs('users', {order: 'createdAt'});
  const admins = useDocs('admin_users');
  const statusDocs = useDocs('user_admin_status');
  const role = useRole();
  const currentUid = auth().currentUser?.uid;
  const [msg, setMsg] = useState('');
  const roleOf = (uid: string) => admins.docs.find((a) => a.id === uid)?.role ?? 'user';
  const disabledOf = (uid: string) => statusDocs.docs.find((a) => a.id === uid)?.disabled === true;

  async function setRole(uid: string, r: string) {
    setMsg('');
    try { await call('setUserRole', {uid, role: r}); setMsg('Role updated. The user must sign in again.'); admins.reload(); }
    catch (e: any) { setMsg(e?.message ?? 'Failed'); }
  }
  async function setDisabled(uid: string, disabled: boolean) {
    setMsg('');
    try {
      await call('setUserDisabled', {uid, disabled});
      setMsg(disabled ? 'User account disabled.' : 'User account re-enabled.');
      await statusDocs.reload();
    } catch (e: any) {
      setMsg(e?.message ?? 'Failed');
    }
  }

  return (
    <>
      <h1>Users & roles</h1>
      {role !== 'super_admin' && <p className="muted">Only a super admin can change roles.</p>}
      {msg && <div className="ok" role="status">{msg}</div>}
      {error && <div className="err">{error}</div>}
      <div className="card scroll">
        <table>
          <thead><tr><th>Name</th><th>Email</th><th>Type</th><th>Joined</th><th>Role</th><th>Account</th></tr></thead>
          <tbody>
            {loading ? <tr><td colSpan={6}>Loading…</td></tr> : docs.map((u) => (
              <tr key={u.id}>
                <td>{u.displayName}</td><td>{u.email}</td><td><span className="badge">{u.accountType}</span></td>
                <td>{fmt(u.createdAt)}</td>
                <td>
                  <select disabled={role !== 'super_admin'} value={roleOf(u.id)} onChange={(e) => setRole(u.id, e.target.value)} aria-label={`Role for ${u.email}`}>
                    <option value="user">user</option><option value="admin">admin</option><option value="super_admin">super_admin</option>
                  </select>
                </td>
                <td>
                  <span className={`badge ${disabledOf(u.id) ? 'rejected' : 'verified'}`}>
                    {disabledOf(u.id) ? 'Disabled' : 'Active'}
                  </span>
                  {role === 'super_admin' && (
                    <button
                      className={disabledOf(u.id) ? 'sec' : 'bad'}
                      style={{marginTop: 6}}
                      disabled={u.id === currentUid}
                      onClick={() => setDisabled(u.id, !disabledOf(u.id))}
                    >
                      {disabledOf(u.id) ? 'Enable' : 'Disable'}
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <button className="sec" onClick={reload}>Refresh</button>
    </>
  );
}
