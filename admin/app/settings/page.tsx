'use client';
import {useEffect, useState} from 'react';
import {doc, getDoc} from 'firebase/firestore';
import {call, db} from '@/lib/firebase';

const METHODS = ['karachi', 'muslim_world_league', 'egyptian', 'umm_al_qura', 'dubai', 'qatar', 'kuwait', 'singapore', 'turkey', 'tehran', 'north_america', 'moon_sighting_committee'];

export default function Settings() {
  const [s, setS] = useState<any>({defaultLanguage: 'bn', defaultMethod: 'karachi', defaultMadhab: 'hanafi', maxDailyNotifications: 8, maintenanceMode: false});
  const [msg, setMsg] = useState('');
  const [err, setErr] = useState('');
  useEffect(() => { getDoc(doc(db(), 'app_settings', 'global')).then((d) => d.exists() && setS((p: any) => ({...p, ...d.data()}))).catch(() => {}); }, []);
  return (
    <>
      <h1>Global settings</h1>
      <p className="muted">Defaults for new users, including prayer calculation defaults.</p>
      {msg && <div className="ok">{msg}</div>}{err && <div className="err">{err}</div>}
      <div className="card">
        <label>Default language</label><select value={s.defaultLanguage} onChange={(e) => setS({...s, defaultLanguage: e.target.value})}><option value="bn">বাংলা</option><option value="en">English</option><option value="ar">العربية</option></select>
        <label>Default calculation method</label><select value={s.defaultMethod} onChange={(e) => setS({...s, defaultMethod: e.target.value})}>{METHODS.map((m) => <option key={m}>{m}</option>)}</select>
        <label>Default Asr calculation</label><select value={s.defaultMadhab} onChange={(e) => setS({...s, defaultMadhab: e.target.value})}><option value="hanafi">Hanafi</option><option value="shafi">Shafi'i / Maliki / Hanbali</option></select>
        <label>Maximum daily content notifications</label><input type="number" min={1} max={30} value={s.maxDailyNotifications} onChange={(e) => setS({...s, maxDailyNotifications: e.target.value})} />
        <label><input type="checkbox" style={{width: 'auto'}} checked={!!s.maintenanceMode} onChange={(e) => setS({...s, maintenanceMode: e.target.checked})} /> Maintenance mode</label>
        <p><button onClick={async () => { setMsg(''); setErr(''); try { await call('updateAppSettings', s); setMsg('Saved.'); } catch (e: any) { setErr(e?.message ?? 'Failed'); } }}>Save settings</button></p>
      </div>
    </>
  );
}
