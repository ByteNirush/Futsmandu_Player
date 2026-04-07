class PlayerAuthProfile {
  const PlayerAuthProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.isActive,
    required this.isVerified,
    required this.reliabilityScore,
    required this.eloRating,
    required this.avatarUrl,
    required this.profileImageUrl,
    required this.banUntil,
    required this.createdAt,
    required this.refreshTokenVersion,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final bool isActive;
  final bool isVerified;
  final int reliabilityScore;
  final int eloRating;
  final String avatarUrl;
  final String profileImageUrl;
  final DateTime? banUntil;
  final DateTime? createdAt;
  final int refreshTokenVersion;

  factory PlayerAuthProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    int toInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    bool toBool(dynamic value, {bool fallback = false}) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.toLowerCase().trim();
        if (normalized == 'true') return true;
        if (normalized == 'false') return false;
      }
      return fallback;
    }

    String toStringValue(dynamic value, {String fallback = ''}) {
      if (value is String && value.isNotEmpty) return value;
      if (value != null) return value.toString();
      return fallback;
    }

    final avatarUrl = toStringValue(
      json['avatarUrl'] ?? json['profileImageUrl'] ?? json['profile_image_url'],
    );

    return PlayerAuthProfile(
      id: toStringValue(json['id']),
      name: toStringValue(json['name'], fallback: 'Player'),
      email: toStringValue(json['email']),
      phone: toStringValue(json['phone']),
      isActive: toBool(json['isActive'] ?? json['is_active'], fallback: true),
      isVerified: toBool(json['isVerified'] ?? json['is_verified']),
      reliabilityScore: toInt(
        json['reliabilityScore'] ?? json['reliability_score'],
        fallback: 0,
      ),
      eloRating: toInt(json['eloRating'] ?? json['elo_rating'], fallback: 0),
      avatarUrl: avatarUrl,
      profileImageUrl: avatarUrl,
      banUntil: parseDate(json['banUntil'] ?? json['ban_until']),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      refreshTokenVersion: toInt(
        json['refreshTokenVersion'] ?? json['refresh_token_version'],
        fallback: 0,
      ),
    );
  }

  factory PlayerAuthProfile.empty() => const PlayerAuthProfile(
        id: '',
        name: 'Player',
        email: '',
        phone: '',
        isActive: true,
        isVerified: false,
        reliabilityScore: 0,
        eloRating: 0,
        avatarUrl: '',
        profileImageUrl: '',
        banUntil: null,
        createdAt: null,
        refreshTokenVersion: 0,
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'isActive': isActive,
      'isVerified': isVerified,
      'reliabilityScore': reliabilityScore,
      'eloRating': eloRating,
      'avatarUrl': avatarUrl,
      'profileImageUrl': profileImageUrl,
      'banUntil': banUntil?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'refreshTokenVersion': refreshTokenVersion,
    };
  }
}

class PlayerAuthLoginResult {
  const PlayerAuthLoginResult({
    required this.accessToken,
    required this.user,
  });

  final String accessToken;
  final PlayerAuthProfile user;
}

class PlayerAuthSession {
  const PlayerAuthSession({
    required this.accessToken,
    required this.user,
  });

  final String accessToken;
  final PlayerAuthProfile user;
}
