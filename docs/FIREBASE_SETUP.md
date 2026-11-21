# Firebase setup
1. Create a Firebase project; enable Authentication (Email/Password, Google), Firestore, Storage, Cloud Messaging; Functions needs the Blaze plan.
2. Android: add app `com.deen.deen`, add SHA-1/SHA-256 (needed for Google Sign-In), save `google-services.json` as secret `GOOGLE_SERVICES_JSON` (CI) or at `apps/mobile/android/app/`. iOS: see IOS.md. Web: pass `--dart-define` keys (apps/web/README.md).
3. `cd backend && cp .firebaserc.example .firebaserc` (edit), then `firebase deploy --only firestore,storage,functions`.
4. Bootstrap the first super admin on a trusted machine: `GOOGLE_APPLICATION_CREDENTIALS=key.json node scripts/set_super_admin.js you@example.com`. Further roles are assigned in the admin dashboard (server function `setUserRole`, super admin only).
5. Admin dashboard: `cd apps/admin && cp ../../.env.example .env.local` (fill web config), `npm install && npm run build`, deploy `out/` to Hosting target `admin`.
Service-account keys are never used in any frontend. Roles are custom claims, enforced by rules and functions.
