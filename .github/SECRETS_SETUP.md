# DEEN GitHub Actions secrets

Open **GitHub → mdevu5599-byte/Deen- → Settings → Secrets and variables → Actions → New repository secret**.

## Android build
- `GOOGLE_SERVICES_JSON`: complete text of Firebase Android `google-services.json` for package `com.deen.deen`.
- `KEYSTORE_BASE64`: base64 of the original Android upload keystore (single uninterrupted line).
- `KEYSTORE_PASSWORD`: keystore password.
- `KEY_ALIAS`: key alias.
- `KEY_PASSWORD`: key password.

PowerShell conversion (run locally; never paste its output into chat or commit it):
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('C:\secure\deen-upload-key.jks'))
```

## Firebase deployment
- `FIREBASE_PROJECT_ID`: actual Firebase project ID.
- `FIREBASE_SERVICE_ACCOUNT`: complete JSON for a dedicated, least-privilege deployment service account.
- `FIREBASE_ADMIN_HOSTING_SITE_ID`: existing Firebase Hosting site ID for the Admin Dashboard target.
- `FIREBASE_WEB_HOSTING_SITE_ID`: existing Firebase Hosting site ID for the public web app target.
- `NEXT_PUBLIC_FIREBASE_API_KEY`
- `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN`
- `NEXT_PUBLIC_FIREBASE_PROJECT_ID`
- `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET`
- `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID`
- `NEXT_PUBLIC_FIREBASE_APP_ID`

The six `NEXT_PUBLIC_*` values are Firebase web app configuration, not server credentials. The service-account JSON and signing key/passwords are secrets. Never commit those secrets. Create/register the Web, Android and Hosting sites in Firebase Console first. Enable Email/Password and Google providers (and Phone only after SMS/verification settings are configured).

Because signing passwords were shared in a chat upload, treat them as exposed. Change passwords securely while preserving the original keystore/key identity; keep an encrypted backup. Check Google Play App Signing/upload-key arrangements before rotating the upload key.

## Run
- **Actions → Build DEEN → Run workflow**: builds release APK and AAB and uploads both as `deen-android`.
- **Actions → Deploy DEEN Firebase → Run workflow**: builds the Admin Dashboard and public web app, then deploys Firestore rules/indexes, Storage rules, Functions and both Hosting targets.
- Bootstrap the first super-admin claim on a trusted machine as described in `docs/FIREBASE_SETUP.md`.
