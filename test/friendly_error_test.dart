import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scores11/core/utils/friendly_error.dart';

DioException _bad(int status, Object? data) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  test('shows the API message from a bad response', () {
    expect(
      friendlyError(_bad(400, {'message': 'Insufficient stock for Bat'})),
      'Insufficient stock for Bat',
    );
  });

  test('YouTube reconnect message is not mistaken for a logout', () {
    expect(
      friendlyError(_bad(400, {'message': 'YouTube channel is not connected. Connect YouTube first.'})),
      'YouTube channel is not connected. Connect YouTube first.',
    );
  });

  test('falls back when the response has no message', () {
    expect(friendlyError(_bad(400, 'oops'), fallback: 'FB'), 'FB');
  });

  test('connection errors read as network issues', () {
    final e = DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionError,
    );
    expect(friendlyError(e), contains('Internet connection'));
  });

  test('a 400 explanation from the API is shown as written', () {
    const text =
        'This YouTube video was not found. Make sure the live stream is Public or Unlisted, then paste its link again.';
    expect(friendlyError(_bad(400, {'message': text})), text);
  });

  test('database error text in a 400 is still hidden', () {
    expect(
      friendlyError(_bad(400, {'message': 'Cast to ObjectId failed for value "x"'}), fallback: 'FB'),
      isNot(contains('ObjectId')),
    );
  });
}
