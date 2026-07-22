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
    final data = ApiResponseParser.payload(json);
    final userJson = ApiResponseParser.userFromPayload(data);

    return AuthResponseModel(
      accessToken: _readToken(data),
      user: UserModel.fromJson(userJson),
    );
  }

  static String _readToken(Map<String, dynamic> data) {
    final token = data['token'] ?? data['access_token'] ?? data['accessToken'];
    if (token == null) return '';
    return token.toString();
  }
}
