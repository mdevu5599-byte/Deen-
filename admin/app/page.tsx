'use client';
import {useEffect, useState} from 'react';
import {count} from '@/lib/hooks';

export default function Overview() {
  const [s, setS] = useState<Record<string, number>>({});
  useEffect(() => {
    (async () => {
      const r: Record<string, number> = {};
      r.users = await count('users');
      r.personal = await count('users', ['accountType', '==', 'personal']);
      r.public = await count('users', ['accountType', '==', 'public']);
      r.admins = await count('admin_users');
      r.hadithVerified = await count('hadith', ['status', '==', 'verified']);
      r.hadithPending = await count('hadith', ['status', '==', 'pending']);
      r.remindersVerified = await count('reminders', ['status', '==', 'verified']);
      r.jobsScheduled = await count('notification_jobs', ['status', '==', 'scheduled']);
      r.jobsSent = await count('notification_jobs', ['status', '==', 'sent']);
      setS(r);
    })();
  }, []);
  const show = (k: string) => (s[k] === undefined ? '…' : s[k] < 0 ? 'n/a' : s[k]);
  const items: [string, string][] = [
    ['users', 'Total users'], ['personal', 'Personal accounts'], ['public', 'Public accounts'], ['admins', 'Admins'],
    ['hadithVerified', 'Verified Hadith'], ['hadithPending', 'Hadith awaiting review'],
    ['remindersVerified', 'Published reminders'], ['jobsScheduled', 'Scheduled notifications'], ['jobsSent', 'Sent notifications'],
  ];
  return (
    <>
      <h1>Overview</h1>
      <div className="grid">
        {items.map(([k, l]) => <div className="card stat" key={k}><b>{show(k)}</b><span className="muted">{l}</span></div>)}
      </div>
      <p className="muted">Counts come from Firestore aggregation queries. “n/a” means the query failed (missing index or permission).</p>
    </>
  );
}
