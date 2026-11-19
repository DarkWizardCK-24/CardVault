import 'dart:math';
import 'package:flutter/material.dart';

/// Layout breakpoints (logical pixels of *available* width).
class Bp {
  /// Phones (and narrow windows) below this use a single column + bottom bar.
  static const double tablet = 640;

  /// At and above this the app switches to a side rail and two-pane layouts.
  static const double wide = 960;

  static bool isWide(double width) => width >= wide;
  static bool isTablet(double width) => width >= tablet;
}

/// Horizontal gutter that centres content inside [maxWidth].
double gutterFor(double available, double maxWidth, {double min = 20}) => max(min, (available - maxWidth) / 2);

/// Adaptive grid of fixed-height tiles; the column count follows the available width.
class StatGrid extends StatelessWidget {
  final List<Widget> children;
  final double minTile;
  final double tileHeight;
  final int maxColumns;
  const StatGrid({super.key, required this.children, this.minTile = 160, this.tileHeight = 132, this.maxColumns = 4});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final cols = (box.maxWidth / minTile).floor().clamp(2, maxColumns);
        // grow the tile with the user's text-size setting so large fonts never overflow
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final height = tileHeight + (scale - 1).clamp(0.0, 1.0) * 120;
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: height),
          children: children,
        );
      });
}

/// Two columns when there is room, otherwise stacked.
class TwoPane extends StatelessWidget {
  final Widget left, right;
  final double leftWidth;
  final double breakpoint;
  const TwoPane({super.key, required this.left, required this.right, this.leftWidth = 440, this.breakpoint = 740});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        if (box.maxWidth < breakpoint) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, right]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: leftWidth, child: left),
          const SizedBox(width: 28),
          Expanded(child: right),
        ]);
      });
}
