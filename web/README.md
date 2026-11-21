# DEEN Web
The user-facing web app is the same Flutter codebase as mobile (`apps/mobile`), built for the web target:

    cd apps/mobile
    flutter create --platforms=web --org com.deen --project-name deen .
    flutter build web --release \
      --dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_APP_ID=... \
      --dart-define=FIREBASE_PROJECT_ID=... --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
      --dart-define=FIREBASE_AUTH_DOMAIN=...

Without the dart-defines the web app runs in guest mode (prayer times, tasbih, tracker, content). Local scheduled notifications are mobile-only.
