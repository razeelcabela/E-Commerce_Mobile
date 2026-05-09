class SocketException implements Exception {
  final String message;
  const SocketException(this.message);
  @override
  String toString() => 'SocketException: $message';
}
