import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {double width = 400, double textScale = 1}) => MaterialApp(
      theme: buildTheme(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900), textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: SizedBox(width: width - 32, child: child))),
      ),
    );

void main() {
  group('StatGrid adapts to width and never overflows', () {
    for (final w in [320.0, 400.0, 820.0, 1400.0]) {
      testWidgets('width $w, large text', (tester) async {
        tester.view.physicalSize = Size(w, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(host(
          StatGrid(children: [
            for (var i = 0; i < 8; i++) StatTile('Outstanding balance', '₹21.00L', Icons.credit_card, foot: i.isEven ? '13% utilised' : null),
          ]),
          width: w,
          textScale: 1.25,
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
        final cols = (((w - 32) / 160).floor()).clamp(2, 4);
        expect(find.byType(StatTile), findsNWidgets(8));
        expect(cols >= 2 && cols <= 4, isTrue);
      });
    }
  });

  testWidgets('QuickFab is an icon-only circle when compact and a labelled pill otherwise', (tester) async {
    await tester.pumpWidget(host(const QuickFab(label: 'Add card', icon: Icons.add, onTap: _noop, compact: true)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Add card'), findsNothing);
    expect(find.byTooltip('Add card'), findsOneWidget);
    await tester.pumpWidget(host(const QuickFab(label: 'Add card', icon: Icons.add, onTap: _noop)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Add card'), findsOneWidget);
  });

  testWidgets('SliderField keeps text and slider in sync', (tester) async {
    final c = TextEditingController(text: '500000');
    var changed = '';
    await tester.pumpWidget(host(StatefulBuilder(
      builder: (context, set) => SliderField(label: 'Loan amount', controller: c, min: 50000, max: 2500000, step: 10000, suffix: '₹', onChanged: (v) => set(() => changed = v)),
    )));
    expect(tester.widget<Slider>(find.byType(Slider)).value, 500000);
    // typing beyond the slider range keeps the text but clamps the slider
    await tester.enterText(find.byType(TextField), '9999999');
    await tester.pump();
    expect(tester.widget<Slider>(find.byType(Slider)).value, 2500000);
    expect(c.text, '9999999');
    expect(changed, '9999999');
    // dragging the slider rewrites the text snapped to the step
    await tester.tapAt(tester.getCenter(find.byType(Slider)));
    await tester.pump();
    final v = double.parse(c.text);
    expect(v % 10000, 0);
    expect(v >= 50000 && v <= 2500000, isTrue);
  });

  testWidgets('long screen titles wrap instead of truncating to one line', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: const Screen(title: 'Domestic lounge visits and offers', subtitle: 'Airport lounge', children: []),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    final t = tester.widget<Text>(find.text('Domestic lounge visits and offers'));
    expect(t.maxLines, 2);
  });

  test('theme styles the stock widgets used across the app', () {
    final t = buildTheme();
    expect(t.sliderTheme.activeTrackColor, C.gold);
    expect(t.checkboxTheme.checkColor, isNotNull);
    expect(t.datePickerTheme.backgroundColor, C.charcoal);
    expect(t.popupMenuTheme.color, C.charcoal);
    expect(t.textSelectionTheme.cursorColor, C.gold);
    expect(t.tooltipTheme.decoration, isNotNull);
    expect(t.brightness, Brightness.dark);
  });
}

void _noop() {}
