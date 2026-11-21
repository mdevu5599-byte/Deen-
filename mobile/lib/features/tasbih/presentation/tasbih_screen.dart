import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/services/prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../ibadah_tracker/data/ibadah_repository.dart';

const _dhikr = <String, List<String>>{
  'subhanallah': ['سُبْحَانَ اللّٰه', 'সুবহানাল্লাহ'],
  'alhamdulillah': ['اَلْحَمْدُ لِلّٰه', 'আলহামদুলিল্লাহ'],
  'allahuakbar': ['اَللّٰهُ أَكْبَر', 'আল্লাহু আকবার'],
  'astaghfirullah': ['أَسْتَغْفِرُ اللّٰه', 'আস্তাগফিরুল্লাহ'],
  'lailaha': ['لَا إِلٰهَ إِلَّا اللّٰه', 'লা ইলাহা ইল্লাল্লাহ'],
  'custom': ['', 'কাস্টম যিকির'],
};

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});
  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  String key = Prefs.s('tasbih_key') ?? 'subhanallah';
  String customName = Prefs.s('tasbih_custom') ?? '';

  String get _today => dayKey(DateTime.now());
  Map<String, dynamic> get _day => Prefs.json('tasbih_$_today') ?? {};
  int get count => (_day[key] ?? 0) as int;
  int get target => Prefs.i('tasbih_target_$key') ?? 33;

  Future<void> _tap() async {
    HapticFeedback.lightImpact();
    final d = _day;
    final c = ((d[key] ?? 0) as int) + 1;
    d[key] = c;
    await Prefs.setJson('tasbih_$_today', d);
    if (c == target) HapticFeedback.heavyImpact();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final names = _dhikr[key]!;
    final label = key == 'custom' && customName.isNotEmpty ? customName : names[1];
    final progress = target == 0 ? 0.0 : (count / target).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('tasbih')), actions: [
        IconButton(icon: const Icon(Icons.history), tooltip: s.t('tasbih_history'), onPressed: _history),
      ]),
      body: Column(children: [
        SizedBox(
          height: 52,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
            for (final k in _dhikr.keys)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_dhikr[k]![1]),
                  selected: key == k,
                  onSelected: (_) async {
                    if (k == 'custom') await _askCustom();
                    await Prefs.setS('tasbih_key', k);
                    setState(() => key = k);
                  },
                ),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        if (names[0].isNotEmpty) ArabicText(names[0], size: 30),
        Text(label, style: const TextStyle(fontSize: 18, color: DeenColors.textSecondary)),
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: _tap,
              child: SizedBox(
                width: 260,
                height: 260,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: CircularProgressIndicator(value: progress, strokeWidth: 8, backgroundColor: DeenColors.sage, color: DeenColors.accent),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(s.n(count), style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w300, color: DeenColors.accent)),
                    Text('${s.t('target')}: ${s.n(target)}', style: const TextStyle(color: DeenColors.textSecondary)),
                  ]),
                ]),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final d = _day;
                  d[key] = 0;
                  await Prefs.setJson('tasbih_$_today', d);
                  setState(() {});
                },
                child: Text(s.t('reset')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _askTarget,
                child: Text(s.t('target')),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Future<void> _askTarget() async {
    final c = TextEditingController(text: '$target');
    final s = context.sRead;
    final v = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.t('target')),
        content: TextField(controller: c, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, int.tryParse(c.text)), child: Text(s.t('save'))),
        ],
      ),
    );
    if (v != null && v > 0) {
      await Prefs.setI('tasbih_target_$key', v);
      setState(() {});
    }
  }

  Future<void> _askCustom() async {
    final c = TextEditingController(text: customName);
    final s = context.sRead;
    final v = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.t('tasbih')),
        content: TextField(controller: c),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: Text(s.t('save'))),
        ],
      ),
    );
    if (v != null) {
      await Prefs.setS('tasbih_custom', v);
      customName = v;
    }
  }

  void _history() {
    final s = context.sRead;
    final today = DateTime.now();
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(padding: const EdgeInsets.all(16), children: [
        for (int i = 0; i < 14; i++)
          Builder(builder: (_) {
            final d = today.subtract(Duration(days: i));
            final m = Prefs.json('tasbih_${dayKey(d)}') ?? {};
            final total = m.values.fold<int>(0, (a, b) => a + (b as int));
            return ListTile(title: Text(dayKey(d)), trailing: Text(s.n(total)));
          }),
      ]),
    );
  }
}
