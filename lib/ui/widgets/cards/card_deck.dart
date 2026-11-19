import 'package:flutter/physics.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

/// THE signature widget: a layered, half-overlapping wallet deck.
///
/// * Vertical swipe browses (spring physics). The focused card is fully visible; the
///   following cards peek out beneath it, each showing roughly [peek] of its height.
/// * Tap a card to select it; tap the selected card again to flip it.
/// * Long-press = quick actions. Reordering is only possible in [reorder] mode, so
///   swipe and drag gestures never compete.
class CardDeck extends StatefulWidget {
  final List<CardItem> cards;
  final String? selectedId;
  final ValueChanged<CardItem> onSelect;
  final ValueChanged<CardItem>? onOpen;
  final ValueChanged<CardItem>? onLongPress;
  final bool expanded;
  final bool reorder;
  final ValueChanged<List<CardItem>>? onReorder;
  final double peek; // fraction of card height revealed per stacked card (≈ .5)
  final int visible; // followers shown beneath the focused card
  final double maxCardWidth;
  const CardDeck({
    super.key,
    required this.cards,
    required this.onSelect,
    this.selectedId,
    this.onOpen,
    this.onLongPress,
    this.expanded = false,
    this.reorder = false,
    this.onReorder,
    this.peek = .5,
    this.visible = 3,
    this.maxCardWidth = 400,
  });
  @override
  State<CardDeck> createState() => _CardDeckState();
}

class _CardDeckState extends State<CardDeck> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController.unbounded(vsync: this, value: _initial().toDouble());
  final _flipKeys = <String, GlobalKey<FlipCardState>>{};
  int _focus = 0;

  int _initial() {
    final i = widget.cards.indexWhere((c) => c.id == widget.selectedId);
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _focus = _initial();
    _ctl.addListener(_tick);
  }

  void _tick() {
    final n = widget.cards.length;
    if (n == 0) return;
    final f = _ctl.value.round().clamp(0, n - 1);
    if (f != _focus) {
      _focus = f;
      HapticFeedback.selectionClick();
      widget.onSelect(widget.cards[f]);
    }
  }

  @override
  void didUpdateWidget(CardDeck old) {
    super.didUpdateWidget(old);
    final n = widget.cards.length;
    if (n == 0) return;
    if (widget.selectedId != old.selectedId || widget.cards.length != old.cards.length) {
      final i = widget.cards.indexWhere((c) => c.id == widget.selectedId);
      if (i >= 0 && i != _ctl.value.round()) _spring(i.toDouble(), 0);
      if (_ctl.value > n - 1) _spring((n - 1).toDouble(), 0);
    }
  }

  void _spring(double target, double velocity) {
    _ctl.animateWith(SpringSimulation(const SpringDescription(mass: 1, stiffness: 220, damping: 22), _ctl.value, target, velocity));
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, a) => FadeTransition(
          opacity: a, child: ScaleTransition(scale: Tween(begin: .96, end: 1.0).animate(a), child: child)),
      child: widget.reorder
          ? _buildReorder(context)
          : widget.expanded
              ? _buildExpanded(context)
              : _buildStack(context),
    );
  }

  // ------------------------------------------------------------------ stacked
  Widget _buildStack(BuildContext context) {
    return LayoutBuilder(key: const ValueKey('stack'), builder: (context, box) {
      final w = min(box.maxWidth, widget.maxCardWidth);
      final h = w / kCardAspect;
      final step = h * widget.peek;
      final topPad = h * .07;
      final n = widget.cards.length;
      final shown = min(widget.visible, max(0, n - 1));
      final height = shown == 0 ? topPad + h + h * .03 : topPad + h * .97 + step * (shown - 1) + h + h * .03;
      return Center(
        child: SizedBox(
          width: w, height: height,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: (_) => _ctl.stop(),
            onVerticalDragUpdate: (d) {
              final next = _ctl.value - d.delta.dy / max(step, 40);
              _ctl.value = next.clamp(-.25, n - 1 + .25);
            },
            onVerticalDragEnd: (d) {
              final v = -(d.primaryVelocity ?? 0) / max(step, 40);
              final target = (_ctl.value + v * .12).round().clamp(0, n - 1);
              _spring(target.toDouble(), v);
            },
            child: AnimatedBuilder(
              animation: _ctl,
              builder: (context, _) {
                final pos = _ctl.value;
                final kids = <Widget>[];
                for (var i = 0; i < n; i++) {
                  final d = i - pos;
                  if (d < -2.2 || d > shown + 1.2) continue;
                  kids.add(_stackCard(i, d, h, step, topPad, shown));
                }
                return Stack(clipBehavior: Clip.none, children: kids);
              },
            ),
          ),
        ),
      );
    });
  }

  Widget _stackCard(int i, double d, double h, double step, double topPad, int shown) {
    double y;
    double scale = 1;
    double opacity = 1;
    double dim = 0;
    if (d < 0) {
      // cards already browsed: tuck up behind the focused card
      y = topPad + d.clamp(-1.0, 0.0) * h * .06 + (d < -1 ? (d + 1) * h * .02 : 0);
      scale = 1 + d.clamp(-2.0, 0.0) * .035;
      opacity = (1 + d * .75).clamp(0.0, 1.0);
      dim = (-d * .25).clamp(0.0, .45);
    } else if (d < 1) {
      y = topPad + d * h * .97;
      dim = 0;
    } else {
      y = topPad + h * .97 + (d - 1) * step;
      dim = ((d - 1) * .06).clamp(0.0, .3);
      if (d > shown) opacity = (1 - (d - shown) / .5).clamp(0.0, 1.0);
    }
    final c = widget.cards[i];
    final selected = (i - _ctl.value).abs() < .5;
    final key = _flipKeys.putIfAbsent(c.id, () => GlobalKey<FlipCardState>());
    return Positioned(
      key: ValueKey(c.id), top: y, left: 0, right: 0,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale, alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {
              if (!selected) {
                HapticFeedback.lightImpact();
                _spring(i.toDouble(), 0);
                widget.onSelect(c);
              } else {
                HapticFeedback.selectionClick();
                key.currentState?.flip();
              }
            },
            onDoubleTap: () => widget.onOpen?.call(c),
            onLongPress: () {
              HapticFeedback.mediumImpact();
              widget.onLongPress?.call(c);
            },
            child: Stack(children: [
              FlipCard(key: key, card: c, selected: selected),
              if (dim > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: dim), borderRadius: BorderRadius.circular(h * .1))),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- expanded
  Widget _buildExpanded(BuildContext context) {
    return LayoutBuilder(key: const ValueKey('expanded'), builder: (context, box) {
      final w = min(box.maxWidth, widget.maxCardWidth);
      return Center(
        child: SizedBox(
          width: w,
          child: Column(children: [
            for (var i = 0; i < widget.cards.length; i++)
              _ExpandedItem(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Pressable(
                    scale: .985,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onSelect(widget.cards[i]);
                      widget.onOpen?.call(widget.cards[i]);
                    },
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      widget.onLongPress?.call(widget.cards[i]);
                    },
                    child: CardFront(card: widget.cards[i], selected: widget.cards[i].id == widget.selectedId),
                  ),
                ),
              ),
          ]),
        ),
      );
    });
  }

  // ------------------------------------------------------------------ reorder
  Widget _buildReorder(BuildContext context) {
    return LayoutBuilder(key: const ValueKey('reorder'), builder: (context, box) {
      final w = min(box.maxWidth, widget.maxCardWidth);
      return Center(
        child: SizedBox(
          width: w,
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: widget.cards.length,
            proxyDecorator: (child, i, a) => AnimatedBuilder(
              animation: a,
              builder: (_, _) => Transform.scale(scale: 1 + .04 * Curves.easeOut.transform(a.value), child: Material(color: Colors.transparent, child: child)),
            ),
            onReorderStart: (_) => HapticFeedback.mediumImpact(),
            onReorder: (o, n) {
              if (n > o) n -= 1;
              final l = [...widget.cards];
              l.insert(n, l.removeAt(o));
              HapticFeedback.selectionClick();
              widget.onReorder?.call(l);
            },
            itemBuilder: (context, i) {
              final c = widget.cards[i];
              return ReorderableDragStartListener(
                key: ValueKey(c.id), index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Stack(children: [
                    CardFront(card: c),
                    Positioned(top: 10, right: 10, child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: .5), shape: BoxShape.circle),
                      child: const Icon(Icons.drag_indicator_rounded, color: Colors.white, size: 18),
                    )),
                  ]),
                ),
              );
            },
          ),
        ),
      );
    });
  }
}

/// Staggered entrance for expanded cards.
class _ExpandedItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _ExpandedItem({required this.index, required this.child});
  @override
  State<_ExpandedItem> createState() => _ExpandedItemState();
}

class _ExpandedItemState extends State<_ExpandedItem> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 55 * min(widget.index, 8)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    return AnimatedBuilder(
      animation: a,
      builder: (_, child) => Opacity(
        opacity: a.value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - a.value) * -60), child: child),
      ),
      child: widget.child,
    );
  }
}

