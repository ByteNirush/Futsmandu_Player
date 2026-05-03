import 'package:flutter_test/flutter_test.dart';
import 'package:futsmandu/features/booking/utils/slot_time_filter.dart';

void main() {
  group('filterSlotsForSelectedDate', () {
    final today = DateTime(2026, 5, 1);
    final slots = <Map<String, dynamic>>[
      {'time': '6:00 PM', 'endTime': '7:00 PM', 'status': 'AVAILABLE'},
      {'time': '18:30', 'endTime': '19:30', 'status': 'AVAILABLE'},
      {'time': '20:00:00', 'endTime': '21:00:00', 'status': 'AVAILABLE'},
    ];

    test('hides slots earlier than the current minute for today', () {
      final visible = filterSlotsForSelectedDate(
        slots,
        selectedDate: today,
        now: DateTime(2026, 5, 1, 18, 25),
      );

      expect(visible.map((slot) => slot['time']), ['18:30', '20:00:00']);
    });

    test('hides a slot once the current time passes its minute', () {
      final visible = filterSlotsForSelectedDate(
        <Map<String, dynamic>>[
          {'time': '6:00 PM', 'status': 'AVAILABLE'},
          {'time': '6:01 PM', 'status': 'AVAILABLE'},
        ],
        selectedDate: today,
        now: DateTime(2026, 5, 1, 18, 1),
      );

      expect(visible, isEmpty);
    });

    test('keeps a future-minute slot visible until its exact start time', () {
      final visible = filterSlotsForSelectedDate(
        <Map<String, dynamic>>[
          {'time': '6:01 PM', 'status': 'AVAILABLE'},
        ],
        selectedDate: today,
        now: DateTime(2026, 5, 1, 18, 0, 59),
      );

      expect(visible.single['time'], '6:01 PM');
    });

    test('shows all slots for future dates', () {
      final visible = filterSlotsForSelectedDate(
        slots,
        selectedDate: DateTime(2026, 5, 2),
        now: DateTime(2026, 5, 1, 18, 25),
      );

      expect(visible, slots);
    });

    test('shows no slots for past dates', () {
      final visible = filterSlotsForSelectedDate(
        slots,
        selectedDate: DateTime(2026, 4, 30),
        now: DateTime(2026, 5, 1, 18, 25),
      );

      expect(visible, isEmpty);
    });

    test('compares full API datetimes in the device local timezone', () {
      final now = DateTime.parse('2026-05-01T18:25:00+05:45');
      final visible = filterSlotsForSelectedDate(
        <Map<String, dynamic>>[
          {'time': '2026-05-01T18:00:00+05:45', 'status': 'AVAILABLE'},
          {'time': '2026-05-01T18:30:00+05:45', 'status': 'AVAILABLE'},
        ],
        selectedDate: now,
        now: now,
      );

      expect(
        visible.map((slot) => slot['time']),
        ['2026-05-01T18:30:00+05:45'],
      );
    });
  });

  group('formatSlotTimeLabel', () {
    test('formats 24-hour API times for display', () {
      expect(
        formatSlotTimeLabel(
          '18:00:00',
          selectedDate: DateTime(2026, 5, 1),
        ),
        '6:00 PM',
      );
    });

    test('keeps unparsable values unchanged', () {
      expect(
        formatSlotTimeLabel(
          'evening',
          selectedDate: DateTime(2026, 5, 1),
        ),
        'evening',
      );
    });
  });
}
