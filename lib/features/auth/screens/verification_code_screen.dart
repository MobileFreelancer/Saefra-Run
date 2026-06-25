import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/config/api_config.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/utils/formatters.dart';
import 'package:saefra_run/core/widgets/auth_scaffold.dart';
import 'package:saefra_run/core/widgets/otp_input.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';

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

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit code')),
      );
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
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final identifier = auth.pendingResetIdentifier ?? '';
    final masked = identifier.contains('@')
        ? Formatters.maskEmail(identifier)
        : Formatters.maskPhone(identifier);

    return AuthScaffold(
      title: 'Verification Code',
      subtitle: 'We sent a 6-digit code to $masked. '
          'Enter it below to continue.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OtpInput(
            controllers: _controllers,
            focusNodes: _focusNodes,
            onCompleted: (code) => setState(() => _code = code),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: auth.isLoading ? null : _resend,
              child: Text(
                'Resend Code',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Verify',
            onPressed: _verify,
            isLoading: auth.isLoading,
          ),
          if (ApiConfig.useMockApi) ...[
            const SizedBox(height: 12),
            Text(
              'Mock OTP: 123456',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
