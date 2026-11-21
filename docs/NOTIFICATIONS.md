# Notifications
- Prayer and reminder notifications are **local scheduled** (flutter_local_notifications), rebuilt on launch and every app resume for the next 7 days (4 on iOS, capped at 60 pending). Boot receivers restore alarms after restart.
- Android 12+: exact alarms need the "Alarms & reminders" permission; the settings screen detects and asks, and falls back to inexact scheduling.
- Known limits: a timezone/date/location change while the app stays closed is only corrected at next launch (no background worker yet). Aggressive OEM battery savers may delay alarms.
- Adhan audio: add a licensed `adhan.mp3` to `android/app/src/main/res/raw/` and set `kAdhanBundled = true` in `lib/core/constants.dart`.
- Hadith notifications are sent only when a verified Hadith exists. Content rotates by day (no repeats within a cycle); quiet hours and a daily limit apply to non-prayer notifications.
- FCM (admin announcements): app subscribes to topics `all` and `type_personal|public`; dashboard sends via `createNotification`; scheduled jobs run every 5 minutes.
