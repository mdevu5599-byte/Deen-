'use client';
import {useEffect, useState} from 'react';
import {usePathname} from 'next/navigation';
import Link from 'next/link';
import {onAuthStateChanged, signInWithEmailAndPassword, signOut} from 'firebase/auth';
import {auth, isConfigured} from '@/lib/firebase';

const NAV: [string, string][] = [
  ['/', 'Overview'], ['/users', 'Users & roles'], ['/hadith', 'Hadith'], ['/reminders', 'Reminders'],
  ['/categories', 'Categories'], ['/quran', 'Quran content'], ['/notifications', 'Notifications'],
  ['/audit', 'Audit logs'], ['/settings', 'Global settings'],
];

export type Role = 'user' | 'admin' | 'super_admin';

export default function Shell({children}: {children: React.ReactNode}) {
  const path = usePathname();
  const [state, setState] = useState<'loading' | 'out' | 'denied' | 'in'>('loading');
  const [role, setRole] = useState<Role>('user');
  const [email, setEmail] = useState('');
  const [pw, setPw] = useState('');
  const [err, setErr] = useState('');

  useEffect(() => {
    if (!isConfigured) { setState('out'); return; }
    return onAuthStateChanged(auth(), async (u) => {
      if (!u) { setState('out'); return; }
      // Role comes from the signed ID token claims (set only by the setUserRole function).
      const t = await u.getIdTokenResult(true);
      const r = ((t.claims.role as Role) || 'user');
      setRole(r);
      setState(r === 'admin' || r === 'super_admin' ? 'in' : 'denied');
    });
  }, []);

  if (!isConfigured) {
    return <div className="main"><h1>DEEN Admin</h1><div className="card">Firebase is not configured. Copy <code>.env.example</code> to <code>.env.local</code> and fill in the web app config (see README).</div></div>;
  }
  if (state === 'loading') return <div className="main muted">Loading…</div>;
  if (state === 'out') {
    return (
      <div className="main" style={{maxWidth: 420}}>
        <h1>DEEN Admin</h1>
        <div className="card">
          <label htmlFor="e">Email</label><input id="e" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
          <label htmlFor="p">Password</label><input id="p" type="password" value={pw} onChange={(e) => setPw(e.target.value)} />
          {err && <div className="err" role="alert">{err}</div>}
          <p><button onClick={async () => {
            setErr('');
            try { await signInWithEmailAndPassword(auth(), email, pw); } catch { setErr('Email or password is incorrect.'); }
          }}>Sign in</button></p>
        </div>
      </div>
    );
  }
  if (state === 'denied') {
    return (
      <div className="main" style={{maxWidth: 520}}>
        <h1>Access denied</h1>
        <div className="card">This account does not have an administrator role. Ask a super admin to assign one.</div>
        <button className="sec" onClick={() => signOut(auth())}>Sign out</button>
      </div>
    );
  }
  return (
    <div className="shell">
      <aside className="side">
        <div className="brand">DEEN</div>
        <nav className="nav" aria-label="Main">
          {NAV.map(([href, label]) => (
            <Link key={href} href={href} className={path === href || path === href + '/' ? 'on' : ''}>{label}</Link>
          ))}
        </nav>
        <p className="muted" style={{padding: '12px 12px 0', fontSize: 13}}>Role: {role}</p>
        <button className="sec" style={{margin: '0 12px'}} onClick={() => signOut(auth())}>Sign out</button>
      </aside>
      <main className="main"><RoleContext.Provider value={role}>{children}</RoleContext.Provider></main>
    </div>
  );
}

import {createContext, useContext} from 'react';
export const RoleContext = createContext<Role>('user');
export const useRole = () => useContext(RoleContext);
