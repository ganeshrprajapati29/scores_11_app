import 'dart:async';

/// Debounce class to delay function execution until a certain time
/// has passed since the last call. This is useful for search functionality
/// to avoid making API calls on every keystroke.
///
/// Example usage:
/// ```dart
/// Debounce debounce = Debounce(Duration(milliseconds: 500));
///
/// onSearch(String value) {
///   debounce.run(() {
///     searchPlayer(value);
///   });
/// }
/// ```
class Debounce {
  final Duration delay;
  Timer? _timer;

  Debounce({this.delay = const Duration(milliseconds: 500)});

  /// Run the callback after the delay, canceling any pending calls
  void run(void Function() callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  /// Cancel any pending debounced call
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Check if there's a pending callback
  bool get isActive => _timer?.isActive ?? false;

  /// Dispose the debounce timer
  void dispose() {
    cancel();
  }
}

