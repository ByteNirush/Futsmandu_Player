class Friend {
  const Friend({
    required this.id,
    required this.friendshipId,
    required this.name,
    required this.avatarUrl,
    required this.skillLevel,
    required this.eloRating,
    required this.matchesPlayed,
    required this.reliabilityScore,
    required this.since,
  });

  final String id;
  final String friendshipId;
  final String name;
  final String avatarUrl;
  final String skillLevel;
  final int eloRating;
  final int matchesPlayed;
  final int reliabilityScore;
  final String since;

  factory Friend.fromMap(Map<String, dynamic> raw) {
    return Friend(
      id: _string(raw['id']),
      friendshipId: _string(raw['friendshipId']),
      name: _string(raw['name']),
      avatarUrl: _string(raw['avatarUrl']),
      skillLevel: _string(raw['skillLevel']),
      eloRating: _toInt(raw['eloRating']),
      matchesPlayed: _toInt(raw['matchesPlayed']),
      reliabilityScore: _toInt(raw['reliabilityScore']),
      since: _string(raw['since']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'friendshipId': friendshipId,
      'name': name,
      'avatarUrl': avatarUrl,
      'skillLevel': skillLevel,
      'eloRating': eloRating,
      'matchesPlayed': matchesPlayed,
      'reliabilityScore': reliabilityScore,
      'since': since,
    };
  }
}

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.friendshipId,
    required this.name,
    required this.avatarUrl,
    required this.skillLevel,
    required this.mutualFriends,
  });

  final String id;
  final String friendshipId;
  final String name;
  final String avatarUrl;
  final String skillLevel;
  final int mutualFriends;

  factory FriendRequest.fromMap(Map<String, dynamic> raw) {
    return FriendRequest(
      id: _string(raw['id']),
      friendshipId: _string(raw['friendshipId']),
      name: _string(raw['name']),
      avatarUrl: _string(raw['avatarUrl']),
      skillLevel: _string(raw['skillLevel']),
      mutualFriends: _toInt(raw['mutualFriends']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'friendshipId': friendshipId,
      'name': name,
      'avatarUrl': avatarUrl,
      'skillLevel': skillLevel,
      'mutualFriends': mutualFriends,
    };
  }
}

class SearchPlayer {
  const SearchPlayer({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.skillLevel,
    required this.eloRating,
    required this.matchesPlayed,
    required this.status,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String skillLevel;
  final int eloRating;
  final int matchesPlayed;
  final String status;

  factory SearchPlayer.fromMap(Map<String, dynamic> raw) {
    return SearchPlayer(
      id: _string(raw['id']),
      name: _string(raw['name']),
      avatarUrl: _string(raw['avatarUrl']),
      skillLevel: _string(raw['skillLevel']),
      eloRating: _toInt(raw['eloRating']),
      matchesPlayed: _toInt(raw['matchesPlayed']),
      status: _string(raw['status']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'skillLevel': skillLevel,
      'eloRating': eloRating,
      'matchesPlayed': matchesPlayed,
      'status': status,
    };
  }
}

class FriendRequestResult {
  const FriendRequestResult({
    required this.friendshipId,
    required this.status,
    required this.message,
  });

  final String friendshipId;
  final String status;
  final String message;

  factory FriendRequestResult.fromMap(Map<String, dynamic> raw) {
    return FriendRequestResult(
      friendshipId: _string(raw['friendshipId']),
      status: _string(raw['status']),
      message: _string(raw['message']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'friendshipId': friendshipId,
      'status': status,
      'message': message,
    };
  }
}

class BlockResult {
  const BlockResult({
    required this.playerId,
    required this.success,
    required this.message,
  });

  final String playerId;
  final bool success;
  final String message;

  factory BlockResult.fromMap(Map<String, dynamic> raw) {
    return BlockResult(
      playerId: _string(raw['playerId']),
      success: raw['success'] == true,
      message: _string(raw['message']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'success': success,
      'message': message,
    };
  }
}

String _string(dynamic value) {
  if (value is String) return value;
  return '';
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
