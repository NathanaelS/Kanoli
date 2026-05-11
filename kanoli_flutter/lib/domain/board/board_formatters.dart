// Shared date formatting and ID generation helpers for board persistence.
import 'dart:math';

abstract final class TodoDateFormatter {
  // todo.txt due dates intentionally use date-only yyyy-MM-dd values.
  static DateTime? tryParse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      return null;
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    return DateTime(year, month, day);
  }

  static String format(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

abstract final class NoteDateFormatter {
  // Notes preserve full timestamps with local timezone offsets in Markdown.
  static DateTime? tryParse(String value) {
    return DateTime.tryParse(value);
  }

  static String format(DateTime value) {
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');

    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final abs = offset.abs();
    final offsetHours = abs.inHours.toString().padLeft(2, '0');
    final offsetMinutes = (abs.inMinutes % 60).toString().padLeft(2, '0');

    return '$year-$month-${day}T$hour:$minute:$second$sign$offsetHours:$offsetMinutes';
  }
}

abstract final class IdGenerator {
  // Board IDs only need local uniqueness across user files.
  static final Random _random = Random.secure();

  static String uuid() {
    String hex(int length) => List<int>.generate(
      length,
      (_) => _random.nextInt(16),
    ).map((int value) => value.toRadixString(16)).join();

    return '${hex(8)}-${hex(4)}-${hex(4)}-${hex(4)}-${hex(12)}';
  }
}
