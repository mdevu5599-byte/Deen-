import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DeenCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;
  const DeenCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DeenColors.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
          if (trailing != null) trailing!,
        ]),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 40, color: DeenColors.textSecondary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: DeenColors.textSecondary, height: 1.6)),
          ]),
        ),
      );
}

/// Text that is always rendered right-to-left with the Arabic font.
class ArabicText extends StatelessWidget {
  final String text;
  final double size;
  const ArabicText(this.text, {super.key, this.size = 24});
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          width: double.infinity,
          child: Text(text, textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Amiri', fontSize: size, height: 2.0)),
        ),
      );
}

void showMsg(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));
