String friendlyError(
  Object? error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  var message = _extractMessage(error).trim();
  if (message.isEmpty) return fallback;

  message = message
      .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^DioException\s*\[[^\]]+\]:\s*', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^DioException:\s*', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^Error:\s*', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^Failed to\s+', caseSensitive: false), '')
      .trim();

  final lower = message.toLowerCase();

  if (lower.contains('socketexception') ||
      lower.contains('connection refused') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable') ||
      lower.contains('connection error') ||
      lower.contains('xmlhttprequest error')) {
    return 'Internet connection issue. Please check your network and try again.';
  }
  if (lower.contains('connection timed out') ||
      lower.contains('receive timeout') ||
      lower.contains('send timeout') ||
      lower.contains('timeout')) {
    return 'Request took too long. Please try again.';
  }
  if (lower.contains('401') ||
      lower.contains('unauthorized') ||
      lower.contains('jwt') ||
      lower.contains('token') ||
      lower.contains('login required') ||
      lower.contains('no auth')) {
    return 'Session expired. Please login again.';
  }
  if (lower.contains('403') ||
      lower.contains('forbidden') ||
      lower.contains('not authorized') ||
      lower.contains('permission')) {
    return 'You do not have permission for this action.';
  }
  if (lower.contains('404') || lower.contains('not found')) {
    return 'This item is no longer available.';
  }
  if (lower.contains('500') ||
      lower.contains('502') ||
      lower.contains('503') ||
      lower.contains('504') ||
      lower.contains('server error') ||
      lower.contains('internal server')) {
    return 'Server is busy right now. Please try again shortly.';
  }
  if (lower.contains('validation') ||
      lower.contains('joi') ||
      lower.contains('cast to objectid') ||
      lower.contains('objectid') ||
      lower.contains('mongoose') ||
      lower.contains('duplicate key') ||
      lower.contains('e11000')) {
    return 'Please check the details and try again.';
  }
  if (message.startsWith('{') ||
      message.startsWith('[') ||
      message.contains('stack trace') ||
      message.contains(' at ') ||
      message.contains('package:') ||
      message.contains('/api/') ||
      message.contains('\\backend\\') ||
      message.length > 180) {
    return fallback;
  }

  return message;
}

String _extractMessage(Object? error) {
  if (error == null) return '';
  if (error is String) return error;
  return error.toString();
}
