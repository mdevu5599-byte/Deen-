import 'package:flutter/material.dart';
import '../../features/settings/presentation/settings_controller.dart';
import 'package:provider/provider.dart';

/// Lightweight 3-language string table. Bengali is the default and the fallback
/// of last resort is Bengali (never English-only content for a Bengali user).
const Map<String, Map<String, String>> _s = {
  'app_name': {'bn': 'দ্বীন', 'en': 'DEEN', 'ar': 'دين'},
  'tagline': {
    'bn': 'আল্লাহর দিকে ফিরে আসার আপনার প্রতিদিনের স্মারক।',
    'en': 'Your Daily Reminder to Return to Allah.',
    'ar': 'تذكيرك اليومي بالعودة إلى الله.'
  },
  'greeting_line': {
    'bn': 'প্রতিটি নিঃশ্বাস আল্লাহর দিকে ফিরে আসার একটি নতুন সুযোগ।',
    'en': 'Every breath is a new chance to return to Allah.',
    'ar': 'كل نَفَسٍ فرصة جديدة للعودة إلى الله.'
  },
  'salam': {'bn': 'আসসালামু আলাইকুম', 'en': 'Assalamu Alaikum', 'ar': 'السلام عليكم'},
  'home': {'bn': 'হোম', 'en': 'Home', 'ar': 'الرئيسية'},
  'prayer': {'bn': 'নামাজ', 'en': 'Prayer', 'ar': 'الصلاة'},
  'hadith': {'bn': 'হাদিস', 'en': 'Hadith', 'ar': 'الحديث'},
  'quran': {'bn': 'কুরআন', 'en': 'Quran', 'ar': 'القرآن'},
  'more': {'bn': 'আরও', 'en': 'More', 'ar': 'المزيد'},
  'settings': {'bn': 'সেটিংস', 'en': 'Settings', 'ar': 'الإعدادات'},
  'login': {'bn': 'লগইন', 'en': 'Log in', 'ar': 'تسجيل الدخول'},
  'register': {'bn': 'নিবন্ধন', 'en': 'Register', 'ar': 'إنشاء حساب'},
  'email': {'bn': 'ইমেইল', 'en': 'Email', 'ar': 'البريد الإلكتروني'},
  'password': {'bn': 'পাসওয়ার্ড', 'en': 'Password', 'ar': 'كلمة المرور'},
  'name': {'bn': 'নাম', 'en': 'Name', 'ar': 'الاسم'},
  'forgot_password': {'bn': 'পাসওয়ার্ড ভুলে গেছেন?', 'en': 'Forgot password?', 'ar': 'نسيت كلمة المرور؟'},
  'send_reset': {'bn': 'রিসেট লিংক পাঠান', 'en': 'Send reset link', 'ar': 'إرسال رابط الاستعادة'},
  'reset_sent': {
    'bn': 'পাসওয়ার্ড রিসেট লিংক ইমেইলে পাঠানো হয়েছে।',
    'en': 'A password reset link has been sent.',
    'ar': 'تم إرسال رابط إعادة التعيين.'
  },
  'logout': {'bn': 'লগআউট', 'en': 'Log out', 'ar': 'تسجيل الخروج'},
  'delete_account': {'bn': 'অ্যাকাউন্ট মুছে ফেলুন', 'en': 'Delete account', 'ar': 'حذف الحساب'},
  'delete_confirm': {
    'bn': 'আপনার সকল তথ্য স্থায়ীভাবে মুছে যাবে। এটি ফেরানো যাবে না।',
    'en': 'All your data will be permanently deleted. This cannot be undone.',
    'ar': 'سيتم حذف جميع بياناتك نهائيًا ولا يمكن التراجع.'
  },
  'google_signin': {'bn': 'গুগল দিয়ে চালিয়ে যান', 'en': 'Continue with Google', 'ar': 'المتابعة باستخدام Google'},
  'continue_guest': {'bn': 'অ্যাকাউন্ট ছাড়া চালিয়ে যান', 'en': 'Continue without account', 'ar': 'المتابعة بدون حساب'},
  'no_account': {'bn': 'অ্যাকাউন্ট নেই? নিবন্ধন করুন', 'en': 'No account? Register', 'ar': 'ليس لديك حساب؟ سجّل'},
  'have_account': {'bn': 'অ্যাকাউন্ট আছে? লগইন করুন', 'en': 'Have an account? Log in', 'ar': 'لديك حساب؟ سجّل الدخول'},
  'firebase_missing': {
    'bn': 'Firebase এখনো কনফিগার করা হয়নি। অ্যাকাউন্ট ছাড়া ব্যবহার করতে পারেন; লগইন চালু করতে README দেখুন।',
    'en': 'Firebase is not configured yet. You can use the app without an account; see the README to enable sign-in.',
    'ar': 'لم يتم إعداد Firebase بعد. يمكنك استخدام التطبيق بدون حساب.'
  },
  'next_prayer': {'bn': 'পরবর্তী নামাজ', 'en': 'Next prayer', 'ar': 'الصلاة القادمة'},
  'remaining': {'bn': 'বাকি', 'en': 'remaining', 'ar': 'متبقي'},
  'fajr': {'bn': 'ফজর', 'en': 'Fajr', 'ar': 'الفجر'},
  'sunrise': {'bn': 'সূর্যোদয়', 'en': 'Sunrise', 'ar': 'الشروق'},
  'dhuhr': {'bn': 'যোহর', 'en': 'Dhuhr', 'ar': 'الظهر'},
  'asr': {'bn': 'আসর', 'en': 'Asr', 'ar': 'العصر'},
  'maghrib': {'bn': 'মাগরিব', 'en': 'Maghrib', 'ar': 'المغرب'},
  'isha': {'bn': 'ইশা', 'en': 'Isha', 'ar': 'العشاء'},
  'daily_hadith': {'bn': 'আজকের হাদিস', 'en': 'Hadith of the day', 'ar': 'حديث اليوم'},
  'daily_reminder': {'bn': 'আজকের স্মরণ', 'en': 'Reminder of the day', 'ar': 'تذكير اليوم'},
  'akhirah': {'bn': 'মৃত্যুকে স্মরণ করুন', 'en': 'Remember death', 'ar': 'اذكر الموت'},
  'remember_akhirah': {'bn': 'আখিরাতকে স্মরণ করুন', 'en': 'Remember Your Akhirah', 'ar': 'تذكّر آخرتك'},
  'ibadah_progress': {'bn': 'আজকের ইবাদত', 'en': "Today's worship", 'ar': 'عبادات اليوم'},
  'tasbih': {'bn': 'তাসবিহ', 'en': 'Tasbih', 'ar': 'التسبيح'},
  'dua': {'bn': 'দোয়া ও আজকার', 'en': 'Duas & Adhkar', 'ar': 'الأدعية والأذكار'},
  'journal': {'bn': 'ব্যক্তিগত জার্নাল', 'en': 'Private journal', 'ar': 'المذكرة الخاصة'},
  'tracker': {'bn': 'ইবাদত ট্র্যাকার', 'en': 'Worship tracker', 'ar': 'متابعة العبادات'},
  'self_review': {'bn': 'আজকের আত্মসমালোচনা', 'en': 'Daily self-review', 'ar': 'محاسبة اليوم'},
  'q1': {'bn': 'আজ কি পাঁচ ওয়াক্ত নামাজ আদায় করেছি?', 'en': 'Did I pray all five prayers today?', 'ar': 'هل أديتُ الصلوات الخمس اليوم؟'},
  'q2': {'bn': 'আজ কি কোনো গুনাহ করেছি?', 'en': 'Did I commit any sin today?', 'ar': 'هل ارتكبتُ ذنبًا اليوم؟'},
  'q3': {'bn': 'আজ কি কারও মনে কষ্ট দিয়েছি?', 'en': 'Did I hurt anyone today?', 'ar': 'هل آذيتُ أحدًا اليوم؟'},
  'q4': {'bn': 'আজ কি আল্লাহর কাছে ক্ষমা চেয়েছি?', 'en': 'Did I ask Allah for forgiveness today?', 'ar': 'هل استغفرتُ الله اليوم؟'},
  'q5': {'bn': 'আগামীকাল নিজেকে কীভাবে সংশোধন করব?', 'en': 'How will I improve myself tomorrow?', 'ar': 'كيف سأُصلح نفسي غدًا؟'},
  'notifications': {'bn': 'নোটিফিকেশন', 'en': 'Notifications', 'ar': 'الإشعارات'},
  'language': {'bn': 'ভাষা', 'en': 'Language', 'ar': 'اللغة'},
  'location': {'bn': 'অবস্থান', 'en': 'Location', 'ar': 'الموقع'},
  'auto_location': {'bn': 'স্বয়ংক্রিয় অবস্থান শনাক্ত করুন', 'en': 'Detect location automatically', 'ar': 'تحديد الموقع تلقائيًا'},
  'choose_city': {'bn': 'শহর নির্বাচন করুন', 'en': 'Choose a city', 'ar': 'اختر مدينة'},
  'method': {'bn': 'হিসাব পদ্ধতি', 'en': 'Calculation method', 'ar': 'طريقة الحساب'},
  'asr_method': {'bn': 'আসরের হিসাব', 'en': 'Asr calculation', 'ar': 'حساب العصر'},
  'hanafi': {'bn': 'হানাফি', 'en': 'Hanafi', 'ar': 'حنفي'},
  'shafi': {'bn': 'শাফেয়ি/মালিকি/হাম্বলি', 'en': "Shafi'i / Maliki / Hanbali", 'ar': 'شافعي/مالكي/حنبلي'},
  'adjust': {'bn': 'সময় সমন্বয় (মিনিট)', 'en': 'Time adjustment (minutes)', 'ar': 'تعديل الوقت (دقائق)'},
  'hijri_offset': {'bn': 'হিজরি তারিখ সমন্বয় (দিন)', 'en': 'Hijri date adjustment (days)', 'ar': 'تعديل التاريخ الهجري (أيام)'},
  'completed': {'bn': 'আদায় হয়েছে', 'en': 'Completed', 'ar': 'تمّت'},
  'mark_done': {'bn': 'আদায় করেছি', 'en': 'Mark as done', 'ar': 'تمّت'},
  'test_notification': {'bn': 'টেস্ট নোটিফিকেশন পাঠান', 'en': 'Send test notification', 'ar': 'إرسال إشعار تجريبي'},
  'quiet_hours': {'bn': 'নীরব সময়', 'en': 'Quiet hours', 'ar': 'ساعات الهدوء'},
  'daily_limit': {'bn': 'দৈনিক সর্বোচ্চ নোটিফিকেশন', 'en': 'Daily notification limit', 'ar': 'الحد اليومي للإشعارات'},
  'save': {'bn': 'সংরক্ষণ', 'en': 'Save', 'ar': 'حفظ'},
  'cancel': {'bn': 'বাতিল', 'en': 'Cancel', 'ar': 'إلغاء'},
  'delete': {'bn': 'মুছুন', 'en': 'Delete', 'ar': 'حذف'},
  'no_verified': {
    'bn': 'এখনো কোনো যাচাইকৃত হাদিস যোগ করা হয়নি। অ্যাডমিন যাচাই ও অনুমোদনের পর এখানে দেখা যাবে।',
    'en': 'No verified Hadith have been published yet. They appear here after admin verification and approval.',
    'ar': 'لم يتم نشر أي أحاديث موثّقة بعد.'
  },
  'no_quran': {
    'bn': 'কুরআনের ডেটা এখনো আমদানি করা হয়নি। README-তে "scripts/fetch_quran.py" দেখুন।',
    'en': 'Quran data has not been imported yet. See scripts/fetch_quran.py in the README.',
    'ar': 'لم يتم استيراد بيانات القرآن بعد.'
  },
  'no_dua': {
    'bn': 'যাচাইকৃত দোয়ার ডেটা এখনো যোগ করা হয়নি।',
    'en': 'No verified dua data has been added yet.',
    'ar': 'لم تتم إضافة بيانات أدعية موثّقة بعد.'
  },
  'arabic': {'bn': 'আরবি', 'en': 'Arabic', 'ar': 'العربية'},
  'translation': {'bn': 'বাংলা অনুবাদ', 'en': 'Bengali translation', 'ar': 'الترجمة البنغالية'},
  'english_translation': {'bn': 'ইংরেজি অনুবাদ', 'en': 'English translation', 'ar': 'الترجمة الإنجليزية'},
  'explanation': {'bn': 'ব্যাখ্যা', 'en': 'Explanation', 'ar': 'الشرح'},
  'source': {'bn': 'সূত্র', 'en': 'Source', 'ar': 'المصدر'},
  'grade': {'bn': 'মান', 'en': 'Grade', 'ar': 'الدرجة'},
  'lesson': {'bn': 'শিক্ষা', 'en': 'Lesson', 'ar': 'العبرة'},
  'narrator': {'bn': 'বর্ণনাকারী', 'en': 'Narrator', 'ar': 'الراوي'},
  'favourite': {'bn': 'প্রিয়', 'en': 'Favourite', 'ar': 'المفضلة'},
  'share': {'bn': 'শেয়ার', 'en': 'Share', 'ar': 'مشاركة'},
  'related': {'bn': 'সম্পর্কিত হাদিস', 'en': 'Related Hadith', 'ar': 'أحاديث ذات صلة'},
  'all': {'bn': 'সব', 'en': 'All', 'ar': 'الكل'},
  'original_reflection': {'bn': 'মৌলিক স্মরণ (হাদিস বা আয়াত নয়)', 'en': 'Original reflection (not a Hadith or verse)', 'ar': 'تأمل أصلي (ليس حديثًا أو آية)'},
  'target': {'bn': 'লক্ষ্য', 'en': 'Target', 'ar': 'الهدف'},
  'reset': {'bn': 'রিসেট', 'en': 'Reset', 'ar': 'إعادة'},
  'today': {'bn': 'আজ', 'en': 'Today', 'ar': 'اليوم'},
  'week': {'bn': 'সাপ্তাহিক', 'en': 'Weekly', 'ar': 'أسبوعي'},
  'month': {'bn': 'মাসিক', 'en': 'Monthly', 'ar': 'شهري'},
  'private_note': {'bn': 'এটি শুধু আপনিই দেখতে পারবেন।', 'en': 'Only you can see this.', 'ar': 'أنت فقط من يستطيع رؤية هذا.'},
  'write_here': {'bn': 'এখানে লিখুন...', 'en': 'Write here...', 'ar': 'اكتب هنا...'},
  'search': {'bn': 'অনুসন্ধান', 'en': 'Search', 'ar': 'بحث'},
  'font_size': {'bn': 'লেখার আকার', 'en': 'Text size', 'ar': 'حجم الخط'},
  'enabled': {'bn': 'চালু', 'en': 'Enabled', 'ar': 'مفعّل'},
  'sound': {'bn': 'আজান শব্দ', 'en': 'Adhan sound', 'ar': 'صوت الأذان'},
  'vibration': {'bn': 'ভাইব্রেশন', 'en': 'Vibration', 'ar': 'الاهتزاز'},
  'early': {'bn': 'আগে জানান (মিনিট)', 'en': 'Remind earlier (minutes)', 'ar': 'تذكير مسبق (دقائق)'},
  'off': {'bn': 'বন্ধ', 'en': 'Off', 'ar': 'إيقاف'},
  'hadith_notif': {'bn': 'দৈনিক হাদিস', 'en': 'Daily Hadith', 'ar': 'حديث يومي'},
  'akhirah_notif': {'bn': 'আখিরাতের স্মরণ', 'en': 'Akhirah reminder', 'ar': 'تذكير الآخرة'},
  'reminder_notif': {'bn': 'ইসলামিক স্মরণ', 'en': 'Islamic reminder', 'ar': 'تذكير إسلامي'},
  'night_notif': {'bn': 'রাতের আত্মসমালোচনা', 'en': 'Night reflection', 'ar': 'محاسبة الليل'},
  'exact_alarm': {
    'bn': 'সঠিক সময়ে নোটিফিকেশনের জন্য "অ্যালার্ম ও রিমাইন্ডার" অনুমতি দিন।',
    'en': 'Allow "Alarms & reminders" for on-time notifications.',
    'ar': 'اسمح بـ "المنبهات والتذكيرات" لإشعارات في وقتها.'
  },
  'tasbih_history': {'bn': 'ইতিহাস', 'en': 'History', 'ar': 'السجل'},
  'bookmark': {'bn': 'বুকমার্ক', 'en': 'Bookmark', 'ar': 'إشارة'},
  'continue_reading': {'bn': 'যেখানে থামলেন সেখান থেকে পড়ুন', 'en': 'Continue reading', 'ar': 'تابع القراءة'},
  'profile': {'bn': 'প্রোফাইল', 'en': 'Profile', 'ar': 'الملف الشخصي'},
  'guest': {'bn': 'অতিথি', 'en': 'Guest', 'ar': 'ضيف'},
  'error_generic': {'bn': 'কিছু ভুল হয়েছে। আবার চেষ্টা করুন।', 'en': 'Something went wrong. Please try again.', 'ar': 'حدث خطأ. حاول مرة أخرى.'},
};

class S {
  final String lang;
  const S(this.lang);

  String t(String key) {
    final m = _s[key];
    if (m == null) return key;
    return m[lang] ?? m['bn'] ?? key;
  }

  /// Converts ASCII digits to Bengali digits when the language is Bengali.
  String n(Object v) {
    final s = v.toString();
    if (lang != 'bn') return s;
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return s.replaceAllMapped(RegExp(r'[0-9]'), (m) => bn[int.parse(m[0]!)]);
  }
}

extension SX on BuildContext {
  S get s => S(watch<SettingsController>().lang);
  S get sRead => S(read<SettingsController>().lang);
}
