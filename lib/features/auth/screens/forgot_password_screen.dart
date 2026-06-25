import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/services/auth_service.dart';
import 'package:saefra_run/core/widgets/app_text_field.dart';
import 'package:saefra_run/core/widgets/auth_scaffold.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final success = await auth.forgotPassword(
      identifier: _identifierController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      context.pushNamed('verification');
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return AuthScaffold(
      title: 'Forgot Password?',
      subtitle:
          'Enter your email or phone number and we will send you a verification code.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _identifierController,
              hint: 'Enter email or phone',
              prefixIcon: Icon(Icons.person_outline),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email or phone';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Send',
              onPressed: _send,
              isLoading: auth.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
