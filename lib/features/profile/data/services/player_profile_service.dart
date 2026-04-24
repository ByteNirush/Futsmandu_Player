import 'dart:developer' as developer;
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

  Future<AvatarUploadUrlResponse> requestAvatarUploadUrl({
    String? contentType = 'image/jpeg',
  }) async {
    try {
      final requestBody = AvatarUploadUrlRequest(
        contentType: contentType,
      ).toJson();

      developer.log(
        '[AvatarUpload] Requesting upload URL',
        name: 'PlayerProfileService',
        error: {
          'endpoint': ApiConfig.profileAvatarUploadUrlEndpoint,
          'requestBody': requestBody,
        },
      );

      final response = await _apiClient.post(
        ApiConfig.profileAvatarUploadUrlEndpoint,
        data: requestBody,
      );

      developer.log(
        '[AvatarUpload] Upload URL received',
        name: 'PlayerProfileService',
        error: {
          'statusCode': response.statusCode,
          'responseData': response.data,
        },
      );

      final upload = AvatarUploadUrlResponse.fromJson(
        _asMap(_unwrap(response.data)),
      );
      if (upload.uploadUrl.isEmpty || upload.key.isEmpty || upload.assetId.isEmpty) {
        throw const ProfileApiException(
          message: 'Avatar upload response is invalid (missing url, key, or assetId)',
          statusCode: 500,
        );
      }
      return upload;
    } on DioException catch (error) {
      developer.log(
        '[AvatarUpload] Failed to get upload URL',
        name: 'PlayerProfileService',
        error: {
          'statusCode': error.response?.statusCode,
          'responseData': error.response?.data,
          'errorMessage': error.message,
          'errorType': error.type.toString(),
        },
      );
      throw _toProfileApiException(error);
    }
  }

  Future<void> confirmAvatarUpload({
    required String assetId,
    required String key,
  }) async {
    try {
      developer.log(
        '[AvatarUpload] Confirming avatar upload',
        name: 'PlayerProfileService',
        error: {
          'assetId': assetId,
          'key': key,
        },
      );

      await _apiClient.post(
        ApiConfig.profileAvatarConfirmEndpoint,
        data: <String, dynamic>{
          'assetId': assetId,
          'key': key,
        },
      );

      developer.log(
        '[AvatarUpload] Avatar upload confirmed successfully',
        name: 'PlayerProfileService',
      );
    } on DioException catch (error) {
      developer.log(
        '[AvatarUpload] Failed to confirm avatar upload',
        name: 'PlayerProfileService',
        error: {
          'statusCode': error.response?.statusCode,
          'responseData': error.response?.data,
          'errorMessage': error.message,
        },
      );
      throw _toProfileApiException(error);
    }
  }

  Future<void> uploadAvatarBytes(
    Uint8List bytes, {
    String contentType = 'image/jpeg',
  }) async {
    developer.log(
      '[AvatarUpload] Starting avatar upload',
      name: 'PlayerProfileService',
      error: {
        'bytesLength': bytes.length,
        'contentType': contentType,
      },
    );

    final uploadPayload = await requestAvatarUploadUrl(
      contentType: contentType,
    );

    developer.log(
      '[AvatarUpload] Uploading to presigned URL',
      name: 'PlayerProfileService',
      error: {
        'uploadUrl': uploadPayload.uploadUrl.substring(0, 50) + '...',
        'key': uploadPayload.key,
        'assetId': uploadPayload.assetId,
      },
    );

    final uploadResponse = await _client.put(
      Uri.parse(uploadPayload.uploadUrl),
      headers: <String, String>{
        'Content-Type': contentType,
      },
      body: bytes,
    );

    developer.log(
      '[AvatarUpload] Presigned URL upload response',
      name: 'PlayerProfileService',
      error: {
        'statusCode': uploadResponse.statusCode,
      },
    );

    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      throw ProfileApiException(
        message: 'Avatar upload failed (${uploadResponse.statusCode})',
        statusCode: uploadResponse.statusCode,
      );
    }

    await confirmAvatarUpload(
      assetId: uploadPayload.assetId,
      key: uploadPayload.key,
    );

    developer.log(
      '[AvatarUpload] Avatar upload completed successfully',
      name: 'PlayerProfileService',
    );
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
