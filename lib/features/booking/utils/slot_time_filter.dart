import 'package:intl/intl.dart';

List<Map<String, dynamic>> filterSlotsForSelectedDate(
  Iterable<Map<String, dynamic>> slots, {
  required DateTime selectedDate,
  DateTime? now,
}) {
  final localNow = (now ?? DateTime.now()).toLocal();
  final selectedLocalDate = _dateOnly(selectedDate);
  final today = _dateOnly(localNow);

  if (selectedLocalDate.isBefore(today)) {
    return const <Map<String, dynamic>>[];
  }

  final slotList = slots.toList(growable: false);
  if (selectedLocalDate.isAfter(today)) {
    return slotList;
  }

  return slotList.where((slot) {
    final slotStart = parseSlotStartDateTime(
      slot['time'] ?? slot['startTime'],
      selectedDate: selectedLocalDate,
    );

    return slotStart != null && slotStart.isAfter(localNow);
  }).toList(growable: false);
}

bool isSlotVisibleForSelectedDate(
  Map<String, dynamic> slot, {
  required DateTime selectedDate,
  DateTime? now,
}) {
  return filterSlotsForSelectedDate(
    <Map<String, dynamic>>[slot],
    selectedDate: selectedDate,
    now: now,
  ).isNotEmpty;
}

DateTime? parseSlotStartDateTime(
  dynamic value, {
  required DateTime selectedDate,
}) {
  if (value is DateTime) {
    return value.toLocal();
  }

  final rawValue = value?.toString().trim();
  if (rawValue == null || rawValue.isEmpty) return null;

  if (_hasDateComponent(rawValue)) {
    final parsedDateTime = DateTime.tryParse(rawValue);
    if (parsedDateTime != null) {
      return parsedDateTime.toLocal();
    }
  }

  final clockTime = _parseClockTime(rawValue);
  if (clockTime == null) return null;

  final selectedLocalDate = _dateOnly(selectedDate);
  return DateTime(
    selectedLocalDate.year,
    selectedLocalDate.month,
    selectedLocalDate.day,
    clockTime.hour,
    clockTime.minute,
    clockTime.second,
  );
}

String formatSlotTimeLabel(
  dynamic value, {
  required DateTime selectedDate,
}) {
  final rawValue = value?.toString().trim() ?? '';
  final slotDateTime = parseSlotStartDateTime(
    value,
    selectedDate: selectedDate,
  );

  if (slotDateTime == null) return rawValue;
  return DateFormat.jm()
      .format(slotDateTime)
      .replaceAll('\u202F', ' ')
      .replaceAll('\u00A0', ' ');
}

DateTime _dateOnly(DateTime value) {
  final localValue = value.toLocal();
  return DateTime(localValue.year, localValue.month, localValue.day);
}

bool _hasDateComponent(String value) {
  return RegExp(r'^\d{4}-\d{2}-\d{2}(?:[ T]|$)').hasMatch(value);
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

  return _ClockTime(hour, minute, second);
}

class _ClockTime {
  const _ClockTime(this.hour, this.minute, this.second);

  final int hour;
  final int minute;
  final int second;
}
