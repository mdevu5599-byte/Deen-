import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {after, test} from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const projectId = 'demo-deen-firestore-rules';
const rules = readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8');
const env = await initializeTestEnvironment({
  projectId,
  firestore: {rules},
});

after(async () => {
  await env.cleanup();
});

const alice = env.authenticatedContext('alice', {role: 'user'}).firestore();
const bob = env.authenticatedContext('bob', {role: 'user'}).firestore();
const admin = env.authenticatedContext('admin-user', {role: 'admin'}).firestore();
const superAdmin = env.authenticatedContext('root-user', {role: 'super_admin'}).firestore();
const guest = env.unauthenticatedContext().firestore();

await env.withSecurityRulesDisabled(async (context) => {
  const firestore = context.firestore();
  await setDoc(doc(firestore, 'users/alice'), {
    uid: 'alice',
    email: 'alice@example.test',
    displayName: 'Alice',
    accountType: 'personal',
    language: 'bn',
  });
  await setDoc(doc(firestore, 'users/legacy'), {
    uid: 'legacy',
    email: 'legacy@example.test',
    displayName: 'Legacy user',
  });
  await setDoc(doc(firestore, 'user_settings/alice'), {
    uid: 'alice',
    language: 'bn',
  });
  await setDoc(doc(firestore, 'journals/alice_2026-11-23'), {
    uid: 'alice',
    date: '2026-11-23',
    answers: {note: 'private'},
    clientUpdatedAt: 100,
  });
  await setDoc(doc(firestore, 'duas/approved'), {
    status: 'verified',
    arabic: 'verified sample text',
    bn: 'verified translation',
    reference: 'test-fixture-only',
  });
  await setDoc(doc(firestore, 'duas/pending'), {
    status: 'pending',
    arabic: 'unpublished text',
    bn: 'unpublished translation',
    reference: 'test-fixture-only',
  });
  await setDoc(doc(firestore, 'user_admin_status/alice'), {
    uid: 'alice',
    disabled: true,
  });
});

test('a user can read and update only their own settings', async () => {
  await assertSucceeds(getDoc(doc(alice, 'user_settings/alice')));
  await assertFails(getDoc(doc(bob, 'user_settings/alice')));
  await assertSucceeds(setDoc(doc(alice, 'user_settings/alice'), {
    uid: 'alice',
    language: 'en',
  }, {merge: true}));
  await assertFails(setDoc(doc(alice, 'user_settings/alice'), {
    uid: 'alice',
    role: 'super_admin',
  }, {merge: true}));
});

test('a legacy profile may fill a missing account type once, but cannot later change it', async () => {
  await assertSucceeds(setDoc(doc(env.authenticatedContext('legacy', {role: 'user'}).firestore(), 'users/legacy'), {
    uid: 'legacy',
    email: 'legacy@example.test',
    displayName: 'Legacy user',
    accountType: 'personal',
  }, {merge: true}));
  await assertFails(updateDoc(doc(env.authenticatedContext('legacy', {role: 'user'}).firestore(), 'users/legacy'), {
    accountType: 'public',
  }));
});

test('a user cannot assign themselves an admin role in their profile', async () => {
  await assertFails(updateDoc(doc(alice, 'users/alice'), {
    role: 'admin',
  }));
  await assertFails(setDoc(doc(alice, 'users/alice'), {
    uid: 'alice',
    displayName: 'Alice',
    accountType: 'personal',
    role: 'admin',
  }));
});

test('journals are private even from admins and super admins', async () => {
  const journal = doc(alice, 'journals/alice_2026-11-23');
  await assertSucceeds(getDoc(journal));
  await assertFails(getDoc(doc(bob, 'journals/alice_2026-11-23')));
  await assertFails(getDoc(doc(admin, 'journals/alice_2026-11-23')));
  await assertFails(getDoc(doc(superAdmin, 'journals/alice_2026-11-23')));
  await assertFails(getDoc(doc(guest, 'journals/alice_2026-11-23')));
});

test('verified Duas are readable, pending Duas are hidden, and clients cannot write content', async () => {
  await assertSucceeds(getDoc(doc(guest, 'duas/approved')));
  await assertFails(getDoc(doc(guest, 'duas/pending')));
  await assertFails(setDoc(doc(alice, 'duas/client-injected'), {
    status: 'verified',
    arabic: 'untrusted',
    bn: 'untrusted',
    reference: 'fake',
  }));
});

test('only an admin can read account suspension metadata; clients cannot write it', async () => {
  await assertSucceeds(getDoc(doc(admin, 'user_admin_status/alice')));
  await assertSucceeds(getDoc(doc(superAdmin, 'user_admin_status/alice')));
  await assertFails(getDoc(doc(alice, 'user_admin_status/alice')));
  await assertFails(deleteDoc(doc(admin, 'user_admin_status/alice')));
});

test('a user can create a tracker record only under their own uid and date key', async () => {
  await assertSucceeds(setDoc(doc(alice, 'ibadah_records/alice_2026-11-24'), {
    uid: 'alice',
    date: '2026-11-24',
    items: {fajr: true},
    clientUpdatedAt: 123,
  }));
  await assertFails(setDoc(doc(alice, 'ibadah_records/bob_2026-11-24'), {
    uid: 'alice',
    date: '2026-11-24',
    items: {fajr: true},
  }));
  await assertFails(setDoc(doc(alice, 'ibadah_records/alice_not-a-date'), {
    uid: 'alice',
    date: 'not-a-date',
    items: {fajr: true},
  }));
});
