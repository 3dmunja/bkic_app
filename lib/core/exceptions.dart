class SessionExpiredException implements Exception {
  final String message;
  const SessionExpiredException([this.message = 'Sesija je istekla']);

  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}