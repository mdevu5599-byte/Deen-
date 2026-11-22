# Firebase setup
1. Create a Firebase project; enable Authentication (Email/Password, Google), Firestore, Storage, Cloud Messaging; Functions needs the Blaze plan.
2. Android: add app `com.deen.deen`, add SHA-1/SHA-256 (needed for Google Sign-In), save `google-services.json` as secret `GOOGLE_SERVICES_JSON` (CI) or at `mobile/android/app/`. iOS: see IOS.md. Web: pass `--dart-define` keys (mobile/README.md).
3. `cd backend && cp .firebaserc.example .firebaserc` (edit), then `firebase deploy --only firestore,storage,functions`.
4. Bootstrap the first super admin on a trusted machine: `GOOGLE_APPLICATION_CREDENTIALS=key.json node scripts/set_super_admin.js you@example.com`. Further roles are assigned in the admin dashboard (server function `setUserRole`, super admin only).
5. Admin dashboard: `cd admin && cp ../../.env.example .env.local` (fill web config), `npm install && npm run build`, deploy `out/` to Hosting target `admin`.
Service-account keys are never used in any frontend. Roles are custom claims, enforced by rules and functions.


## Phone OTP login

- In Firebase Console open **Authentication → Sign-in method → Phone** and enable Phone.
- Add the Android app with package name `com.deen.deen` and register its current SHA-1 and SHA-256 signing fingerprints.
- For development, add test phone numbers and fixed test codes in Firebase Authentication; never use real SMS for repeated automated tests.
- Phone numbers must be entered in E.164 format, for example `+8801XXXXXXXXX`.
- Configure SMS region policy, billing/quota and app verification settings before production use. On Android, Play Integrity / reCAPTCHA verification requirements may apply.

## Admin account management

- The first super admin is bootstrapped using the trusted-machine command above.
- Super admins can assign user/admin/super_admin roles and can disable or re-enable regular user accounts from **Users & roles**.
- Admin roles are custom claims. After a role change, the affected user must obtain a refreshed ID token (sign out and sign in again).
- Admins can manage Hadith, original reminders and Duas through callable Cloud Functions; new or edited content is saved as pending until reviewed.
- Quran text is intentionally source-controlled/imported from verified Tanzil material; it is not edited as free-form text from the dashboard.
