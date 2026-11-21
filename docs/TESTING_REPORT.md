# Testing report (honest status)
| Area | Result |
|---|---|
| Dart syntax (tree-sitter), 39 files | Pass, 0 errors |
| Dart type-check / `flutter analyze` / unit tests (`test/deen_test.dart`) | **Not run** - no Flutter SDK available (network blocked). Expect some compile fixes on first CI run |
| Cloud Functions `tsc` | Pass |
| Admin dashboard `next build` (type-check + static export) | Pass |
| Quran import script | Pass on synthetic data (114 surahs, 6,236 verses invariants); not run on real Tanzil files |
| Content validator | Pass (no verified records bundled) |
| Firestore rules emulator tests | **Not run** (emulator download blocked) |
| Registration, login, password reset, Google sign-in | **Not tested** (needs Firebase credentials) |
| Prayer calculation accuracy, location, notifications after close/restart, Bengali/Arabic rendering on device, Android install | **Not tested** (needs device) |
| Web responsiveness, admin auth against live project | **Not tested** |
Do not treat the app as release-ready until these are run on a real device and Firebase project.
