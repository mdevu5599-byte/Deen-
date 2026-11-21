import 'package:hijri/hijri_calendar.dart';
import 'app_strings.dart';

const _gBn = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];
const _gEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const _gAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
const _hBn = ['মুহাররম', 'সফর', 'রবিউল আউয়াল', 'রবিউস সানি', 'জমাদিউল আউয়াল', 'জমাদিউস সানি', 'রজব', "শা'বান", 'রমজান', 'শাওয়াল', 'জিলকদ', 'জিলহজ'];
const _hEn = ['Muharram', 'Safar', "Rabi' al-Awwal", "Rabi' al-Thani", 'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', "Sha'ban", 'Ramadan', 'Shawwal', "Dhu al-Qi'dah", 'Dhu al-Hijjah'];
const _hAr = ['محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'];
const _wBn = ['সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার'];
const _wEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _wAr = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];

String gregorian(S s, DateTime d) {
  final months = s.lang == 'bn' ? _gBn : s.lang == 'ar' ? _gAr : _gEn;
  final wd = (s.lang == 'bn' ? _wBn : s.lang == 'ar' ? _wAr : _wEn)[d.weekday - 1];
  return '$wd, ${s.n(d.day)} ${months[d.month - 1]} ${s.n(d.year)}';
}

String hijri(S s, DateTime d, int offset) {
  final h = HijriCalendar.fromDate(d.add(Duration(days: offset)));
  final months = s.lang == 'bn' ? _hBn : s.lang == 'ar' ? _hAr : _hEn;
  final suffix = s.lang == 'bn' ? 'হিজরি' : s.lang == 'ar' ? 'هـ' : 'AH';
  return '${s.n(h.hDay)} ${months[h.hMonth - 1]} ${s.n(h.hYear)} $suffix';
}

String clock(S s, DateTime t) {
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final mm = t.minute.toString().padLeft(2, '0');
  final am = t.hour < 12;
  final suf = s.lang == 'bn' ? (am ? 'এএম' : 'পিএম') : s.lang == 'ar' ? (am ? 'ص' : 'م') : (am ? 'AM' : 'PM');
  return '${s.n(h12)}:${s.n(mm)} $suf';
}

String countdown(S s, Duration d) {
  if (d.isNegative) d = Duration.zero;
  String two(int v) => v.toString().padLeft(2, '0');
  return s.n('${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}');
}
