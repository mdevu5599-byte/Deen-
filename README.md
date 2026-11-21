# DEEN - Your Daily Reminder to Return to Allah

Islamic spiritual companion: Flutter app (Android, iOS, web), Firebase backend, Next.js admin dashboard. Bengali is the default language; English and Arabic (RTL) are supported.

## Status (read this first)

| Part | State |
|---|---|
| Flutter app source (all modules in the brief) | Written. **Never compiled** - the build sandbox had no Flutter/Android SDK. Dart syntax checked (0 errors in 39 files). |
| **Android APK / AAB** | **Not built here.** Built by the GitHub Actions workflow (`.github/workflows/build.yml`) - see below. No APK exists yet; there is no download link. |
| Firebase rules, indexes, Cloud Functions | Written. Functions **compile** (`tsc`). Rules **not tested** against the emulator. Nothing deployed. |
| Admin dashboard | Written, **type-checked and production-built** (static export). Not run against a live Firebase project. |
| Hadith / Dua content | **None published.** Structure, verification workflow and import path are ready; no unverified text was invented. |
| Quran text | **Not bundled.** Import verified Tanzil files with `scripts/fetch_quran.py`. |
| Adhan audio | Not bundled (needs a licensed file). |
| Live notifications / Firebase | Untested; require real credentials and a device. |

## Get your APK (about 10 minutes)

1. Create a GitHub repository and push this folder to it.
2. Optional now, needed for sign-in: in Firebase console add an Android app with package name **`com.deen.deen`**, download `google-services.json`, and save its full text as the repository secret `GOOGLE_SERVICES_JSON`.
3. Optional: download Tanzil Arabic text and the Bengali translation into `data_sources/` (see `scripts/fetch_quran.py`).
4. Open the **Actions** tab, run **Build DEEN** (or push a commit). When finished, download the `deen-android` artifact: `app-release.apk` (install on your phone, allow "install unknown apps") and `app-release.aab`.

The release APK is signed with Flutter's debug key so it installs directly. For Google Play, configure your own upload keystore.
Or build locally: install Flutter 3.27.4, then from `apps/mobile` run the same steps as the workflow's Android job.

Without `google-services.json` the APK still installs and runs in **guest mode** (prayer times, notifications, tasbih, tracker, journal, bundled content). Registration/login need Firebase.
The first CI run may need small fixes (Gradle/AGP versions); I could not exercise it.

## Layout
`apps/mobile` Flutter (feature folders: authentication, home, prayer_times, notifications, hadith, reminders, akhirah, quran, duas, ibadah_tracker, tasbih, journal, settings). Clean-architecture layers (domain/data/presentation) are fully separated in authentication, prayer_times, hadith and notifications; smaller features are flatter.
`apps/web` web build notes | `apps/admin` Next.js dashboard | `backend` rules, indexes, functions, firebase.json | `packages` shared constants/schemas | `docs` | `scripts`.

## Docs
`docs/FIREBASE_SETUP.md`, `docs/CONTENT_VERIFICATION.md`, `docs/DATABASE.md`, `docs/NOTIFICATIONS.md`, `docs/IOS.md`, `docs/TESTING_REPORT.md`.
