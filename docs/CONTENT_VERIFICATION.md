# Content verification
No Hadith, translation, narrator, number or grade was invented. Publication workflow:
1. An admin enters a Hadith in the dashboard: Arabic text and reference copied from a canonical source, Bengali translation from a named translator, grade with the grader cited. It is saved as **pending**.
2. A **different** admin verifies it (`setContentStatus`). The server refuses verification unless Arabic, Bengali, one of the six canonical books, a numeric hadith number, a known category and a grade are all present. Edits revert the record to pending.
3. Only `status == verified` records are readable by clients (Firestore rules) and shown/notified by the app (client re-checks mandatory fields).
Bundled content: put records in `apps/mobile/assets/data/hadith.json` / `duas.json` with `"status":"verified"` only after human review; run `python3 scripts/validate_content.py`.
Reminders are **original reflections** (labelled "not a Hadith or verse"); quotations come only from verified Hadith. Bundled reminders are Bengali-only; English/Arabic users see Bengali for them.
Quran: `scripts/fetch_quran.py` assembles Tanzil.net files (keep Tanzil's licence/attribution); it refuses incomplete data (must be 6,236 verses). Quran audio is not included (licensing).
A qualified scholar should review all published religious content.
