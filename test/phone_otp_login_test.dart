import 'package:flutter_test/flutter_test.dart';
import 'package:scores11/data/models/user_model.dart';
import 'package:scores11/data/services/auth_service.dart';
import 'package:scores11/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backend stand-in with the same replies as /auth/phone/send-otp and
/// /auth/phone/verify-otp.
class FakeOtpBackend extends AuthService {
  final Map<String, String> sentCodes = {};
  final Set<String> registered = {'9000000009'};
  final List<Map<String, dynamic>> verifyCalls = [];

  // Called by AuthProvider after sign-in; no network in tests.
  @override
  Future<dynamic> getUserStats() async => null;

  @override
  Future<Map<String, dynamic>> sendPhoneOtp(String phone) async {
    if (sentCodes.containsKey(phone)) {
      return {
        'success': false,
        'message': 'Please wait 25 seconds before requesting a new OTP.',
        'code': 'OTP_RESEND_WAIT',
        'retryAfterSeconds': 25,
      };
    }
    sentCodes[phone] = '123456';
    return {'success': true, 'isNewUser': !registered.contains(phone), 'resendInSeconds': 30, 'otpLength': 6};
  }

  @override
  Future<Map<String, dynamic>> verifyPhoneOtp({
    String? phone,
    String? otp,
    String? verificationToken,
    String? name,
    String? email,
    String? playerRole,
    String? battingStyle,
    String? bowlingStyle,
  }) async {
    verifyCalls.add({'phone': phone, 'otp': otp, 'token': verificationToken, 'name': name});
    String? verified;
    if (verificationToken != null) {
      verified = verificationToken == 'tok-9123456789' ? '9123456789' : null;
      if (verified == null) {
        return {'success': false, 'message': 'Your verification expired. Please request a new OTP.'};
      }
    } else {
      if (sentCodes[phone] != otp) {
        return {'success': false, 'message': 'Incorrect OTP. 4 attempts left.', 'code': 'OTP_INVALID'};
      }
      verified = phone;
    }
    if (!registered.contains(verified) && (name == null || name.isEmpty)) {
      return {
        'success': false,
        'message': 'Add your name to create your Scores11 account',
        'code': 'PROFILE_REQUIRED',
        'verificationToken': 'tok-$verified',
      };
    }
    registered.add(verified!);
    return {
      'success': true,
      'data': {
        'user': UserModel.fromJson({'_id': 'u-$verified', 'fullName': name ?? 'Existing', 'phone': verified, 'email': '', 'role': 'player'}),
      },
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('existing number: send OTP, verify, signed in', () async {
    final backend = FakeOtpBackend();
    final auth = AuthProvider(authService: backend);
    expect(await auth.sendPhoneOtp('9000000009'), isTrue);
    expect(auth.otpResendSeconds, 30);
    expect(await auth.loginWithPhoneOtp(phone: '9000000009', otp: '123456'), isTrue);
    expect(auth.status, AuthStatus.authenticated);
    expect(auth.user?.id, 'u-9000000009');
  });

  test('wrong OTP shows the server message and stays signed out', () async {
    final auth = AuthProvider(authService: FakeOtpBackend());
    await auth.sendPhoneOtp('9000000009');
    expect(await auth.loginWithPhoneOtp(phone: '9000000009', otp: '000000'), isFalse);
    expect(auth.errorMessage, contains('Incorrect OTP'));
    expect(auth.authActionCode, 'OTP_INVALID');
    expect(auth.status, isNot(AuthStatus.authenticated));
  });

  test('new number: verify, then add a name without a second OTP', () async {
    final backend = FakeOtpBackend();
    final auth = AuthProvider(authService: backend);
    await auth.sendPhoneOtp('9123456789');
    expect(await auth.loginWithPhoneOtp(phone: '9123456789', otp: '123456'), isFalse);
    expect(auth.authActionCode, 'PROFILE_REQUIRED');
    expect(auth.phoneVerificationToken, 'tok-9123456789');

    expect(await auth.loginWithPhoneOtp(name: 'Ravi Kumar'), isTrue);
    expect(backend.verifyCalls.last['token'], 'tok-9123456789');
    expect(backend.verifyCalls.last['otp'], isNull, reason: 'the used OTP is not sent again');
    expect(auth.status, AuthStatus.authenticated);
    expect(auth.phoneVerificationToken, isNull);
  });

  test('resend too soon gives the wait time', () async {
    final auth = AuthProvider(authService: FakeOtpBackend());
    await auth.sendPhoneOtp('9000000009');
    expect(await auth.sendPhoneOtp('9000000009'), isFalse);
    expect(auth.authActionCode, 'OTP_RESEND_WAIT');
    expect(auth.otpResendSeconds, 25);
  });

  test('register screen style: OTP + name in one step for a new number', () async {
    final backend = FakeOtpBackend();
    final auth = AuthProvider(authService: backend);
    await auth.sendPhoneOtp('9811111111');
    expect(await auth.loginWithPhoneOtp(phone: '9811111111', otp: '123456', name: 'Neha'), isTrue);
    expect(backend.verifyCalls.last['phone'], '9811111111');
    expect(backend.verifyCalls.last['otp'], '123456');
  });
}
