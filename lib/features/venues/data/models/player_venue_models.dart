class VenueSummary {
  const VenueSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.coverUrl,
    required this.rating,
    required this.reviewCount,
    required this.amenities,
    required this.courts,
    required this.isVerified,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final String coverUrl;
  final double rating;
  final int reviewCount;
  final List<String> amenities;
  final List<VenueCourt> courts;
  final bool isVerified;

  factory VenueSummary.fromMap(Map<String, dynamic> map) {
    return VenueSummary(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      slug: (map['slug'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      latitude: _toDouble(map['lat'] ?? map['latitude']),
      longitude: _toDouble(map['lng'] ?? map['longitude']),
      coverUrl: (map['coverUrl'] ?? map['cover_image_url'] ?? '').toString(),
      rating: _toDouble(map['rating'] ?? map['avg_rating']),
      reviewCount: _toInt(map['reviewCount'] ?? map['total_reviews']),
      amenities: _toStringList(map['amenities']),
      courts: _toMapList(map['courts']).map(VenueCourt.fromMap).toList(),
      isVerified: map['isVerified'] == true || map['is_verified'] == true,
    );
  }
}

class VenueDetail extends VenueSummary {
  const VenueDetail({
    required super.id,
    required super.name,
    required super.slug,
    required super.description,
    required super.address,
    required super.latitude,
    required super.longitude,
    required super.coverUrl,
    required super.rating,
    required super.reviewCount,
    required super.amenities,
    required super.courts,
    required super.isVerified,
    required this.reviews,
  });

  final List<VenueReview> reviews;

  factory VenueDetail.fromMap(Map<String, dynamic> map) {
    final summary = VenueSummary.fromMap(map);
    return VenueDetail(
      id: summary.id,
      name: summary.name,
      slug: summary.slug,
      description: summary.description,
      address: summary.address,
      latitude: summary.latitude,
      longitude: summary.longitude,
      coverUrl: summary.coverUrl,
      rating: summary.rating,
      reviewCount: summary.reviewCount,
      amenities: summary.amenities,
      courts: summary.courts,
      isVerified: summary.isVerified,
      reviews: _toMapList(map['reviews']).map(VenueReview.fromMap).toList(),
    );
  }
}

class VenueCourt {
  const VenueCourt({
    required this.id,
    required this.name,
    required this.type,
    required this.surface,
    required this.slotDurationMins,
  });

  final String id;
  final String name;
  final String type;
  final String surface;
  final int slotDurationMins;

  factory VenueCourt.fromMap(Map<String, dynamic> map) {
    return VenueCourt(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      type: (map['type'] ?? map['court_type'] ?? '').toString(),
      surface: (map['surface'] ?? '').toString(),
      slotDurationMins:
          _toInt(map['slotDurationMins'] ?? map['slot_duration_mins']),
    );
  }
}

class VenueAvailabilitySlot {
  const VenueAvailabilitySlot({
    required this.time,
    required this.endTime,
    required this.status,
  });

  final String time;
  final String endTime;
  final String status;

  factory VenueAvailabilitySlot.fromMap(Map<String, dynamic> map) {
    return VenueAvailabilitySlot(
      time: (map['time'] ?? map['startTime'] ?? '').toString(),
      endTime: (map['endTime'] ?? '').toString(),
      status: (map['status'] ?? 'UNAVAILABLE').toString(),
    );
  }
}

class VenueReview {
  const VenueReview({
    required this.id,
    required this.author,
    required this.authorAvatarUrl,
    required this.rating,
    required this.text,
    required this.ownerReply,
    required this.date,
  });

  final String id;
  final String author;
  final String authorAvatarUrl;
  final double rating;
  final String text;
  final String ownerReply;
  final String date;

  factory VenueReview.fromMap(Map<String, dynamic> map) {
    return VenueReview(
      id: (map['id'] ?? '').toString(),
      author: (map['author'] ?? '').toString(),
      authorAvatarUrl: (map['authorAvatarUrl'] ?? '').toString(),
      rating: _toDouble(map['rating']),
      text: (map['text'] ?? map['comment'] ?? '').toString(),
      ownerReply: (map['ownerReply'] ?? map['owner_reply'] ?? '').toString(),
      date: (map['date'] ?? map['created_at'] ?? '').toString(),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

List<String> _toStringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value.map((e) => e.toString()).toList(growable: false);
}

List<Map<String, dynamic>> _toMapList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList(growable: false);
}
