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
      );

  String get reference => '$book, $number';

  /// Mandatory-field gate: Arabic text, Bengali translation, book and number must exist.
  bool get isPublishable =>
      arabic.trim().isNotEmpty && bn.trim().isNotEmpty && book.trim().isNotEmpty && number.trim().isNotEmpty;
}
