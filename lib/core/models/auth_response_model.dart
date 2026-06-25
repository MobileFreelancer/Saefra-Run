import 'package:saefra_run/core/models/user_model.dart';

class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return AuthResponseModel(
      accessToken: data['access_token'] as String? ??
          data['accessToken'] as String? ??
          '',
      refreshToken: data['refresh_token'] as String? ??
          data['refreshToken'] as String? ??
          '',
      user: UserModel.fromJson(
        data['user'] as Map<String, dynamic>? ?? data,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'user': user.toJson(),
      };
}
