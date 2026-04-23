class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImageUrl,
    required this.skillLevel,
    required this.eloRating,
    required this.reliabilityScore,
    required this.totalNoShows,
    required this.totalLateCancels,
    required this.matchesPlayed,
    required this.matchesWon,
    required this.matchesLost,
    required this.matchesDraw,
    required this.showMatchHistory,
    required this.isVerified,
    required this.preferredRoles,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImageUrl;
  final String skillLevel;
  final int eloRating;
  final int reliabilityScore;
  final int totalNoShows;
  final int totalLateCancels;
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final int matchesDraw;
  final bool showMatchHistory;
  final bool isVerified;
  final List<String> preferredRoles;

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    String toStringValue(dynamic value) {
      if (value is String) return value;
      return '';
    }

    List<String> parseRoles(dynamic value) {
      if (value is! List) return const <String>[];
      return value
          .map((item) {
            if (item is Map<String, dynamic>) {
              return toStringValue(item['role']);
            }
            if (item is Map) {
              return toStringValue(item['role']);
            }
            if (item is String) {
              return item;
            }
            return '';
          })
          .where((role) => role.isNotEmpty)
          .toList(growable: false);
    }

    return PlayerProfile(
      id: toStringValue(json['id']),
      name: toStringValue(json['name']),
      email: toStringValue(json['email']),
      phone: toStringValue(json['phone']),
      profileImageUrl: toStringValue(json['profile_image_url']),
      skillLevel: toStringValue(json['skill_level']),
      eloRating: toInt(json['elo_rating']),
      reliabilityScore: toInt(json['reliability_score']),
      totalNoShows: toInt(json['total_no_shows']),
      totalLateCancels: toInt(json['total_late_cancels']),
      matchesPlayed: toInt(json['matches_played']),
      matchesWon: toInt(json['matches_won']),
      matchesLost: toInt(json['matches_lost']),
      matchesDraw: toInt(json['matches_draw']),
      showMatchHistory: json['show_match_history'] != false,
      isVerified: json['is_verified'] == true,
      preferredRoles: parseRoles(json['preferred_roles']),
    );
  }
}

class PublicPlayerProfile {
  const PublicPlayerProfile({
    required this.id,
    required this.name,
    required this.profileImageUrl,
    required this.skillLevel,
    required this.eloRating,
    required this.reliabilityScore,
    required this.matchesPlayed,
    required this.matchesWon,
    required this.matchesLost,
    required this.matchesDraw,
    required this.showMatchHistory,
    required this.preferredRoles,
  });

  final String id;
  final String name;
  final String profileImageUrl;
  final String skillLevel;
  final int eloRating;
  final int reliabilityScore;
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final int matchesDraw;
  final bool showMatchHistory;
  final List<String> preferredRoles;

  factory PublicPlayerProfile.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    String toStringValue(dynamic value) {
      if (value is String) return value;
      return '';
    }

    List<String> parseRoles(dynamic value) {
      if (value is! List) return const <String>[];
      return value
          .map((item) {
            if (item is Map<String, dynamic>) {
              return toStringValue(item['role']);
            }
            if (item is Map) {
              return toStringValue(item['role']);
            }
            if (item is String) {
              return item;
            }
            return '';
          })
          .where((role) => role.isNotEmpty)
          .toList(growable: false);
    }

    return PublicPlayerProfile(
      id: toStringValue(json['id']),
      name: toStringValue(json['name']),
      profileImageUrl: toStringValue(json['profile_image_url']),
      skillLevel: toStringValue(json['skill_level']),
      eloRating: toInt(json['elo_rating']),
      reliabilityScore: toInt(json['reliability_score']),
      matchesPlayed: toInt(json['matches_played']),
      matchesWon: toInt(json['matches_won']),
      matchesLost: toInt(json['matches_lost']),
      matchesDraw: toInt(json['matches_draw']),
      showMatchHistory: json['show_match_history'] != false,
      preferredRoles: parseRoles(json['preferred_roles']),
    );
  }
}

class UpdateProfileRequest {
  const UpdateProfileRequest({
    this.name,
    this.skillLevel,
    this.preferredRoles,
    this.showMatchHistory,
  });

  final String? name;
  final String? skillLevel;
  final List<String>? preferredRoles;
  final bool? showMatchHistory;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (name != null) 'name': name!.trim(),
      if (skillLevel != null) 'skill_level': skillLevel,
      if (preferredRoles != null) 'preferred_roles': preferredRoles,
      if (showMatchHistory != null) 'show_match_history': showMatchHistory,
    };
  }
}

class AvatarUploadUrlResponse {
  const AvatarUploadUrlResponse({required this.uploadUrl, required this.key});

  final String uploadUrl;
  final String key;

  factory AvatarUploadUrlResponse.fromJson(Map<String, dynamic> json) {
    final uploadUrl = (json['uploadUrl'] ?? json['url'] ?? '').toString();
    final key = (json['key'] ?? '').toString();

    return AvatarUploadUrlResponse(uploadUrl: uploadUrl, key: key);
  }
}
