import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/services/player_http_client.dart';
import '../models/player_profile_models.dart';

class ProfileApiException implements Exception {
  const ProfileApiException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => 'ProfileApiException($statusCode): $message';
}

class PlayerProfileService {
  PlayerProfileService._internal();

  static final PlayerProfileService instance = PlayerProfileService._internal();

  final ApiClient _apiClient = ApiClient.instance;
  final http.Client _client = createPlayerHttpClient();

  Future<PlayerProfile> getOwnProfile() async {
    try {
      final response = await _apiClient.get(ApiConfig.profileEndpoint);
      return PlayerProfile.fromJson(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toProfileApiException(error);
    }
  }

  Future<PlayerProfile> updateOwnProfile(UpdateProfileRequest request) async {
    try {
      await _apiClient.put(
        ApiConfig.profileEndpoint,
        data: request.toJson(),
      );
      return await getOwnProfile();
    } on DioException catch (error) {
      throw _toProfileApiException(error);
    }
  }

  Future<PublicPlayerProfile> getPublicProfile(String userId) async {
    try {
      final response =
          await _apiClient.get(ApiConfig.publicProfileEndpoint(userId));
      return PublicPlayerProfile.fromJson(_asMap(_unwrap(response.data)));
    } on DioException catch (error) {
      throw _toProfileApiException(error);
    }
  }

  Future<AvatarUploadUrlResponse> requestAvatarUploadUrl() async {
    try {
      final response =
          await _apiClient.post(ApiConfig.profileAvatarUploadUrlEndpoint);
      final upload = AvatarUploadUrlResponse.fromJson(
        _asMap(_unwrap(response.data)),
      );
      if (upload.uploadUrl.isEmpty || upload.key.isEmpty) {
        throw const ProfileApiException(
          message: 'Avatar upload response is invalid',
          statusCode: 500,
        );
      }
      return upload;
    } on DioException catch (error) {
      throw _toProfileApiException(error);
    }
  }

  Future<void> confirmAvatarUpload({required String key}) async {
    try {
      await _apiClient.post(
        ApiConfig.profileAvatarConfirmEndpoint,
        data: <String, dynamic>{'key': key},
      );
    } on DioException catch (error) {
      throw _toProfileApiException(error);
    }
  }

  Future<void> uploadAvatarBytes(Uint8List bytes) async {
    final uploadPayload = await requestAvatarUploadUrl();

    final uploadResponse = await _client.put(
      Uri.parse(uploadPayload.uploadUrl),
      headers: const <String, String>{
        'Content-Type': 'image/jpeg',
      },
      body: bytes,
    );

    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      throw ProfileApiException(
        message: 'Avatar upload failed (${uploadResponse.statusCode})',
        statusCode: uploadResponse.statusCode,
      );
    }

    await confirmAvatarUpload(key: uploadPayload.key);
  }

  dynamic _unwrap(dynamic body) {
    if (body is Map && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw const ProfileApiException(
      message: 'Unexpected server response',
      statusCode: 500,
    );
  }

  ProfileApiException _toProfileApiException(DioException error) {
    final statusCode = error.response?.statusCode ?? 500;
    return ProfileApiException(
      message: ErrorHandler.messageFor(error),
      statusCode: statusCode,
    );
  }
}
