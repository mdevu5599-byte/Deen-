import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/services/prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../ibadah_tracker/data/ibadah_repository.dart';

/// Private journal + daily self-review. Stored on-device; mirrored to Firestore
/// under the owner's uid only (see firestore.rules: journals are owner-only).
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final DateTime day = DateTime.now();
  late final String key = dayKey(day);
  late Map<String, dynamic> data = Prefs.json('journal_$key') ?? {};
  final note = TextEditingController();
  final fix = TextEditingController();

  @override
  void initState() {
    super.initState();
    note.text = (data['note'] ?? '') as String;
    fix.text = (data['q5'] ?? '') as String;
  }

  Future<void> _save() async {
    data['note'] = note.text;
    data['q5'] = fix.text;
    await Prefs.setJson('journal_$key', data);
    final clientUpdatedAt = DateTime.now().millisecondsSinceEpoch;
    await Prefs.setI('journal_updated_$key', clientUpdatedAt);
    final uid = Fb.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('journals').doc('${uid}_$key').set({
          'uid': uid, 'date': key, 'answers': {for (final e in data.entries) e.key: e.value},
          'clientUpdatedAt': clientUpdatedAt,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
    if (mounted) showMsg(context, context.sRead.t('save'));
  }

  Widget _yesNo(String qKey, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: const TextStyle(height: 1.6)),
          const SizedBox(height: 6),
          SegmentedButton<bool>(
            emptySelectionAllowed: true,
            segments: const [ButtonSegment(value: true, label: Text('হ্যাঁ / Yes')), ButtonSegment(value: false, label: Text('না / No'))],
            selected: data[qKey] is bool ? {data[qKey] as bool} : <bool>{},
            onSelectionChanged: (v) => setState(() => data[qKey] = v.isEmpty ? null : v.first),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('journal')), actions: [
        TextButton(onPressed: _save, child: Text(s.t('save'))),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          const Icon(Icons.lock_outline, size: 16, color: DeenColors.textSecondary),
          const SizedBox(width: 6),
          Text(s.t('private_note'), style: const TextStyle(color: DeenColors.textSecondary)),
        ]),
        SectionTitle(s.t('self_review')),
        DeenCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _yesNo('q1', s.t('q1')),
            _yesNo('q2', s.t('q2')),
            _yesNo('q3', s.t('q3')),
            _yesNo('q4', s.t('q4')),
            Text(s.t('q5'), style: const TextStyle(height: 1.6)),
            const SizedBox(height: 6),
            TextField(controller: fix, maxLines: 3, decoration: InputDecoration(hintText: s.t('write_here'))),
          ]),
        ),
        SectionTitle(s.t('journal')),
        TextField(controller: note, maxLines: 10, decoration: InputDecoration(hintText: s.t('write_here'))),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: Text(s.t('save'))),
      ]),
    );
  }
}
