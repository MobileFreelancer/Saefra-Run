class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final int? retryAfter;

  const ApiException(this.message, [this.statusCode, this.retryAfter]);

  @override
  String toString() => message;
}
