export const ROLES = ['user', 'admin', 'super_admin'] as const;
export type Role = (typeof ROLES)[number];

// Primary collections only. Grading/verification is a human decision.
export const ALLOWED_BOOKS = [
  'Sahih al-Bukhari',
  'Sahih Muslim',
  'Sunan Abu Dawud',
  "Jami' at-Tirmidhi",
  "Sunan an-Nasa'i",
  'Sunan Ibn Majah',
];

export const HADITH_CATEGORIES = [
  'জিনা ও ব্যভিচার', 'চোখের হেফাজত', 'অবৈধ সম্পর্ক', 'দুনিয়ার মোহ', 'সম্পদের লোভ',
  'হিংসা ও বিদ্বেষ', 'অহংকার', 'গিবত ও পরনিন্দা', 'মিথ্যা ও প্রতারণা', 'তওবা ও ইস্তিগফার',
  'মৃত্যু ও কবর', 'আখিরাত', 'জান্নাত ও জাহান্নাম', 'নামাজের গুরুত্ব', 'কুরআন তিলাওয়াত',
  'ধৈর্য ও কৃতজ্ঞতা', 'আল্লাহর রহমত', 'পিতা-মাতার অধিকার', 'উত্তম চরিত্র', 'দান-সদকা',
];

export const STATUSES = ['draft', 'pending', 'verified', 'rejected'] as const;
export type Status = (typeof STATUSES)[number];

/** Strips control characters and HTML angle brackets; trims and caps length. */
export function clean(v: unknown, max = 5000): string {
  if (typeof v !== 'string') return '';
  // eslint-disable-next-line no-control-regex
  return v.replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, '').replace(/[<>]/g, '').trim().slice(0, max);
}

export interface HadithInput {
  category: string;
  arabic: string;
  bn: string;
  en?: string;
  explanationBn: string;
  lessonBn: string;
  book: string;
  number: string;
  narrator?: string;
  grade?: string;
  related?: string[];
}

export function sanitizeHadith(raw: any): HadithInput {
  return {
    category: clean(raw?.category, 100),
    arabic: clean(raw?.arabic, 6000),
    bn: clean(raw?.bn, 6000),
    en: clean(raw?.en, 6000) || undefined,
    explanationBn: clean(raw?.explanationBn, 8000),
    lessonBn: clean(raw?.lessonBn, 2000),
    book: clean(raw?.book, 100),
    number: clean(raw?.number, 30),
    narrator: clean(raw?.narrator, 120) || undefined,
    grade: clean(raw?.grade, 60) || undefined,
    related: Array.isArray(raw?.related) ? raw.related.slice(0, 10).map((x: unknown) => clean(x, 60)) : [],
  };
}

/** Returns a list of problems that block publishing a Hadith as 'verified'. */
export function verificationProblems(h: HadithInput): string[] {
  const p: string[] = [];
  if (!h.arabic) p.push('Arabic text is required');
  if (!h.bn) p.push('Bengali translation is required');
  if (!ALLOWED_BOOKS.includes(h.book)) p.push('Book must be one of the six canonical collections');
  if (!/^[0-9]{1,5}[A-Za-z]?$/.test(h.number)) p.push('Hadith number is required (digits, e.g. 1234)');
  if (!HADITH_CATEGORIES.includes(h.category)) p.push('Unknown category');
  if (!h.grade) p.push('Authenticity grade is required (cite the grader)');
  return p;
}
