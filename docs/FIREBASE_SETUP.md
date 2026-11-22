# Firebase setup

DEEN uses the existing Firebase project `deen` (`deen-b7d89`). These instructions do not create a project, app, or Hosting site.

## Android

The Android app is registered as `DEEN Android` with package `com.deen.deen`.

Set the complete contents of that app's `google-services.json` as the GitHub repository secret `GOOGLE_SERVICES_JSON`. The existing workflow generates Android platform files, writes the secret to `mobile/android/app/google-services.json`, validates the JSON, and then runs `scripts/patch_android.py` to enable the Google Services Gradle plugin. The JSON is ignored by Git and must not be committed.

## Firebase project selection

`backend/.firebaserc` selects `deen-b7d89` as the default project. Run Firebase CLI commands from `backend/` so they use `backend/firebase.json`.

## Admin dashboard and Flutter web

The repository includes safe examples at `admin/.env.example` and `mobile/firebase.web.example.json`. They contain placeholders, not credentials.

Copy `admin/.env.example` to `admin/.env.local` and copy `mobile/firebase.web.example.json` to `mobile/firebase.web.json`; fill them only with values from an already registered Firebase Web app in `deen-b7d89`. No Web app is currently registered, so these placeholders cannot initialize Firebase until valid Web app values are provided. The local files are ignored by Git.

From `mobile/`, build Flutter web with:

```sh
flutter build web --release --dart-define-from-file=firebase.web.json
```

The admin dashboard is in `admin/`; its Firebase web configuration is read from the `NEXT_PUBLIC_FIREBASE_*` variables.

## Hosting targets

`backend/firebase.json` points to the existing repository build outputs: `../admin/out` and `../mobile/build/web`. Its Hosting targets are named `admin` and `web`. Those target names still need mappings to verified existing Firebase Hosting site IDs in `backend/.firebaserc`; the IDs are intentionally not guessed, and no Hosting sites are created here.

## Services and privileged setup

Authentication, Firestore, Storage, Cloud Functions, and Cloud Messaging must be configured in the existing Firebase project before their related app features can work. Storage and Cloud Functions may require the Blaze billing plan.

To bootstrap the first super admin after Functions and Authentication are configured, run this from the repository root on a trusted machine and keep the service-account key outside the repository:

```sh
GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node scripts/set_super_admin.js you@example.com
```

Further roles are assigned in the admin dashboard through the server-side `setUserRole` function. Service-account keys must never be used in frontend code or committed to Git.
