import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/services/prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

/// Reads assets/data/quran.json produced by scripts/fetch_quran.py from the
/// Tanzil.net verified text. The app never generates Quran text.
class QuranData {
  static List<Map<String, dynamic>>? _surahs;
  static Future<List<Map<String, dynamic>>> load() async {
    if (_surahs != null) return _surahs!;
    try {
      final raw = await rootBundle.loadString('assets/data/quran.json');
      _surahs = ((jsonDecode(raw)['surahs'] ?? []) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      _surahs = [];
    }
    return _surahs!;
  }
}

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});
  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('quran'))),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: QuranData.load(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final all = snap.data!;
          if (all.isEmpty) return EmptyState(icon: Icons.menu_book_outlined, message: s.t('no_quran'));
          final last = Prefs.json('quran_last');
          final bm = (Prefs.json('quran_bookmarks') ?? {}).keys.toSet();
          final query = q.trim();
          List<Map<String, dynamic>> list = all;
          List<Map<String, dynamic>> hits = [];
          if (query.isNotEmpty) {
            list = all.where((e) => '${e['no']}'.contains(query) || (e['en'] ?? '').toString().toLowerCase().contains(query.toLowerCase()) || (e['ar'] ?? '').toString().contains(query)).toList();
            for (final sr in all) {
              for (final a in (sr['ayahs'] as List).cast<Map<String, dynamic>>()) {
                if ((a['bn'] ?? '').toString().contains(query) || (a['ar'] ?? '').toString().contains(query)) {
                  hits.add({'surah': sr, 'ayah': a});
                  if (hits.length >= 30) break;
                }
              }
              if (hits.length >= 30) break;
            }
          }
          return ListView(padding: const EdgeInsets.all(16), children: [
            TextField(
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: s.t('search')),
              onChanged: (v) => setState(() => q = v),
            ),
            const SizedBox(height: 12),
            if (last != null && query.isEmpty)
              DeenCard(
                color: DeenColors.sage,
                onTap: () {
                  final sr = all.firstWhere((e) => e['no'] == last['surah'], orElse: () => all.first);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SurahScreen(surah: sr)));
                },
                child: Row(children: [
                  const Icon(Icons.bookmark_outline, color: DeenColors.accent),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${s.t('continue_reading')} (${s.n(last['surah'])}:${s.n(last['ayah'])})')),
                ]),
              ),
            for (final h in hits)
              DeenCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahScreen(surah: h['surah'] as Map<String, dynamic>))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ArabicText((h['ayah'] as Map)['ar'].toString(), size: 20),
                  Text((h['ayah'] as Map)['bn'].toString(), style: const TextStyle(height: 1.8)),
                  Text('${s.n((h['surah'] as Map)['no'])}:${s.n((h['ayah'] as Map)['n'])}', style: const TextStyle(color: DeenColors.textSecondary)),
                ]),
              ),
            for (final sr in list)
              DeenCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahScreen(surah: sr))),
                child: Row(children: [
                  SizedBox(width: 36, child: Text(s.n(sr['no']), style: const TextStyle(color: DeenColors.accent, fontWeight: FontWeight.w600))),
                  Expanded(child: Text('${sr['en']}', style: const TextStyle(fontSize: 16))),
                  if (bm.any((k) => k.startsWith('${sr['no']}:'))) const Icon(Icons.bookmark, size: 18, color: DeenColors.accent),
                  const SizedBox(width: 8),
                  Text('${sr['ar'] ?? ''}', style: const TextStyle(fontFamily: 'Amiri', fontSize: 22)),
                ]),
              ),
          ]);
        },
      ),
    );
  }
}

class SurahScreen extends StatefulWidget {
  final Map<String, dynamic> surah;
  const SurahScreen({super.key, required this.surah});
  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  double size = Prefs.d('quran_size') ?? 26;
  bool showEn = Prefs.b('quran_en') ?? false;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final sr = widget.surah;
    final ayahs = (sr['ayahs'] as List).cast<Map<String, dynamic>>();
    final bm = Prefs.json('quran_bookmarks') ?? <String, dynamic>{};
    return Scaffold(
      appBar: AppBar(title: Text('${sr['en']}'), actions: [
        IconButton(
          icon: Icon(showEn ? Icons.translate : Icons.translate_outlined),
          tooltip: s.t('english_translation'),
          onPressed: () async {
            await Prefs.setB('quran_en', !showEn);
            setState(() => showEn = !showEn);
          },
        ),
        PopupMenuButton<double>(
          icon: const Icon(Icons.text_fields),
          onSelected: (v) async {
            await Prefs.setD('quran_size', v);
            setState(() => size = v);
          },
          itemBuilder: (_) => [for (final v in const [20.0, 24.0, 28.0, 34.0, 40.0]) PopupMenuItem(value: v, child: Text(s.n(v.toInt())))],
        ),
      ]),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ayahs.length,
        itemBuilder: (_, i) {
          final a = ayahs[i];
          final key = '${sr['no']}:${a['n']}';
          final marked = bm.containsKey(key);
          return DeenCard(
            onTap: () => Prefs.setJson('quran_last', {'surah': sr['no'], 'ayah': a['n']}),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(s.n(key), style: const TextStyle(color: DeenColors.accent, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: Icon(marked ? Icons.bookmark : Icons.bookmark_border, color: DeenColors.accent),
                  onPressed: () async {
                    marked ? bm.remove(key) : bm[key] = true;
                    await Prefs.setJson('quran_bookmarks', bm);
                    setState(() {});
                  },
                ),
              ]),
              ArabicText('${a['ar']}', size: size),
              if ((a['bn'] ?? '').toString().isNotEmpty) Text('${a['bn']}', style: const TextStyle(fontSize: 16, height: 1.9)),
              if (showEn && (a['en'] ?? '').toString().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 8), child: Text('${a['en']}', style: const TextStyle(fontFamily: 'Inter', color: DeenColors.textSecondary, height: 1.6))),
            ]),
          );
        },
      ),
    );
  }
}
