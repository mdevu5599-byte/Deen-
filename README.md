
## GitHub Actions: Android builds and Firebase deployment

Automated workflows are in `.github/workflows/`:

- **Build DEEN**: runs Flutter dependency resolution, analysis and tests, then builds an Android release APK and AAB. Without an upload keystore, Flutter's default debug signing may be used (direct-install testing only, not a Play Store upload).
- **Deploy DEEN Firebase**: builds Cloud Functions, the Next.js Admin Dashboard and the Flutter web app, then deploys Firestore rules/indexes, Storage rules, Functions and the two Firebase Hosting targets.

Add repository Actions secrets using ` .github/SECRETS_SETUP.md` (remove the leading space when opening the path). Firebase deployment requires `FIREBASE_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT`, the two Hosting site IDs and the six `NEXT_PUBLIC_FIREBASE_*` values. Android Firebase requires `GOOGLE_SERVICES_JSON` for package `com.deen.deen`. For upload signing, also add `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS` and `KEY_PASSWORD`.

Create the Firebase Android/Web apps and the two Hosting sites in Firebase Console before deploying. Enable authentication providers and configure phone/SMS settings before relying on login flows. Never commit service-account JSON, keystores or passwords. Preserve the original keystore backup and change any signing passwords exposed in chat without generating a different signing key.
