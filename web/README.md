# DEEN Web

The user-facing web app uses the Flutter project in `mobile/`.

1. Copy `mobile/firebase.web.example.json` to `mobile/firebase.web.json`.
2. Replace placeholders with values from an already registered Firebase Web app in the existing project `deen-b7d89`. No Web app is currently registered; no app is created by these instructions.
3. From the repository root:

```sh
cd mobile
flutter create --platforms=web --org com.deen --project-name deen .
flutter build web --release --dart-define-from-file=firebase.web.json
```

The local config file is ignored by Git. Without valid Dart defines the web app runs in guest mode. Local scheduled notifications are mobile-only.
