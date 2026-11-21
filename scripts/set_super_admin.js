#!/usr/bin/env node
// One-time bootstrap: makes an existing user a super admin.
// Run ONLY on a trusted machine. The service-account key is read from the
// GOOGLE_APPLICATION_CREDENTIALS env var and must never be committed or shipped in any app.
//   npm i firebase-admin && GOOGLE_APPLICATION_CREDENTIALS=./key.json node scripts/set_super_admin.js you@example.com
const admin = require('firebase-admin');
admin.initializeApp();
(async () => {
  const email = process.argv[2];
  if (!email) { console.error('Usage: set_super_admin.js <email>'); process.exit(1); }
  const u = await admin.auth().getUserByEmail(email);
  await admin.auth().setCustomUserClaims(u.uid, {role: 'super_admin'});
  await admin.firestore().collection('admin_users').doc(u.uid).set({uid: u.uid, role: 'super_admin', assignedBy: 'bootstrap', updatedAt: admin.firestore.FieldValue.serverTimestamp()});
  console.log('super_admin set for', u.uid, '- sign out and in again to refresh the token');
})().catch((e) => { console.error(e); process.exit(1); });
