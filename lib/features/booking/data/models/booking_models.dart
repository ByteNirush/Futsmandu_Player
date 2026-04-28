class BookingAvailabilitySlot {
  const BookingAvailabilitySlot({
    required this.time,
    required this.endTime,
    required this.status,
  });

  final String time;
  final String endTime;
  final String status;

  bool get isAvailable => status == 'AVAILABLE';

  factory BookingAvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return BookingAvailabilitySlot(
      time: (json['startTime'] ?? json['time'] ?? '').toString(),
      endTime: (json['endTime'] ?? '').toString(),
      status: _normalizeSlotStatus((json['status'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'endTime': endTime,
      'status': status,
    };
  }
}

class BookingRecord {
  const BookingRecord({
    required this.id,
    required this.totalAmount,
    required this.displayAmount,
    required this.courtId,
    required this.venueId,
    required this.startTime,
    required this.endTime,
    required this.bookingDate,
    this.matchGroupId = '',
  });

  final String id;
  final int totalAmount;
  final String displayAmount;
  final String courtId;
  final String venueId;
  final String startTime;
  final String endTime;
  final String bookingDate;
  final String matchGroupId;

  factory BookingRecord.fromJson(Map<String, dynamic> json) {
    String matchGroupId = '';
    final mg = json['match_group'];
    if (mg is Map) {
      matchGroupId = (mg['id'] ?? '').toString();
    }
    if (matchGroupId.isEmpty) {
      matchGroupId = (json['matchGroupId'] ?? json['match_group_id'] ?? '').toString();
    }

    return BookingRecord(
      id: (json['id'] ?? '').toString(),
      totalAmount: _toInt(json['total_amount']),
      displayAmount: (json['displayAmount'] ?? '').toString(),
      courtId: (json['court_id'] ?? '').toString(),
      venueId: (json['venue_id'] ?? '').toString(),
      startTime: (json['start_time'] ?? '').toString(),
      endTime: (json['end_time'] ?? '').toString(),
      bookingDate: (json['booking_date'] ?? '').toString(),
      matchGroupId: matchGroupId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'displayAmount': displayAmount,
      'court_id': courtId,
      'venue_id': venueId,
      'start_time': startTime,
      'end_time': endTime,
      'booking_date': bookingDate,
      'matchGroupId': matchGroupId,
    };
  }
}

class BookingHistoryItem {
  const BookingHistoryItem({
    required this.id,
    required this.status,
    required this.date,
    required this.time,
    required this.duration,
    required this.priceNpr,
    required this.displayAmount,
    required this.venueName,
    required this.courtName,
    required this.startTime,
    required this.endTime,
    required this.bookingDate,
    required this.refundStatus,
    required this.refundAmount,
    required this.paymentGateway,
    required this.paymentStatus,
    required this.venueAddress,
    required this.venueId,
    required this.courtId,
    required this.bookingType,
    required this.matchGroupId,
    required this.maxPlayers,
    required this.myPlayers,
  });

  final String id;
  final String status;
  final String date;
  final String time;
  final String duration;
  final String priceNpr;
  final String displayAmount;
  final String venueName;
  final String courtName;
  final String startTime;
  final String endTime;
  final String bookingDate;
  final String refundStatus;
  final int refundAmount;
  final String paymentGateway;
  final String paymentStatus;
  final String venueAddress;
  final String venueId;
  final String courtId;
  /// 'FULL_TEAM' or 'PARTIAL_TEAM'
  final String bookingType;
  /// Match group ID — non-empty only for PARTIAL_TEAM bookings
  final String matchGroupId;
  /// Total team size for partial bookings (maxPlayers sent to API)
  final int maxPlayers;
  /// Players the booker already had when creating a partial booking
  final int myPlayers;

  bool get isPartialTeam => bookingType == 'PARTIAL_TEAM';
  int get playersNeeded => maxPlayers > myPlayers ? maxPlayers - myPlayers : 0;

  factory BookingHistoryItem.fromMap(Map<String, dynamic> map) {
    return BookingHistoryItem(
      id: (map['id'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      date: (map['date'] ?? '-').toString(),
      time: (map['time'] ?? '-').toString(),
      duration: (map['duration'] ?? '-').toString(),
      priceNpr: (map['priceNPR'] ?? '').toString(),
      displayAmount: (map['displayAmount'] ?? '').toString(),
      venueName: (map['venueName'] ?? '-').toString(),
      courtName: (map['courtName'] ?? '-').toString(),
      startTime: (map['startTime'] ?? '').toString(),
      endTime: (map['endTime'] ?? '').toString(),
      bookingDate: (map['bookingDate'] ?? '').toString(),
      refundStatus: (map['refundStatus'] ?? '').toString(),
      refundAmount: _toInt(map['refundAmount']),
      paymentGateway: (map['paymentGateway'] ?? '').toString(),
      paymentStatus: (map['paymentStatus'] ?? '').toString(),
      venueAddress: (map['venueAddress'] ?? '').toString(),
      venueId: (map['venueId'] ?? '').toString(),
      courtId: (map['courtId'] ?? '').toString(),
      bookingType: (map['bookingType'] ?? '').toString(),
      matchGroupId: (map['matchGroupId'] ?? '').toString(),
      maxPlayers: _toInt(map['maxPlayers']),
      myPlayers: _toInt(map['myPlayers']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status,
      'date': date,
      'time': time,
      'duration': duration,
      'priceNPR': priceNpr,
      'displayAmount': displayAmount,
      'venueName': venueName,
      'courtName': courtName,
      'startTime': startTime,
      'endTime': endTime,
      'bookingDate': bookingDate,
      'refundStatus': refundStatus,
      'refundAmount': refundAmount,
      'paymentGateway': paymentGateway,
      'paymentStatus': paymentStatus,
      'venueAddress': venueAddress,
      'venueId': venueId,
      'courtId': courtId,
      'bookingType': bookingType,
      'matchGroupId': matchGroupId,
      'maxPlayers': maxPlayers,
      'myPlayers': myPlayers,
    };
  }
}

class BookingHistoryPage {
  const BookingHistoryPage({
    required this.items,
    required this.nextCursor,
    required this.limit,
  });

  final List<BookingHistoryItem> items;
  final String? nextCursor;
  final int limit;
}

class BookingCancellationResult {
  const BookingCancellationResult({
    required this.refundAmount,
    required this.refundPct,
    required this.displayRefund,
    required this.refundNote,
  });

  final int refundAmount;
  final int refundPct;
  final String displayRefund;
  final String refundNote;

  factory BookingCancellationResult.fromJson(Map<String, dynamic> json) {
    return BookingCancellationResult(
      refundAmount: _toInt(json['refundAmount']),
      refundPct: _toInt(json['refundPct']),
      displayRefund: (json['displayRefund'] ?? '').toString(),
      refundNote: (json['refundNote'] ?? '').toString(),
    );
  }
}

class BookingDetail {
  const BookingDetail(this.raw);

  final Map<String, dynamic> raw;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String _normalizeSlotStatus(String status) {
  if (status == 'AVAILABLE' || status == 'OPEN_TO_JOIN') return 'AVAILABLE';
  return 'UNAVAILABLE';
}
