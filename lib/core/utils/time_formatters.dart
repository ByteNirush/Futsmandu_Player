String formatClockTime12Hour(dynamic value) {
  final rawValue = value?.toString().trim() ?? '';
  if (rawValue.isEmpty) return rawValue;

  final rangeParts = rawValue.split(RegExp(r'\s+[-–]\s+'));
  if (rangeParts.length == 2) {
    return formatClockTimeRange12Hour(rangeParts[0], rangeParts[1]);
  }

  final parsed = _parseClockTime(rawValue);
  if (parsed == null) return rawValue;

  final period = parsed.hour >= 12 ? 'PM' : 'AM';
  final displayHour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  return '$displayHour:${parsed.minute.toString().padLeft(2, '0')} $period';
}

String formatClockTimeRange12Hour(String start, String end) {
  if (start.isEmpty && end.isEmpty) return '-';
  if (end.isEmpty) return formatClockTime12Hour(start);
  return '${formatClockTime12Hour(start)} - ${formatClockTime12Hour(end)}';
}

_ClockTime? _parseClockTime(String value) {
  final normalized = value
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('A.M.', 'AM')
      .replaceAll('P.M.', 'PM')
      .replaceAll('A.M', 'AM')
      .replaceAll('P.M', 'PM');

  final match = RegExp(
    r'^(\d{1,2})(?:(?::|\.)(\d{2}))?(?::(\d{2})(?:\.\d{1,6})?)?\s*([AP]M)?$',
  ).firstMatch(normalized);
  if (match == null) return null;

  var hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2) ?? '0');
  final second = int.tryParse(match.group(3) ?? '0');
  final meridiem = match.group(4);

  if (hour == null || minute == null || second == null) return null;
  if (minute > 59 || second > 59) return null;

  if (meridiem != null) {
    if (hour < 1 || hour > 12) return null;
    if (hour == 12) hour = 0;
    if (meridiem == 'PM') hour += 12;
  } else if (hour > 23) {
    return null;
  }

  return _ClockTime(hour, minute);
}

class _ClockTime {
  const _ClockTime(this.hour, this.minute);

  final int hour;
  final int minute;
}
