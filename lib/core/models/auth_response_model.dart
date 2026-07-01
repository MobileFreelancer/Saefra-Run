import 'package:saefra_run/core/models/user_model.dart';
import 'package:saefra_run/core/utils/api_response_parser.dart';



class AuthResponseModel {
  final String accessToken;
  final UserModel user;

  const AuthResponseModel({
    required this.accessToken,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = ApiResponseParser.asMap(json);
    final userJson = ApiResponseParser.asMap(data['user']);

    return AuthResponseModel(
      accessToken: data['token'] as String? ??
          data['access_token'] as String? ??
          data['accessToken'] as String? ??
          '',
      user: UserModel.fromJson(userJson),
    );
  }
}
