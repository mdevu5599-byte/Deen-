/// Set to true only after a licensed adhan audio file is placed at
/// android/app/src/main/res/raw/adhan.mp3 (see docs/NOTIFICATIONS.md).
const bool kAdhanBundled = false;

/// Hadith imported from the 400-hadith compilation carry a "verification pending" notice
/// in the app. true = they are also used in notifications (each shows its source reference).
/// Set to false to send only hadith marked "verified".
const bool kNotifyImportedHadith = true;

/// Categories used by the periodic "remember death" notifications. They mix death/grave
/// with Hereafter, Paradise/Hellfire, worldly attachment and repentance to keep a
/// balance between accountability and hope in Allah's mercy.
const kDeathHadithCategories = <String>[
  'মৃত্যু ও কবর',
  'আখিরাত',
  'জান্নাত ও জাহান্নাম',
  'দুনিয়ার মোহ',
  'তওবা ও ইস্তিগফার',
];

const hadithCategories = <String>[
  'জিনা ও ব্যভিচার',
  'চোখের হেফাজত',
  'অবৈধ সম্পর্ক',
  'দুনিয়ার মোহ',
  'সম্পদের লোভ',
  'হিংসা ও বিদ্বেষ',
  'অহংকার',
  'গিবত ও পরনিন্দা',
  'মিথ্যা ও প্রতারণা',
  'তওবা ও ইস্তিগফার',
  'মৃত্যু ও কবর',
  'আখিরাত',
  'জান্নাত ও জাহান্নাম',
  'নামাজের গুরুত্ব',
  'কুরআন তিলাওয়াত',
  'ধৈর্য ও কৃতজ্ঞতা',
  'আল্লাহর রহমত',
  'পিতা-মাতার অধিকার',
  'উত্তম চরিত্র',
  'দান-সদকা',
];

const allowedBooks = <String>[
  'Sahih al-Bukhari',
  'Sahih Muslim',
  'Sunan Abu Dawud',
  "Jami' at-Tirmidhi",
  "Sunan an-Nasa'i",
  'Sunan Ibn Majah',
];
