import 'dart:math';
import 'package:intl/intl.dart';

// ---------- Formatting ----------
final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _inr2 = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
String money(num v, {bool decimals = false}) => (decimals ? _inr2 : _inr).format(v);

String compactMoney(num v) {
  final a = v.abs();
  final s = v < 0 ? '-' : '';
  if (a >= 10000000) return '$s₹${(a / 10000000).toStringAsFixed(2)}Cr';
  if (a >= 100000) return '$s₹${(a / 100000).toStringAsFixed(2)}L';
  if (a >= 1000) return '$s₹${(a / 1000).toStringAsFixed(1)}K';
  return '$s₹${a.toStringAsFixed(0)}';
}

String dShort(DateTime d) => DateFormat('d MMM yyyy').format(d);
String dDay(DateTime d) => DateFormat('d MMM').format(d);
String dMonth(DateTime d) => DateFormat('MMM yyyy').format(d);

String relDays(DateTime d) {
  final n = DateTime.now();
  final a = DateTime(n.year, n.month, n.day);
  final diff = DateTime(d.year, d.month, d.day).difference(a).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  if (diff < 0) return '${-diff}d ago';
  if (diff < 31) return 'in ${diff}d';
  return dShort(d);
}

String greeting() {
  final h = DateTime.now().hour;
  return h < 12 ? 'Good morning' : (h < 17 ? 'Good afternoon' : 'Good evening');
}

// ---------- Validation ----------
class Validate {
  static bool luhn(String number) {
    final s = number.replaceAll(RegExp(r'\D'), '');
    if (s.length < 12 || s.length > 19) return false;
    var sum = 0;
    var alt = false;
    for (var i = s.length - 1; i >= 0; i--) {
      var n = int.parse(s[i]);
      if (alt) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alt = !alt;
    }
    return sum % 10 == 0;
  }

  static String? cardNumber(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'\s|-'), '');
    if (s.isEmpty) return null; // optional – last 4 can be entered alone
    if (!RegExp(r'^\d+$').hasMatch(s)) return 'Digits only';
    if (s.length != 16) return 'Card number must be 16 digits';
    if (!luhn(s)) return 'Number fails checksum – check for typos';
    return null;
  }

  static String? last4(String? v) =>
      RegExp(r'^\d{4}$').hasMatch((v ?? '').trim()) ? null : 'Enter exactly 4 digits';

  static String? cvv(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    return RegExp(r'^\d{3,4}$').hasMatch(s) ? null : '3 or 4 digits';
  }

  static String? pin(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    return RegExp(r'^\d{4,6}$').hasMatch(s) ? null : '4 to 6 digits';
  }

  static String? required(String? v) => (v ?? '').trim().isEmpty ? 'Required' : null;

  static String? amount(String? v, {bool required = false}) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return required ? 'Required' : null;
    final n = double.tryParse(s.replaceAll(',', ''));
    if (n == null || n < 0) return 'Enter a valid amount';
    return null;
  }

  static String? day(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    final n = int.tryParse(s);
    return (n == null || n < 1 || n > 31) ? '1–31' : null;
  }
}

String maskNumber(String number, String last4) {
  final s = number.replaceAll(RegExp(r'\D'), '');
  final l = s.length >= 4 ? s.substring(s.length - 4) : last4;
  return '•••• •••• •••• $l';
}

String groupNumber(String n) {
  final s = n.replaceAll(RegExp(r'\D'), '');
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && i % 4 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

// ---------- Calculators ----------
class AmortRow {
  final int month;
  final double emi, principal, interest, balance;
  const AmortRow(this.month, this.emi, this.principal, this.interest, this.balance);
}

class LoanResult {
  final double emi, totalInterest, totalPayment;
  final List<AmortRow> schedule;
  const LoanResult(this.emi, this.totalInterest, this.totalPayment, this.schedule);
}

class Calc {
  /// Reducing-balance EMI. [annualRate] in percent, [months] > 0.
  static double emi(double principal, double annualRate, int months) {
    if (principal <= 0 || months <= 0) return 0;
    final r = annualRate / 12 / 100;
    if (r == 0) return principal / months;
    final f = pow(1 + r, months);
    return principal * r * f / (f - 1);
  }

  static LoanResult loan(double principal, double annualRate, int months) {
    final e = emi(principal, annualRate, months);
    final r = annualRate / 12 / 100;
    var bal = principal;
    final rows = <AmortRow>[];
    for (var m = 1; m <= months; m++) {
      final i = bal * r;
      var p = e - i;
      if (m == months || p > bal) p = bal;
      bal = max(0, bal - p);
      rows.add(AmortRow(m, p + i, p, i, bal));
    }
    final total = rows.fold(0.0, (a, r) => a + r.emi);
    return LoanResult(e, total - principal, total, rows);
  }

  static double simpleInterest(double p, double rate, double years) => p * rate * years / 100;

  static double compoundInterest(double p, double rate, double years, int perYear) =>
      p * pow(1 + rate / 100 / perYear, perYear * years) - p;

  /// Prepayment: a lump-sum after [afterMonth] either shortens tenure (same EMI) – returns savings.
  static ({int newMonths, double interestSaved, double newTotalInterest}) prepay(
      double principal, double annualRate, int months, double lump, int afterMonth) {
    final base = loan(principal, annualRate, months);
    final e = base.emi;
    final r = annualRate / 12 / 100;
    var bal = principal;
    var interest = 0.0;
    var m = 0;
    while (bal > 0.5 && m < 1200) {
      m++;
      final i = bal * r;
      interest += i;
      bal = bal + i - e;
      if (m == afterMonth) bal = max(0, bal - lump);
      if (e <= i && m > months * 2) break;
    }
    return (newMonths: m, interestSaved: max(0, base.totalInterest - interest), newTotalInterest: interest);
  }
}
