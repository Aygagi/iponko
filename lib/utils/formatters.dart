// lib/utils/formatters.dart

import 'package:intl/intl.dart';

class PesoFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'fil_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  static final _compact = NumberFormat.compactCurrency(
    locale: 'fil_PH',
    symbol: '₱',
    decimalDigits: 1,
  );

  // ₱1,250.00
  static String format(double amount) => _formatter.format(amount);

  // ₱1.3K for large values
  static String compact(double amount) =>
      amount >= 10000 ? _compact.format(amount) : _formatter.format(amount);

  // 1,250.00 (no symbol — for input fields)
  static String noSymbol(double amount) =>
      NumberFormat('#,##0.00').format(amount);
}

class DateFormatter {
  // April 30, 2025
  static String full(DateTime date) => DateFormat('MMMM d, yyyy').format(date);

  // Apr 30
  static String short(DateTime date) => DateFormat('MMM d').format(date);

  // Today, Yesterday, or Apr 30
  static String relative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return short(date);
  }

  // For charts: Mon, Tue, etc.
  static String dayLabel(DateTime date) => DateFormat('EEE').format(date);
}
