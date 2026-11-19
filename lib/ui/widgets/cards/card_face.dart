import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cardvault/core/core.dart';

const kCardAspect = 1.586; // ISO/IEC 7810 ID-1

CardStyle resolveTheme(CardItem c) {
  if (c.themeId == 'custom' && c.customColorA != null) {
    return CardStyle('custom', 'Custom', 'Custom design',
        [Color(c.customColorA!), Color(c.customColorB ?? c.customColorA!), Color(c.customColorB ?? c.customColorA!).withValues(alpha: 1)],
        texture: CardTexture.guilloche);
  }
  return themeById(c.themeId);
}

/// Realistic front of a card. Pure widget – everything scales from the width.
class CardFront extends StatelessWidget {
  final CardItem card;
  final bool selected;
  final bool compact; // when partially covered: only draw the top band details
  const CardFront({super.key, required this.card, this.selected = false, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final t = resolveTheme(card);
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final u = w / 340; // design unit
      final fg = t.text;
      final sub = fg.withValues(alpha: .72);
      return AspectRatio(
        aspectRatio: kCardAspect,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22 * u),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: t.colors),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: .55), blurRadius: 24 * u, offset: Offset(0, 10 * u)),
              if (selected) BoxShadow(color: C.gold.withValues(alpha: .35), blurRadius: 22 * u, spreadRadius: 1),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22 * u),
            child: Stack(fit: StackFit.expand, children: [
              CustomPaint(painter: _TexturePainter(t.texture, t.dark)),
              // metallic sheen
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, stops: const [0, .45, .55, 1], colors: [
                    Colors.white.withValues(alpha: .20), Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0), Colors.black.withValues(alpha: .22)]),
                ),
              ),
              // selected: refined metallic border
              if (selected)
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22 * u),
                    border: Border.all(color: const Color(0xFFEBD3A0).withValues(alpha: .9), width: 1.6),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(22 * u, 18 * u, 22 * u, 18 * u),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(card.bank.isEmpty ? 'BANK' : card.bank.toUpperCase(),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: 'Inter', color: fg, fontSize: 13 * u, fontWeight: FontWeight.w800, letterSpacing: 1.4 * u)),
                        SizedBox(height: 2 * u),
                        Text(card.product.isEmpty ? (card.kind == CardKind.credit ? 'Credit Card' : 'Debit Card') : card.product,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Inter', color: sub, fontSize: 11 * u, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                    if (card.status != CardStatus.active) _StatusPill(card.status, u),
                    SizedBox(width: 8 * u),
                    Icon(Icons.contactless_outlined, color: fg.withValues(alpha: .85), size: 26 * u),
                  ]),
                  SizedBox(height: 14 * u),
                  _Chip(u: u, light: !t.dark),
                  const Spacer(),
                  Text('•••• •••• •••• ${card.last4.isEmpty ? '0000' : card.last4}',
                      style: TextStyle(fontFamily: 'Inter', color: fg, fontSize: 19 * u, fontWeight: FontWeight.w600, letterSpacing: 2.2 * u,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          shadows: [Shadow(color: Colors.black.withValues(alpha: .35), blurRadius: 3, offset: const Offset(0, 1))])),
                  SizedBox(height: 10 * u),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(card.holder.isEmpty ? 'CARDHOLDER' : card.holder.toUpperCase(),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: 'Inter', color: fg, fontSize: 11.5 * u, fontWeight: FontWeight.w600, letterSpacing: 1 * u)),
                        if (card.showExpiry)
                          Text('VALID THRU  ${card.expMonth.toString().padLeft(2, '0')}/${(card.expYear % 100).toString().padLeft(2, '0')}',
                              style: TextStyle(fontFamily: 'Inter', color: sub, fontSize: 9.5 * u, letterSpacing: .8 * u)),
                      ]),
                    ),
                    NetworkMark(card.network, u: u, color: fg),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      );
    });
  }
}

class _StatusPill extends StatelessWidget {
  final CardStatus s;
  final double u;
  const _StatusPill(this.s, this.u);
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8 * u, vertical: 3 * u),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: .45), borderRadius: BorderRadius.circular(20)),
        child: Text(s.name.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 8.5 * u, fontWeight: FontWeight.w800, letterSpacing: .8)),
      );
}

class _Chip extends StatelessWidget {
  final double u;
  final bool light;
  const _Chip({required this.u, required this.light});
  @override
  Widget build(BuildContext context) => Container(
        width: 40 * u, height: 30 * u,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6 * u),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF2DB9E), Color(0xFFC9A24F), Color(0xFFE8CD85)]),
          border: Border.all(color: const Color(0xFF8A6D2B).withValues(alpha: .6), width: .6),
        ),
        child: CustomPaint(painter: _ChipLines()),
      );
}

class _ChipLines extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFF8A6D2B).withValues(alpha: .55)..strokeWidth = .8..style = PaintingStyle.stroke;
    c.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), p);
    c.drawLine(Offset(s.width / 3, 0), Offset(s.width / 3, s.height), p);
    c.drawLine(Offset(s.width * 2 / 3, 0), Offset(s.width * 2 / 3, s.height), p);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.width * .3, s.height * .25, s.width * .4, s.height * .5), const Radius.circular(3)), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Network marks drawn as vector shapes (no bundled trademarked bitmaps).
class NetworkMark extends StatelessWidget {
  final String network;
  final double u;
  final Color color;
  const NetworkMark(this.network, {super.key, required this.u, required this.color});
  @override
  Widget build(BuildContext context) {
    switch (network) {
      case 'Mastercard':
        return SizedBox(
          width: 46 * u, height: 28 * u,
          child: Stack(children: [
            Positioned(left: 0, child: _Dot(const Color(0xFFEB001B), 28 * u)),
            Positioned(right: 0, child: _Dot(const Color(0xFFF79E1B).withValues(alpha: .92), 28 * u)),
          ]),
        );
      case 'Visa':
        return Text('VISA', style: TextStyle(fontFamily: 'Inter', fontStyle: FontStyle.italic, color: color, fontSize: 24 * u, fontWeight: FontWeight.w900, letterSpacing: -.5));
      case 'RuPay':
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Text('Ru', style: TextStyle(fontFamily: 'Inter', fontStyle: FontStyle.italic, color: color, fontSize: 19 * u, fontWeight: FontWeight.w800)),
          Text('Pay', style: TextStyle(fontFamily: 'Inter', fontStyle: FontStyle.italic, color: const Color(0xFFFF9933), fontSize: 19 * u, fontWeight: FontWeight.w800)),
          Icon(Icons.arrow_right_alt_rounded, color: const Color(0xFF138808), size: 18 * u),
        ]);
      case 'American Express':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 6 * u, vertical: 3 * u),
          decoration: BoxDecoration(color: const Color(0xFF006FCF), borderRadius: BorderRadius.circular(3)),
          child: Text('AMEX', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12 * u, letterSpacing: 1)),
        );
      default:
        return Text(network.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12 * u, letterSpacing: 1));
    }
  }
}

class _Dot extends StatelessWidget {
  final Color c;
  final double s;
  const _Dot(this.c, this.s);
  @override
  Widget build(BuildContext context) => Container(width: s, height: s, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

/// Back of the card: magnetic stripe, signature panel and *support info only*.
/// There is intentionally no CVV area.
class CardBack extends StatelessWidget {
  final CardItem card;
  const CardBack({super.key, required this.card});
  @override
  Widget build(BuildContext context) {
    final t = resolveTheme(card);
    return LayoutBuilder(builder: (context, box) {
      final u = box.maxWidth / 340;
      return AspectRatio(
        aspectRatio: kCardAspect,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22 * u),
            gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [t.colors[2], t.colors[0]]),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 22 * u, offset: Offset(0, 10 * u))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22 * u),
            child: Stack(fit: StackFit.expand, children: [
              CustomPaint(painter: _TexturePainter(t.texture, t.dark)),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(height: 24 * u),
                Container(height: 42 * u, color: Colors.black.withValues(alpha: .85)),
                Padding(
                  padding: EdgeInsets.fromLTRB(22 * u, 16 * u, 22 * u, 0),
                  child: Container(
                    height: 30 * u, alignment: Alignment.centerLeft, padding: EdgeInsets.symmetric(horizontal: 10 * u),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .88), borderRadius: BorderRadius.circular(4)),
                    child: Text('Authorised signature', style: TextStyle(color: Colors.black54, fontSize: 10 * u, fontStyle: FontStyle.italic)),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.fromLTRB(22 * u, 0, 22 * u, 18 * u),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(card.support.isEmpty ? 'Customer support: add in card details' : 'Support: ${card.support}',
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: t.text.withValues(alpha: .85), fontSize: 10.5 * u, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4 * u),
                    Text('Your own record · not official bank artwork',
                        style: TextStyle(color: t.text.withValues(alpha: .55), fontSize: 8.5 * u, letterSpacing: .3)),
                  ]),
                ),
              ]),
            ]),
          ),
        ),
      );
    });
  }
}

/// 3-D flip between front and back.
class FlipCard extends StatefulWidget {
  final CardItem card;
  final bool selected;
  const FlipCard({super.key, required this.card, this.selected = false});
  @override
  State<FlipCard> createState() => FlipCardState();
}

class FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeInOutCubicEmphasized);
  void flip() => _c.status == AnimationStatus.completed || _c.value > .5 ? _c.reverse() : _c.forward();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: flip,
        child: AnimatedBuilder(
          animation: _a,
          builder: (context, _) {
            final angle = _a.value * pi;
            final back = angle > pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..setEntry(3, 2, .0012)..rotateY(angle),
              child: back
                  ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(pi), child: CardBack(card: widget.card))
                  : CardFront(card: widget.card, selected: widget.selected),
            );
          },
        ),
      );
}

class _TexturePainter extends CustomPainter {
  final CardTexture tex;
  final bool dark;
  _TexturePainter(this.tex, this.dark);
  @override
  void paint(Canvas c, Size s) {
    final line = Paint()..color = (dark ? Colors.white : Colors.black).withValues(alpha: .05)..strokeWidth = 1..style = PaintingStyle.stroke;
    switch (tex) {
      case CardTexture.none:
        break;
      case CardTexture.brushed:
        final r = Random(7);
        for (var i = 0; i < 90; i++) {
          final y = r.nextDouble() * s.height;
          line.color = (r.nextBool() ? Colors.white : Colors.black).withValues(alpha: .035 + r.nextDouble() * .03);
          c.drawLine(Offset(0, y), Offset(s.width, y + r.nextDouble() * 3), line);
        }
      case CardTexture.diagonal:
        for (double x = -s.height; x < s.width; x += 14) {
          c.drawLine(Offset(x, s.height), Offset(x + s.height, 0), line);
        }
        final glow = Paint()..shader = RadialGradient(colors: [Colors.white.withValues(alpha: .16), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(s.width * .95, s.height * .1), radius: s.width * .6));
        c.drawRect(Offset.zero & s, glow);
      case CardTexture.guilloche:
        final p = Paint()..color = (dark ? Colors.white : Colors.black).withValues(alpha: .045)..style = PaintingStyle.stroke..strokeWidth = .8;
        for (var k = 0; k < 26; k++) {
          final path = Path();
          for (double x = 0; x <= s.width; x += 6) {
            final y = s.height * .62 + sin(x / s.width * pi * 3 + k * .38) * (s.height * .12 + k * 1.6) + (k - 13) * 4;
            x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
          }
          c.drawPath(path, p);
        }
      case CardTexture.dots:
        final p = Paint()..color = Colors.white.withValues(alpha: .07);
        for (double x = 8; x < s.width; x += 14) {
          for (double y = 8; y < s.height; y += 14) {
            c.drawCircle(Offset(x, y), 1.3, p);
          }
        }
      case CardTexture.carbon:
        final p = Paint()..color = Colors.white.withValues(alpha: .04);
        for (double x = 0; x < s.width; x += 8) {
          for (double y = 0; y < s.height; y += 8) {
            if (((x + y) ~/ 8) % 2 == 0) c.drawRect(Rect.fromLTWH(x, y, 4, 4), p);
          }
        }
    }
  }

  @override
  bool shouldRepaint(_TexturePainter o) => o.tex != tex;
}

/// Small helper used in lists.
class MiniCard extends StatelessWidget {
  final CardItem card;
  final double width;
  const MiniCard(this.card, {super.key, this.width = 64});
  @override
  Widget build(BuildContext context) {
    final t = resolveTheme(card);
    return Container(
      width: width, height: width / kCardAspect,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(width * .09),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: t.colors)),
      alignment: Alignment.bottomLeft, padding: EdgeInsets.all(width * .08),
      child: Text(card.last4, style: TextStyle(color: t.text.withValues(alpha: .85), fontSize: width * .15, fontWeight: FontWeight.w700)),
    );
  }
}

String cardSubtitle(CardItem c) => '${c.kind == CardKind.credit ? 'Credit' : 'Debit'} · ${c.network}${c.creditLimit > 0 ? ' · ${compactMoney(c.creditLimit)}' : ''}';

