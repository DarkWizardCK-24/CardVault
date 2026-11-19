import 'package:flutter/material.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class ListRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const ListRow({super.key, this.leading, required this.title, this.subtitle, this.trailing, this.onTap, this.onLongPress});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Pressable(
          onTap: onTap, onLongPress: onLongPress,
          child: Glass(
            padding: const EdgeInsets.all(14), radius: 20,
            child: Row(children: [
              if (leading != null) ...[leading!, const SizedBox(width: 14)],
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: T.h3, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[const SizedBox(height: 3), Text(subtitle!, style: T.muted, maxLines: 2, overflow: TextOverflow.ellipsis)],
                ]),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ]),
          ),
        ),
      );
}

class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const IconBadge(this.icon, {super.key, this.color = C.gold});
  @override
  Widget build(BuildContext context) => Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: color, size: 22),
      );
}

