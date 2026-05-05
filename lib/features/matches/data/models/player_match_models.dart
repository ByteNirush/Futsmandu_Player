class MatchMember {
  const MatchMember({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.skillLevel,
    required this.eloRating,
    required this.position,
    required this.team,
    required this.status,
    required this.isAdmin,
    this.joinedAt,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String skillLevel;
  final int eloRating;
  final String position;
  final String team;
  final String status;
  final bool isAdmin;
  final String? joinedAt;

  factory MatchMember.fromMap(Map<String, dynamic> raw) {
    final profileImageUrl =
        _string(raw['avatarUrl']).isNotEmpty ? _string(raw['avatarUrl']) : _string(raw['profileImageUrl']);
    final role = _string(raw['role']);
    return MatchMember(
      id: _string(raw['id']).isNotEmpty ? _string(raw['id']) : _string(raw['userId']),
      name: _string(raw['name']),
      avatarUrl: profileImageUrl,
      skillLevel: _string(raw['skillLevel']),
      eloRating: _toInt(raw['eloRating']),
      position: _string(raw['position']).isNotEmpty ? _string(raw['position']) : '-',
      team: _string(raw['team']).isNotEmpty ? _string(raw['team']) : '-',
      status: _string(raw['status']),
      isAdmin: raw['isAdmin'] == true || role == 'admin',
      joinedAt: _string(raw['joinedAt']).isNotEmpty ? _string(raw['joinedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'skillLevel': skillLevel,
      'eloRating': eloRating,
      'position': position,
      'team': team,
      'status': status,
      'isAdmin': isAdmin,
      'joinedAt': joinedAt,
    };
  }
}

class MatchSummary {
  const MatchSummary({
    required this.id,
    required this.matchGroupId,
    required this.venueId,
    required this.venueName,
    required this.venueImage,
    required this.venueAddress,
    required this.courtName,
    required this.date,
    required this.matchDate,
    required this.time,
    required this.endTime,
    required this.spotsLeft,
    required this.maxPlayers,
    required this.memberCount,
    required this.slotsAvailable,
    required this.playersNeeded,
    required this.skillLevel,
    required this.skillFilter,
    required this.distance,
    required this.fillStatus,
    required this.costSplitMode,
    required this.description,
    required this.isPartialTeamBooking,
    required this.friendsIn,
    required this.isOpen,
    required this.isAdmin,
    required this.adminId,
    required this.priceNpr,
    required this.offlinePlayersCount,
    this.amenities = const [],
  });

  final String id;
  final String matchGroupId;
  final String venueId;
  final String venueName;
  final String venueImage;
  final String venueAddress;
  final String courtName;
  final String date;
  final String matchDate;
  final String time;
  final String endTime;
  final int spotsLeft;
  final int maxPlayers;
  final int memberCount;
  final int slotsAvailable;
  final int playersNeeded;
  final String skillLevel;
  final String skillFilter;
  final String distance;
  final String fillStatus;
  final String costSplitMode;
  final String description;
  final bool isPartialTeamBooking;
  final int friendsIn;
  final bool isOpen;
  final bool isAdmin;
  final String adminId;
  final String priceNpr;
  final int offlinePlayersCount;
  final List<String> amenities;

  factory MatchSummary.fromMap(Map<String, dynamic> raw) {
    return MatchSummary(
      id: _string(raw['id']),
      matchGroupId: _string(raw['matchGroupId']),
      venueId: _string(raw['venueId']),
      venueName: _string(raw['venueName']),
      venueImage: _string(raw['venueImage']),
      venueAddress: _string(raw['venueAddress']),
      courtName: _string(raw['courtName']),
      date: _string(raw['date']),
      matchDate: _string(raw['matchDate']),
      time: _string(raw['time']),
      endTime: _string(raw['endTime']),
      spotsLeft: _toInt(raw['spotsLeft']),
      maxPlayers: _toInt(raw['maxPlayers']),
      memberCount: _toInt(raw['memberCount']),
      slotsAvailable: _toInt(raw['slotsAvailable']),
      playersNeeded: _toInt(raw['playersNeeded']),
      skillLevel: _string(raw['skillLevel']),
      skillFilter: _string(raw['skillFilter']),
      distance: _string(raw['distance']),
      fillStatus: _string(raw['fillStatus']),
      costSplitMode: _string(raw['costSplitMode']),
      description: _string(raw['description']),
      isPartialTeamBooking: raw['isPartialTeamBooking'] == true,
      friendsIn: _toInt(raw['friendsIn']),
      isOpen: raw['isOpen'] == true,
      isAdmin: raw['isAdmin'] == true,
      adminId: _string(raw['adminId']),
      priceNpr: _string(raw['priceNPR']),
      offlinePlayersCount: _toInt(raw['offlinePlayersCount']),
      amenities: _asStringList(raw['amenities']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchGroupId': matchGroupId,
      'venueId': venueId,
      'venueName': venueName,
      'venueImage': venueImage,
      'venueAddress': venueAddress,
      'courtName': courtName,
      'date': date,
      'matchDate': matchDate,
      'time': time,
      'endTime': endTime,
      'spotsLeft': spotsLeft,
      'maxPlayers': maxPlayers,
      'memberCount': memberCount,
      'slotsAvailable': slotsAvailable,
      'playersNeeded': playersNeeded,
      'skillLevel': skillLevel,
      'skillFilter': skillFilter,
      'distance': distance,
      'fillStatus': fillStatus,
      'costSplitMode': costSplitMode,
      'description': description,
      'isPartialTeamBooking': isPartialTeamBooking,
      'friendsIn': friendsIn,
      'isOpen': isOpen,
      'isAdmin': isAdmin,
      'adminId': adminId,
      'priceNPR': priceNpr,
      'offlinePlayersCount': offlinePlayersCount,
      'amenities': amenities,
    };
  }
}

class MatchDetail {
  const MatchDetail({
    required this.summary,
    required this.courtType,
    required this.courtSurface,
    required this.inviteToken,
    required this.inviteExpiresAt,
    required this.resultWinner,
    required this.members,
    required this.confirmedMembers,
    required this.pendingMembers,
    required this.currentUserMember,
  });

  final MatchSummary summary;
  final String courtType;
  final String courtSurface;
  final String inviteToken;
  final String inviteExpiresAt;
  final String resultWinner;
  final List<MatchMember> members;
  final List<MatchMember> confirmedMembers;
  final List<MatchMember> pendingMembers;
  final MatchMember? currentUserMember;

  factory MatchDetail.fromMap(Map<String, dynamic> raw) {
    final members = _asMapList(raw['members'])
        .map(MatchMember.fromMap)
        .toList(growable: false);
    final confirmed = _asMapList(raw['confirmedMembers'])
        .map(MatchMember.fromMap)
        .toList(growable: false);
    final pending = _asMapList(raw['pendingMembers'])
        .map(MatchMember.fromMap)
        .toList(growable: false);

    final current = raw['currentUserMember'] is Map
        ? MatchMember.fromMap(
            (raw['currentUserMember'] as Map).cast<String, dynamic>())
        : null;

    return MatchDetail(
      summary: MatchSummary.fromMap(raw),
      courtType: _string(raw['courtType']),
      courtSurface: _string(raw['courtSurface']),
      inviteToken: _string(raw['inviteToken']),
      inviteExpiresAt: _string(raw['inviteExpiresAt']),
      resultWinner: _string(raw['resultWinner']),
      members: members,
      confirmedMembers: confirmed,
      pendingMembers: pending,
      currentUserMember: current,
    );
  }

  Map<String, dynamic> toMap() {
    final base = summary.toMap();
    return {
      ...base,
      'courtType': courtType,
      'courtSurface': courtSurface,
      'inviteToken': inviteToken,
      'inviteExpiresAt': inviteExpiresAt,
      'resultWinner': resultWinner,
      'members': members.map((item) => item.toMap()).toList(growable: false),
      'confirmedMembers':
          confirmedMembers.map((item) => item.toMap()).toList(growable: false),
      'pendingMembers':
          pendingMembers.map((item) => item.toMap()).toList(growable: false),
      'currentUserMember':
          currentUserMember?.toMap() ?? const <String, dynamic>{},
      'venue': {
        'name': summary.venueName,
        'cover_image_url': summary.venueImage,
        'address': summary.venueAddress,
      },
      'court': {
        'name': summary.courtName,
        'court_type': courtType,
        'surface': courtSurface,
      },
    };
  }
}

class MatchInvitePreview {
  const MatchInvitePreview({
    required this.matchGroupId,
    required this.venueName,
    required this.venueAddress,
    required this.venueImage,
    required this.date,
    required this.startTime,
    required this.spotsLeft,
    required this.skillFilter,
  });

  final String matchGroupId;
  final String venueName;
  final String venueAddress;
  final String venueImage;
  final String date;
  final String startTime;
  final int spotsLeft;
  final String skillFilter;

  factory MatchInvitePreview.fromMap(Map<String, dynamic> raw) {
    return MatchInvitePreview(
      matchGroupId: _string(raw['matchGroupId']),
      venueName: _string(raw['venueName']),
      venueAddress: _string(raw['venueAddress']),
      venueImage: _string(raw['venueImage']),
      date: _string(raw['date']),
      startTime: _string(raw['startTime']),
      spotsLeft: _toInt(raw['spotsLeft']),
      skillFilter: _string(raw['skillFilter']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matchGroupId': matchGroupId,
      'venueName': venueName,
      'venueAddress': venueAddress,
      'venueImage': venueImage,
      'date': date,
      'startTime': startTime,
      'spotsLeft': spotsLeft,
      'skillFilter': skillFilter,
    };
  }
}

class MatchInviteLink {
  const MatchInviteLink({
    required this.url,
    required this.token,
  });

  final String url;
  final String token;

  factory MatchInviteLink.fromMap(Map<String, dynamic> raw) {
    return MatchInviteLink(
      url: _string(raw['url']),
      token: _string(raw['token']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'token': token,
    };
  }
}

class MatchJoinRequest {
  const MatchJoinRequest({
    required this.id,
    required this.matchId,
    required this.playerId,
    required this.playerName,
    required this.playerAvatarUrl,
    required this.requestedPosition,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String matchId;
  final String playerId;
  final String playerName;
  final String playerAvatarUrl;
  final String requestedPosition;
  final String status;
  final String createdAt;

  factory MatchJoinRequest.fromMap(Map<String, dynamic> raw) {
    return MatchJoinRequest(
      id: _string(raw['id']),
      matchId: _string(raw['matchId']).isNotEmpty
        ? _string(raw['matchId'])
        : _string(raw['match_group_id']),
      playerId: _string(raw['playerId']).isNotEmpty
        ? _string(raw['playerId'])
        : _string(raw['user_id']),
      playerName: _string(raw['playerName']),
      playerAvatarUrl: _string(raw['playerAvatarUrl']).isNotEmpty
        ? _string(raw['playerAvatarUrl'])
        : _string(raw['profileImageUrl']),
      requestedPosition: _string(raw['requestedPosition']).isNotEmpty
        ? _string(raw['requestedPosition'])
        : _string(raw['position']),
      status: _string(raw['status']),
      createdAt: _string(raw['createdAt']).isNotEmpty
        ? _string(raw['createdAt'])
        : _string(raw['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'playerId': playerId,
      'playerName': playerName,
      'playerAvatarUrl': playerAvatarUrl,
      'requestedPosition': requestedPosition,
      'status': status,
      'createdAt': createdAt,
    };
  }
}

class MatchJoinResponse {
  const MatchJoinResponse({
    required this.requestId,
    required this.matchId,
    required this.playerId,
    required this.action,
    required this.message,
  });

  final String requestId;
  final String matchId;
  final String playerId;
  final String action;
  final String message;

  factory MatchJoinResponse.fromMap(Map<String, dynamic> raw) {
    final status = _string(raw['status']);
    return MatchJoinResponse(
      requestId: _string(raw['requestId']).isNotEmpty
          ? _string(raw['requestId'])
          : _string(raw['id']),
      matchId: _string(raw['matchId']).isNotEmpty
          ? _string(raw['matchId'])
          : _string(raw['match_group_id']),
      playerId: _string(raw['playerId']).isNotEmpty
          ? _string(raw['playerId'])
          : _string(raw['user_id']),
      action: _string(raw['action']).isNotEmpty ? _string(raw['action']) : status,
      message: _string(raw['message']).isNotEmpty
          ? _string(raw['message'])
          : (status.isNotEmpty ? 'Request $status' : 'Request updated'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'matchId': matchId,
      'playerId': playerId,
      'action': action,
      'message': message,
    };
  }
}

class MatchMemberAddResult {
  const MatchMemberAddResult({
    required this.friendId,
    required this.success,
    required this.message,
  });

  final String friendId;
  final bool success;
  final String message;

  factory MatchMemberAddResult.fromMap(Map<String, dynamic> raw) {
    final memberId = _string(raw['id']);
    return MatchMemberAddResult(
      friendId: _string(raw['friendId']).isNotEmpty
          ? _string(raw['friendId'])
          : _string(raw['user_id']),
      success: raw['success'] == true || memberId.isNotEmpty,
      message: _string(raw['message']).isNotEmpty
          ? _string(raw['message'])
          : (memberId.isNotEmpty
              ? 'Friend added to match'
              : 'Unable to add friend to match'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'friendId': friendId,
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

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList(growable: false);
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().toList(growable: false);
}
