import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/hadith_repository.dart';
import '../domain/hadith.dart';

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});
  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  String? category;
  bool favOnly = false;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final repo = context.read<HadithRepository>();
    return Scaffold(
      appBar: AppBar(title: Text(s.t('hadith')), actions: [
        IconButton(
          icon: Icon(favOnly ? Icons.favorite : Icons.favorite_border),
          onPressed: () => setState(() => favOnly = !favOnly),
        ),
      ]),
      body: Column(children: [
        SizedBox(
          height: 48,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: Text(s.t('all')), selected: category == null, onSelected: (_) => setState(() => category = null)),
            ),
            for (final c in hadithCategories)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: Text(c), selected: category == c, onSelected: (_) => setState(() => category = c)),
              ),
          ]),
        ),
        Expanded(
          child: FutureBuilder<List<Hadith>>(
            future: repo.byCategory(category),
            builder: (_, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              var list = snap.data!;
              if (favOnly) {
                final f = repo.favourites();
                list = list.where((h) => f.contains(h.id)).toList();
              }
              if (list.isEmpty) return EmptyState(icon: Icons.menu_book_outlined, message: s.t('no_verified'));
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => HadithCard(h: list[i], onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => HadithDetailScreen(h: list[i])));
                }),
              );
            },
          ),
        ),
      ]),
    );
  }
}

const _pendingNotice = {
  'bn': 'সংকলন থেকে সংযোজিত। আরবি মূল ও মান যাচাই বাকি; প্রচারের আগে আলেমের কাছে মিলিয়ে নিন।',
  'en': 'Imported from a compilation. Arabic text and grading not yet verified; check with a scholar before sharing.',
  'ar': 'مضاف من مجموعة. النص العربي والدرجة لم يُتحقق منهما بعد؛ راجع أحد العلماء قبل النشر.',
};

class PendingNotice extends StatelessWidget {
  const PendingNotice({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: DeenColors.sage, borderRadius: BorderRadius.circular(10)),
      child: Text(_pendingNotice[s.lang] ?? _pendingNotice['bn']!,
          style: const TextStyle(fontSize: 12, color: DeenColors.warn, height: 1.6)),
    );
  }
}

class HadithCard extends StatelessWidget {
  final Hadith h;
  final VoidCallback? onTap;
  const HadithCard({super.key, required this.h, this.onTap});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return DeenCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(h.bn, style: const TextStyle(fontSize: 17, height: 1.8)),
        const SizedBox(height: 8),
        Text('${s.t('source')}: ${h.reference}', style: const TextStyle(color: DeenColors.textSecondary, fontSize: 13)),
        if (!h.isVerified) Padding(padding: const EdgeInsets.only(top: 6), child: Text(h.category, style: const TextStyle(fontSize: 12, color: DeenColors.accent))),
      ]),
    );
  }
}

class HadithDetailScreen extends StatefulWidget {
  final Hadith h;
  const HadithDetailScreen({super.key, required this.h});
  @override
  State<HadithDetailScreen> createState() => _HadithDetailScreenState();
}

class _HadithDetailScreenState extends State<HadithDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final repo = context.read<HadithRepository>();
    final h = widget.h;
    final fav = repo.favourites().contains(h.id);
    Widget label(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(t, style: const TextStyle(color: DeenColors.accent, fontWeight: FontWeight.w600)));
    return Scaffold(
      appBar: AppBar(title: Text(h.category), actions: [
        IconButton(
          icon: Icon(fav ? Icons.favorite : Icons.favorite_border),
          onPressed: () async {
            await repo.toggleFavourite(h.id);
            if (mounted) setState(() {});
          },
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: () => Share.share('${h.arabic.isNotEmpty ? '${h.arabic}\n\n' : ''}${h.bn}\n\n${h.reference}\n— DEEN'),
        ),
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (!h.isVerified) const PendingNotice(),
        if (h.arabic.isNotEmpty) ArabicText(h.arabic, size: 26),
        label(s.t('translation')),
        Text(h.bn, style: const TextStyle(fontSize: 18, height: 1.9)),
        if ((h.en ?? '').isNotEmpty) ...[label(s.t('english_translation')), Text(h.en!, style: const TextStyle(fontFamily: 'Inter', height: 1.7))],
        if (h.explanationBn.isNotEmpty) ...[label(s.t('explanation')), Text(h.explanationBn, style: const TextStyle(height: 1.9))],
        if (h.lessonBn.isNotEmpty) ...[label(s.t('lesson')), Text(h.lessonBn, style: const TextStyle(height: 1.9))],
        label(s.t('source')),
        Text(h.reference),
        if ((h.narrator ?? '').isNotEmpty) Text('${s.t('narrator')}: ${h.narrator}'),
        if ((h.grade ?? '').isNotEmpty) Text('${s.t('grade')}: ${h.grade}'),
      ]),
    );
  }
}
