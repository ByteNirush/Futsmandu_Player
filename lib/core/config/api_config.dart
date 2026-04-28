/// API endpoints for the Futsmandu Player app.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'FUTSMANDU_API_BASE_URL',
    defaultValue: 'http://localhost:3001',
    // defaultValue: 'http://192.168.18.104:3001',
  ); 
  static const String apiPrefix = '/api/v1/player';
  static const String authEndpoint = '$apiPrefix/auth';
  static const String venuesEndpoint = '$apiPrefix/venues';
  static const String bookingsEndpoint = '$apiPrefix/bookings';
  static const String paymentsEndpoint = '$apiPrefix/payments';
  static const String matchesEndpoint = '$apiPrefix/matches';
  static const String inviteEndpoint = '$apiPrefix/invite';
  static const String friendsEndpoint = '$apiPrefix/friends';
  static const String notificationsEndpoint = '$apiPrefix/notifications';
  static const String profileEndpoint = '$apiPrefix/profile';

  static const String registerEndpoint = '$authEndpoint/register';
  static const String verifyOtpEndpoint = '$authEndpoint/verify-otp';
  static const String resendOtpEndpoint = '$authEndpoint/resend-otp';
  static const String loginEndpoint = '$authEndpoint/login';
  static const String refreshEndpoint = '$authEndpoint/refresh';
  static const String logoutEndpoint = '$authEndpoint/logout';
  static const String forgotPasswordEndpoint = '$authEndpoint/forgot-password';
  static const String resetPasswordEndpoint = '$authEndpoint/reset-password';
  static const String verifyEmailEndpoint = '$authEndpoint/verify-email';

  static String venueAvailabilityEndpoint(String venueId) =>
      '$venuesEndpoint/$venueId/availability';

  static String bookingDetailEndpoint(String bookingId) =>
      '$bookingsEndpoint/$bookingId';

  static String cancelBookingEndpoint(String bookingId) =>
      '$bookingsEndpoint/$bookingId/cancel';

  static String joinBookingEndpoint(String bookingId) =>
      '$bookingsEndpoint/$bookingId/join';

  static const String khaltiInitiateEndpoint =
      '$paymentsEndpoint/khalti-initiate';
  static const String khaltiVerifyEndpoint = '$paymentsEndpoint/khalti-verify';
  static const String esewaInitiateEndpoint =
      '$paymentsEndpoint/esewa-initiate';
  static const String esewaVerifyEndpoint = '$paymentsEndpoint/esewa-verify';
  static const String paymentHistoryEndpoint = '$paymentsEndpoint/history';

  static String paymentDetailEndpoint(String paymentId) =>
      '$paymentsEndpoint/$paymentId';

  static String matchDetailEndpoint(String matchId) =>
      '$matchesEndpoint/$matchId';

  static String joinMatchEndpoint(String matchId) =>
      '$matchesEndpoint/$matchId/join';

  static String approveMatchMemberEndpoint(String matchId, String userId) =>
      '$matchesEndpoint/$matchId/approve/$userId';

  static String rejectMatchMemberEndpoint(String matchId, String userId) =>
      '$matchesEndpoint/$matchId/reject/$userId';

  static String leaveMatchEndpoint(String matchId) =>
      '$matchesEndpoint/$matchId/leave';

  static String updateMatchTeamsEndpoint(String matchId) =>
      '$matchesEndpoint/$matchId/teams';

  static String matchResultEndpoint(String matchId) =>
      '$matchesEndpoint/$matchId/result';

  static String matchInviteLinkEndpoint(String matchId) =>
      '$matchesEndpoint/$matchId/invite-link';

  static const String tonightMatchesEndpoint = '$matchesEndpoint/tonight';
  static const String tomorrowMatchesEndpoint = '$matchesEndpoint/tomorrow';
  static const String weekendMatchesEndpoint = '$matchesEndpoint/weekend';
    static const String openMatchesEndpoint = '$matchesEndpoint/open';

  static String invitePreviewEndpoint(String token) =>
      '$inviteEndpoint/$token/preview';

  static String publicProfileEndpoint(String userId) =>
      '$profileEndpoint/$userId';

  static const String profileAvatarEndpoint = '$profileEndpoint/avatar';
  static const String profileAvatarUploadUrlEndpoint =
      '$profileAvatarEndpoint/upload-url';
  static const String profileAvatarConfirmEndpoint =
      '$profileAvatarEndpoint/confirm';

  static String acceptFriendRequestEndpoint(String friendshipId) =>
      '$friendsEndpoint/$friendshipId/accept';

  static String friendByIdEndpoint(String friendshipId) =>
      '$friendsEndpoint/$friendshipId';

  static String blockPlayerEndpoint(String playerId) =>
      '$friendsEndpoint/$playerId/block';

  static const String markAllNotificationsReadEndpoint =
      '$notificationsEndpoint/read-all';

  static String markNotificationReadEndpoint(String notificationId) =>
      '$notificationsEndpoint/$notificationId/read';
}
