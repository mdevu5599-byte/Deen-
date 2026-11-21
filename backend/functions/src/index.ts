import {initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {FieldValue, getFirestore, Timestamp} from 'firebase-admin/firestore';
import {getMessaging} from 'firebase-admin/messaging';
import {HttpsError, onCall, CallableRequest} from 'firebase-functions/v2/https';
import {onSchedule} from 'firebase-functions/v2/scheduler';
import {clean, ROLES, sanitizeHadith, STATUSES, verificationProblems} from './validators';

initializeApp();
const db = getFirestore();

// ---------------------------------------------------------------- helpers
type Role = 'user' | 'admin' | 'super_admin';

function callerRole(req: CallableRequest): Role {
  return ((req.auth?.token as any)?.role as Role) || 'user';
}
function requireAuth(req: CallableRequest): string {
  if (!req.auth) throw new HttpsError('unauthenticated', 'Sign in required.');
  return req.auth.uid;
}
function requireAdmin(req: CallableRequest): string {
  const uid = requireAuth(req);
  const r = callerRole(req);
  if (r !== 'admin' && r !== 'super_admin') throw new HttpsError('permission-denied', 'Admin only.');
  return uid;
}
function requireSuper(req: CallableRequest): string {
  const uid = requireAuth(req);
  if (callerRole(req) !== 'super_admin') throw new HttpsError('permission-denied', 'Super admin only.');
  return uid;
}
async function audit(actor: string, action: string, target: string, meta: Record<string, unknown> = {}) {
  await db.collection('audit_logs').add({actor, action, target, meta, createdAt: FieldValue.serverTimestamp()});
}

const CONTENT = ['hadith', 'reminders', 'duas'] as const;
type ContentCol = (typeof CONTENT)[number];
function col(v: unknown): ContentCol {
  if (!CONTENT.includes(v as ContentCol)) throw new HttpsError('invalid-argument', 'Unknown collection.');
  return v as ContentCol;
}

// ---------------------------------------------------------------- roles
/** Only a super admin can assign roles. The role is stored as a custom claim. */
export const setUserRole = onCall(async (req) => {
  const actor = requireSuper(req);
  const uid = clean(req.data?.uid, 128);
  const role = clean(req.data?.role, 20);
  if (!uid || !(ROLES as readonly string[]).includes(role)) throw new HttpsError('invalid-argument', 'Bad uid or role.');
  if (uid === actor && role !== 'super_admin') throw new HttpsError('failed-precondition', 'Cannot demote yourself.');
  await getAuth().setCustomUserClaims(uid, {role});
  await getAuth().revokeRefreshTokens(uid);
  if (role === 'user') {
    await db.collection('admin_users').doc(uid).delete();
  } else {
    await db.collection('admin_users').doc(uid).set({uid, role, assignedBy: actor, updatedAt: FieldValue.serverTimestamp()});
  }
  await audit(actor, 'setUserRole', uid, {role});
  return {ok: true};
});

// ---------------------------------------------------------------- content
/** Create or update a content record. New/edited records are saved as 'pending'. */
export const saveContent = onCall(async (req) => {
  const actor = requireAdmin(req);
  const c = col(req.data?.collection);
  const id = clean(req.data?.id, 60);
  let payload: Record<string, unknown>;
  if (c === 'hadith') {
    payload = {...sanitizeHadith(req.data?.data)};
  } else if (c === 'reminders') {
    const d = req.data?.data ?? {};
    payload = {
      group: clean(d.group, 30), category: clean(d.category, 100), kind: d.kind === 'quote' ? 'quote' : 'original',
      bn: clean(d.bn, 3000), en: clean(d.en, 3000) || null, lessonBn: clean(d.lessonBn, 1500),
      sourceHadithId: clean(d.sourceHadithId, 60) || null,
    };
    if (!payload.bn) throw new HttpsError('invalid-argument', 'Bengali text is required.');
  } else {
    const d = req.data?.data ?? {};
    payload = {
      title: clean(d.title, 150), category: clean(d.category, 60), arabic: clean(d.arabic, 4000),
      pronunciationBn: clean(d.pronunciationBn, 2000), bn: clean(d.bn, 3000), reference: clean(d.reference, 200),
    };
  }
  const ref = id ? db.collection(c).doc(id) : db.collection(c).doc();
  const existing = id ? await ref.get() : null;
  await ref.set({
    ...payload,
    status: 'pending',               // editing always sends content back to review
    updatedBy: actor,
    updatedAt: FieldValue.serverTimestamp(),
    ...(existing?.exists ? {} : {createdBy: actor, createdAt: FieldValue.serverTimestamp()}),
  }, {merge: false});
  await audit(actor, 'saveContent', `${c}/${ref.id}`);
  return {id: ref.id, status: 'pending'};
});

/** Approve / reject. Approval re-validates the record; a different admin should approve than authored. */
export const setContentStatus = onCall(async (req) => {
  const actor = requireAdmin(req);
  const c = col(req.data?.collection);
  const id = clean(req.data?.id, 60);
  const status = clean(req.data?.status, 20);
  if (!id || !(STATUSES as readonly string[]).includes(status)) throw new HttpsError('invalid-argument', 'Bad id/status.');
  const ref = db.collection(c).doc(id);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'No such record.');
  const data = snap.data()!;
  if (status === 'verified') {
    if (c === 'hadith') {
      const problems = verificationProblems(sanitizeHadith(data));
      if (problems.length) throw new HttpsError('failed-precondition', problems.join('; '));
    } else if (c === 'duas') {
      if (!data.arabic || !data.bn || !data.reference) {
        throw new HttpsError('failed-precondition', 'Dua needs Arabic, Bengali meaning and a reference.');
      }
    }
    if (data.createdBy && data.createdBy === actor && callerRole(req) !== 'super_admin') {
      throw new HttpsError('failed-precondition', 'A second admin must verify content you authored.');
    }
  }
  await ref.update({
    status,
    reviewedBy: actor,
    reviewedAt: FieldValue.serverTimestamp(),
    reviewNote: clean(req.data?.note, 500) || null,
  });
  await audit(actor, 'setContentStatus', `${c}/${id}`, {status});
  return {ok: true};
});

export const deleteContent = onCall(async (req) => {
  const actor = requireAdmin(req);
  const c = col(req.data?.collection);
  const id = clean(req.data?.id, 60);
  if (!id) throw new HttpsError('invalid-argument', 'id required.');
  await db.collection(c).doc(id).delete();
  await audit(actor, 'deleteContent', `${c}/${id}`);
  return {ok: true};
});

// ---------------------------------------------------------------- notifications
async function deliver(job: FirebaseFirestore.DocumentSnapshot) {
  const j = job.data()!;
  const topic = j.audience === 'all' ? 'all' : `type_${j.audience}`;
  try {
    const id = await getMessaging().send({
      topic,
      notification: {title: j.title, body: j.body},
      data: {category: String(j.category ?? 'general'), lang: 'bn'},
      android: {priority: 'high'},
    });
    await job.ref.update({status: 'sent', sentAt: FieldValue.serverTimestamp(), messageId: id});
    await db.collection('notification_logs').add({jobId: job.id, topic, title: j.title, ok: true, createdAt: FieldValue.serverTimestamp()});
  } catch (e: any) {
    await job.ref.update({status: 'failed', error: String(e?.message ?? e)});
    await db.collection('notification_logs').add({jobId: job.id, topic, title: j.title, ok: false, error: String(e?.message ?? e), createdAt: FieldValue.serverTimestamp()});
  }
}

export const createNotification = onCall(async (req) => {
  const actor = requireAdmin(req);
  const d = req.data ?? {};
  const title = clean(d.title, 120);
  const body = clean(d.body, 600);
  const audience = ['all', 'personal', 'public'].includes(d.audience) ? d.audience : 'all';
  if (!title || !body) throw new HttpsError('invalid-argument', 'Title and body are required.');
  const when = d.scheduleAt ? new Date(d.scheduleAt) : null;
  const ref = db.collection('notification_jobs').doc();
  await ref.set({
    title, body, audience, category: clean(d.category, 40) || 'general',
    status: when && !isNaN(when.getTime()) ? 'scheduled' : 'queued',
    scheduleAt: when && !isNaN(when.getTime()) ? Timestamp.fromDate(when) : null,
    createdBy: actor, createdAt: FieldValue.serverTimestamp(),
  });
  await audit(actor, 'createNotification', ref.id);
  if (!when) await deliver(await ref.get());
  return {id: ref.id};
});

export const sendTestNotification = onCall(async (req) => {
  const actor = requireAdmin(req);
  const token = clean(req.data?.token, 400);
  if (!token) throw new HttpsError('invalid-argument', 'Device token required.');
  const id = await getMessaging().send({
    token,
    notification: {title: 'পরীক্ষামূলক নোটিফিকেশন', body: 'DEEN নোটিফিকেশন সঠিকভাবে কাজ করছে।'},
  });
  await audit(actor, 'sendTestNotification', 'device');
  return {messageId: id};
});

export const processNotificationJobs = onSchedule('every 5 minutes', async () => {
  const due = await db.collection('notification_jobs')
    .where('status', '==', 'scheduled').where('scheduleAt', '<=', Timestamp.now()).limit(25).get();
  for (const d of due.docs) await deliver(d);
});

// ---------------------------------------------------------------- account deletion
const OWNED_BY_UID_FIELD = ['prayer_records', 'ibadah_records', 'tasbih_records', 'journals'];
const OWNED_BY_DOC_ID = ['users', 'user_settings', 'notification_preferences', 'prayer_settings'];

/** Permanently deletes the caller's Firestore data and their Auth account. */
export const deleteMyAccount = onCall(async (req) => {
  const uid = requireAuth(req);
  for (const c of OWNED_BY_UID_FIELD) {
    const snap = await db.collection(c).where('uid', '==', uid).get();
    for (let i = 0; i < snap.docs.length; i += 400) {
      const batch = db.batch();
      snap.docs.slice(i, i + 400).forEach((d) => batch.delete(d.ref));
      await batch.commit();
    }
  }
  for (const c of OWNED_BY_DOC_ID) await db.collection(c).doc(uid).delete();
  await db.collection('admin_users').doc(uid).delete();
  await getAuth().deleteUser(uid);
  await audit(uid, 'deleteMyAccount', uid);
  return {ok: true};
});

// ---------------------------------------------------------------- global settings
export const updateAppSettings = onCall(async (req) => {
  const actor = requireAdmin(req);
  const d = req.data ?? {};
  const allowedMethods = ['karachi', 'muslim_world_league', 'egyptian', 'umm_al_qura', 'dubai', 'qatar', 'kuwait', 'singapore', 'turkey', 'tehran', 'north_america', 'moon_sighting_committee'];
  const settings = {
    defaultLanguage: ['bn', 'en', 'ar'].includes(d.defaultLanguage) ? d.defaultLanguage : 'bn',
    defaultMethod: allowedMethods.includes(d.defaultMethod) ? d.defaultMethod : 'karachi',
    defaultMadhab: d.defaultMadhab === 'shafi' ? 'shafi' : 'hanafi',
    maxDailyNotifications: Math.min(Math.max(parseInt(d.maxDailyNotifications, 10) || 8, 1), 30),
    maintenanceMode: d.maintenanceMode === true,
    updatedBy: actor,
    updatedAt: FieldValue.serverTimestamp(),
  };
  await db.collection('app_settings').doc('global').set(settings, {merge: true});
  await audit(actor, 'updateAppSettings', 'global');
  return {ok: true};
});
