/// Shared parsing for Saefra Run API responses and Laravel-style errors.
class ApiResponseParser {
  ApiResponseParser._();

  static bool isSuccess(dynamic data, int? statusCode) {
    if (statusCode == null || statusCode < 200 || statusCode >= 300) {
      return false;
    }
    if (data is Map<String, dynamic> && data.containsKey('success')) {
      return data['success'] == true;
    }
    return true;
  }

  static String parseErrorMessage(
    dynamic data, {
    String fallback = 'Something went wrong.',
  }) {
    if (data is! Map<String, dynamic>) return fallback;

    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    final errors = data['errors'];
    if (errors is Map) {
      final parts = <String>[];
      for (final entry in errors.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          parts.add(value.first.toString());
        } else if (value is String && value.isNotEmpty) {
          parts.add(value);
        }
      }
      if (parts.isNotEmpty) return parts.join('\n');
    }

    return fallback;
  }

  static Map<String, dynamic> asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}
