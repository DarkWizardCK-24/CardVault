import 'package:flutter/material.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

/// Standard page: ambient background, header row and a centred, responsive content column.
class Screen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget>? actions;
  final Widget? fab;
  final bool padBottom;

  /// Maximum content width. Wide layouts (dashboard, vault) pass a larger value.
  final double maxWidth;
  const Screen({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actions,
    this.fab,
    this.padBottom = true,
    this.maxWidth = 720,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: fab,
        body: AmbientBackground(
          child: SafeArea(
            bottom: false,
            child: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
              SliverLayoutBuilder(builder: (context, c) {
                final side = gutterFor(c.crossAxisExtent, maxWidth);
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(side, 10, side, padBottom ? 130 : 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      ScreenHeader(title: title, subtitle: subtitle, actions: actions),
                      const SizedBox(height: 10),
                      ...children,
                    ]),
                  ),
                );
              }),
            ]),
          ),
        ),
      );
}

/// Back button + title block + trailing actions.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  const ScreenHeader({super.key, required this.title, this.subtitle, this.actions});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Row(children: [
      if (canPop) ...[
        IconPill(Icons.arrow_back_ios_new_rounded, () => Navigator.maybePop(context), tooltip: 'Back'),
        const SizedBox(width: 12),
      ],
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: title.length > 16 ? T.h1.copyWith(fontSize: 21, height: 1.15) : T.h1, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (subtitle != null) Text(subtitle!, style: T.muted, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
      if (actions != null) ...[const SizedBox(width: 12), ...actions!],
    ]);
  }
}
