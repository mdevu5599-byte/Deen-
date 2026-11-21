# Database
Collections: users, user_settings, admin_users, hadith, hadith_categories, quran_verses, reminders, duas, prayer_settings, prayer_records, ibadah_records, tasbih_records, journals, notification_preferences, notification_jobs, notification_logs, app_settings, audit_logs.
- Owner data (`users`, `user_settings`, `notification_preferences`, `prayer_settings`): doc id = uid.
- Daily records (`prayer_records`, `ibadah_records`, `journals`): doc id `<uid>_<yyyy-mm-dd>`, field `uid`; owner-only. **Journals are unreadable by admins.**
- Content (`hadith`, `reminders`, `duas`): clients read only `status == verified`; writes only via Cloud Functions (`saveContent`, `setContentStatus`, `deleteContent`).
- `admin_users`, `notification_jobs/logs`, `audit_logs`: admin read, server write only. Audit log is append-only.
- Roles: custom claim `role` = user | admin | super_admin. Clients cannot write role fields (rules).
Files: `backend/firestore.rules`, `backend/firestore.indexes.json`, `backend/storage.rules`. Timestamps use server time.
Currently the app itself syncs ibadah/prayer/journal records; tasbih and settings are local-only (tasbih_records/user_settings are provisioned but unused by the app).
