import 'package:flutter/material.dart';
import 'auth_design.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String identifier;
  final bool isForgotPassword;
  final Function(String otp) onVerify;
  final VoidCallback onResend;

  const OTPVerificationScreen({
    super.key,
    required this.identifier,
    this.isForgotPassword = false,
    required this.onVerify,
    required this.onResend,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  bool get _isComplete => _otp.length == 6;

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    if (!_isComplete) return;
    
    setState(() => _isLoading = true);
    await widget.onVerify(_otp);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      showBack: true,
      title: 'Verify OTP',
      subtitle: 'Enter the 6-digit code sent to\n${widget.identifier}',
      heroIcon: Icons.sms_rounded,
      heroImage: 'score 11/Login, Register, OTP 1080 x 720 PNG.png',
      belowCard: const AuthFeatureStrip(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthSuccessBanner(
            title: 'Code sent successfully',
            description: "We've sent a 6-digit verification code to ${widget.identifier}",
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Enter 6-digit code',
              style: TextStyle(color: AuthDesign.ink, fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
          const SizedBox(height: 14),
          AuthOtpBoxRow(
            controllers: _controllers,
            focusNodes: _focusNodes,
            onChanged: (index, value) => _onDigitChanged(index, value),
          ),
          const SizedBox(height: 14),
          const Center(
            child: AuthSecurityNote(text: 'For your security, never share your OTP with anyone.'),
          ),
          const SizedBox(height: 20),
          AuthPrimaryButton(
            onPressed: _isComplete ? _verify : null,
            label: widget.isForgotPassword ? 'Reset password' : 'Verify & Continue',
            loading: _isLoading,
            icon: Icons.verified_user_rounded,
            trailingArrow: true,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: widget.onResend,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text("Didn't receive code? Resend", style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AuthDesign.muted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Having trouble? Check your spam folder or wait a minute before requesting a new code.',
                    style: TextStyle(fontSize: 11.5, color: AuthDesign.muted, fontWeight: FontWeight.w600, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
