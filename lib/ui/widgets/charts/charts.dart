import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cardvault/core/core.dart';

const kChartColors = [C.gold, Color(0xFF7DA7E8), Color(0xFF6FCF97), Color(0xFFE48B6B), Color(0xFFB59AE8), C.silver, Color(0xFFE9B949), Color(0xFF5CC5C9)];

class Donut extends StatelessWidget {
  final Map<String, double> data;
  final String center;
  final double size;
  const Donut(this.data, {super.key, this.center = '', this.size = 170});
  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    final entries = data.entries.where((e) => e.value > 0).toList();
    if (total <= 0) return SizedBox(height: size, child: Center(child: Text('No data yet', style: T.muted)));
    return Row(children: [
      SizedBox(
        width: size, height: size,
        child: Stack(alignment: Alignment.center, children: [
          PieChart(PieChartData(
            sectionsSpace: 3, centerSpaceRadius: size * .32,
            sections: [for (final (i, e) in entries.indexed) PieChartSectionData(value: e.value, color: kChartColors[i % kChartColors.length], radius: size * .16, showTitle: false)],
          ), duration: const Duration(milliseconds: 700), curve: Curves.easeOutCubic),
          Text(center, style: T.num(15), textAlign: TextAlign.center),
        ]),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final (i, e) in entries.take(6).indexed)
          Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: kChartColors[i % kChartColors.length], borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Expanded(child: Text(e.key, style: T.muted.copyWith(color: C.text), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text('${(e.value / total * 100).toStringAsFixed(0)}%', style: T.caption),
          ])),
      ])),
    ]);
  }
}

class Bars extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final double height;
  const Bars(this.labels, this.values, {super.key, this.height = 170});
  @override
  Widget build(BuildContext context) {
    final mx = values.fold(0.0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: height,
      child: BarChart(BarChartData(
        maxY: mx <= 0 ? 1 : mx * 1.25, gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(), rightTitles: const AxisTitles(), topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 26, getTitlesWidget: (v, m) => Padding(padding: const EdgeInsets.only(top: 8), child: Text(labels[v.toInt()], style: T.caption)))),
        ),
        barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(getTooltipColor: (_) => C.raised, getTooltipItem: (g, gi, r, ri) => BarTooltipItem(compactMoney(r.toY), T.body))),
        barGroups: [for (var i = 0; i < values.length; i++) BarChartGroupData(x: i, barRods: [BarChartRodData(toY: values[i], width: 18, borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [C.goldDeep, C.gold]))])],
      ), duration: const Duration(milliseconds: 700), curve: Curves.easeOutCubic),
    );
  }
}

class LineTrend extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  const LineTrend(this.labels, this.values, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 150,
        child: LineChart(LineChartData(
          gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(leftTitles: const AxisTitles(), rightTitles: const AxisTitles(), topTitles: const AxisTitles(),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, interval: 1, getTitlesWidget: (v, m) => v.toInt() < labels.length && v == v.roundToDouble() ? Padding(padding: const EdgeInsets.only(top: 6), child: Text(labels[v.toInt()], style: T.caption)) : const SizedBox()))),
          lineBarsData: [LineChartBarData(
            spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])], isCurved: true, barWidth: 3, color: C.gold, dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.gold.withValues(alpha: .28), Colors.transparent])),
          )],
        ), duration: const Duration(milliseconds: 700)),
      );
}

/// Semicircle-style utilisation ring.
class Ring extends StatelessWidget {
  final double value; // 0..1
  final String label, caption;
  final Color color;
  final double size;
  const Ring(this.value, {super.key, required this.label, this.caption = '', this.color = C.gold, this.size = 120});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size, height: size,
        child: Stack(alignment: Alignment.center, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0, 1)), duration: const Duration(milliseconds: 1100), curve: Curves.easeOutCubic,
            builder: (_, v, _) => SizedBox.expand(child: CircularProgressIndicator(value: v, strokeWidth: 10, backgroundColor: Colors.white10, color: color, strokeCap: StrokeCap.round)),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [Text(label, style: T.num(size * .19)), if (caption.isNotEmpty) Text(caption, style: T.caption)]),
        ]),
      );
}

