import 'dart:async'; // Added for Timer
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/utils/formatters.dart';
import 'package:saefra_run/core/widgets/otp_input.dart';
import '../../../core/widgets/auth_header.dart';
import '../../onboarding/widgets/common_app_button.dart';

class VerificationCodeScreen extends StatefulWidget {
  const VerificationCodeScreen({super.key});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String _code = '';

  // Timer properties
  Timer? _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer to avoid memory leaks
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
          _timer?.cancel();
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _verify() async {
    if (_code.length != 6) {

      return;
    }

    final auth = context.read<AuthService>();
    final success = await auth.verifyOtp(code: _code);

    if (!mounted) return;

    if (success) {
      context.pushNamed('resetPassword');
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  Future<void> _resend() async {
    if (!_canResend) return;

    final identifier = context.read<AuthService>().pendingResetIdentifier;
    if (identifier == null) return;

    final success = await context.read<AuthService>().forgotPassword(
      identifier: identifier,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Code resent successfully'
              : context.read<AuthService>().error ?? 'Failed to resend',
        ),
      ),
    );

    if (success) {
      _startTimer(); // Restart the countdown on successful trigger
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final identifier = auth.pendingResetIdentifier ?? '';
    final masked = identifier.contains('@')
        ? Formatters.maskEmail(identifier)
        : Formatters.maskPhone(identifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                title: 'Verification Code',
                subtitle:
                    'We have sent a code for verification to your email $masked',
                fallbackRoute: '/auth/forgot-password',
              ),
              SizedBox(height: 22.h),
            OtpInput(
              controllers: _controllers,
              focusNodes: _focusNodes,
              onCompleted: (code) => setState(() => _code = code),
            ),
            SizedBox(height: 8.h,),
            Padding(
              padding:   EdgeInsets.symmetric(horizontal: 10.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!_canResend)
                    Text(
                      '${_secondsRemaining.toString().padLeft(2, '0')} seconds',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                      ),
                    ),
                  SizedBox(height: 8.h,),
                  if (_canResend)

                  TextButton(
                    onPressed: (auth.isLoading || !_canResend) ? null : _resend,
                    child: Text(
                      'Resend OTP',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:  AppColors.textPrimary ,
                        fontWeight: FontWeight.w400,
                        fontSize: 14.sp,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.white,
                        //backgroundColor: AppColors.textPrimary
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: 'Verify',
              onTap: _verify,
            ),
            ],
          ),
        ),
      ),
    );
  }
}