import 'package:flutter/material.dart';

/// Brand mark (the layered-cards app icon). Rendered from the bundled 256px asset.
class CvLogo extends StatelessWidget {
  final double size;
  const CvLogo({super.key, this.size = 64});
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'CardVault logo',
        image: true,
        child: Image.asset('assets/images/logo_256.png', width: size, height: size, filterQuality: FilterQuality.high, gaplessPlayback: true),
      );
}
