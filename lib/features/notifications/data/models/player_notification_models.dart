class PlayerNotification {
  const PlayerNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  factory PlayerNotification.fromMap(Map<String, dynamic> raw) {
    return PlayerNotification(
      id: _string(raw['id']),
      type: _string(raw['type']),
      title: _string(raw['title']),
      body: _string(raw['body']),
      isRead: _bool(raw['isRead'] ?? raw['is_read']),
      createdAt: _date(raw['createdAt'] ?? raw['created_at']),
    );
  }

  PlayerNotification copyWith({
    String? id,
    String? type,
    String? title,
    String? body,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return PlayerNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get timeAgo {
    final date = createdAt;
    if (date == null) return '';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return mins == 1 ? '1 min ago' : '$mins mins ago';
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return hours == 1 ? '1 hr ago' : '$hours hrs ago';
    }
    if (diff.inDays < 7) {
      final days = diff.inDays;
      return days == 1 ? 'Yesterday' : '$days days ago';
    }

    return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';
  }
}

class NotificationsPage {
  const NotificationsPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  final List<PlayerNotification> items;
  final int page;
  final int limit;
  final bool hasMore;
}

String _string(dynamic value) {
  if (value is String) return value;
  return '';
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }
  return false;
}

DateTime? _date(dynamic value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');