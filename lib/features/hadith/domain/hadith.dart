/// A Hadith record. Only records with status == 'verified' and all mandatory
/// fields present are ever shown or used in notifications.
class Hadith {
  final String id;
  final String category;
  final String arabic;
  final String bn;
  final String? en;
  final String explanationBn;
  final String book;
  final String number;
  final String? narrator;
  final String? grade;
  final String lessonBn;
  final List<String> related;
  final String refText; // full reference text, e.g. "সহীহ বুখারী: ২৪৭৫; সহীহ মুসলিম: ৫৭"
  final String status; // verified | imported

  const Hadith({
    required this.id,
    required this.category,
    required this.arabic,
    required this.bn,
    this.en,
    required this.explanationBn,
    required this.book,
    required this.number,
    this.narrator,
    this.grade,
    required this.lessonBn,
    this.related = const [],
    this.refText = '',
    this.status = 'verified',
  });

  factory Hadith.fromJson(String id, Map<String, dynamic> j) => Hadith(
        id: id,
        category: (j['category'] ?? '') as String,
        arabic: (j['arabic'] ?? '') as String,
        bn: (j['bn'] ?? '') as String,
        en: j['en'] as String?,
        explanationBn: (j['explanationBn'] ?? '') as String,
        book: (j['book'] ?? '') as String,
        number: (j['number'] ?? '').toString(),
        narrator: j['narrator'] as String?,
        grade: j['grade'] as String?,
        lessonBn: (j['lessonBn'] ?? '') as String,
        related: ((j['related'] ?? const []) as List).map((e) => e.toString()).toList(),
        refText: (j['refText'] ?? '') as String,
        status: (j['status'] ?? 'verified') as String,
      );

  bool get isVerified => status == 'verified';

  String get reference => refText.isNotEmpty ? refText : (number.isEmpty ? book : '$book, $number');

  /// Display gate: a Bengali text and some source reference are required. Arabic is
  /// optional (shown when present). Verified status is tracked separately.
  bool get isPublishable => bn.trim().isNotEmpty && (refText.trim().isNotEmpty || book.trim().isNotEmpty);
}
