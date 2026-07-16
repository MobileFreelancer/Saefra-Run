class ApiResponseParser {
  ApiResponseParser._();

  static bool isSuccess(dynamic data, int? statusCode) {
    if (statusCode == null || statusCode < 200 || statusCode >= 300) {
      return false;
    }
    if (data is! Map) return true;

    final map = asMap(data);

    if (map.containsKey('success')) {
      final success = map['success'];
      if (success is bool) return success;
      if (success is num) return success != 0;
      if (success is String) {
        final normalized = success.toLowerCase();
        return normalized == 'true' || normalized == '1';
      }
      return false;
    }

    if (map.containsKey('status')) {
      final status = map['status']?.toString().toLowerCase();
      if (status == 'fail' || status == 'failed' || status == 'error') {
        return false;
      }
      if (status == 'success' || status == 'ok') {
        return true;
      }
    }

    return true;
  }

  static Map<String, dynamic> payload(dynamic data) {
    final map = asMap(data);
    final inner = map['data'];
    if (inner is Map) {
      return asMap(inner);
    }
    return map;
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
