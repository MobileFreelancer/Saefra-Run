import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/settings_service.dart';
import 'package:saefra_run/core/utils/navigation_utils.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';

class LegalContentScreen extends StatelessWidget {
  const LegalContentScreen({super.key, required this.type});

  final String type;

  String get _title =>
      type == 'privacy' ? 'Privacy Policy' : 'Terms and Conditions';

  String get _body => type == 'privacy'
      ? _privacyText
      : _termsText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(title: _title),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  _body,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.sp,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: PrimaryButton(
                label:"Agree",
                onPressed: () async {
                  final settings = context.read<SettingsService>();
                  if (type == 'terms') {
                    await settings.setTermsAccepted(true);
                  } else if (type == 'privacy') {
                    await settings.setPrivacyAccepted(true);
                  }
                  if (context.mounted) {
                    safePop(context, fallback: '/settings');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _privacyText = '''
Privacy Policy

Effective Date: July 27, 2026

Saefra Run values your privacy and is committed to protecting your personal information. This Privacy Policy explains what information we collect, how we use it, and the choices you have regarding your data.

Information We Collect

• Account Information
  - First Name
  - Last Name (optional)
  - Email Address
  - Date of Birth
  - Gender (optional)

• Location Information
  - Device location
  - Running routes
  - Navigation data
  - Safety Check-In location

• Emergency Contacts
  - Contact information you choose to share for Safety Check-In features.

• Running Activity
  - Route ratings
  - Running surface
  - Sidewalk availability
  - Safety feedback
  - Community insights

• Device Information
  - Operating system
  - App version
  - Crash reports
  - Diagnostic information

How We Use Your Information

• Create and manage your account.
• Personalise your running experience.
• Generate running routes.
• Improve app performance and safety features.
• Respond to customer support requests.

Safety Check-In

If enabled, Safety Check-In allows you to notify selected emergency contacts while running. If your expected run time expires and you do not check in, your emergency contacts may receive your last known location.

Data Sharing

We do not sell your personal information.

Information is shared only:
• With service providers that help operate the app.
• When required by law.
• With emergency contacts you explicitly select.

Third-Party Services

Saefra Run uses trusted third-party providers including:
• Google Maps Platform APIs
• Authentication services
• Cloud hosting
• Analytics
• Push notifications

Data Security

We take reasonable measures to protect your information, but no system can guarantee complete security.

Children's Privacy

Saefra Run is not intended for children under 13 years of age.

Changes to this Policy

We may update this Privacy Policy from time to time. Continued use of the app after changes become effective constitutes acceptance of the updated policy.
''';

const _termsText = '''
Terms & Conditions

Effective Date: July 28, 2026

Welcome to Saefra Run. These Terms govern your use of the application and related services.

Eligibility

You must be at least 13 years old (or the minimum legal age in your jurisdiction). If you are under the required age, you must have permission from a parent or legal guardian.

Your Account

You agree to:
• Provide accurate information.
• Keep your login credentials secure.
• Notify us of any unauthorised access.
• Accept responsibility for activity on your account.

Services

Saefra Run provides:
• Route generation
• Running activity tracking
• Community route feedback
• Safety Check-In
• Personalised running recommendations

Safety Disclaimer

Running involves inherent risks.

You are responsible for:
• Following local traffic laws.
• Remaining aware of your surroundings.
• Exercising good judgement while running.
• Stopping use of the app whenever it becomes unsafe or distracting.

Saefra Run provides guidance only and does not guarantee your safety.

Emergency Features

Safety Check-In attempts to notify your selected emergency contacts when appropriate. These features depend on device connectivity and cannot guarantee emergency detection or assistance.

Community Contributions

By submitting ratings, reviews or route feedback, you grant Saefra Run permission to use that content to improve the service.

User Conduct

You agree not to:
• Violate any laws.
• Submit false or misleading information.
• Harass other users.
• Reverse engineer or misuse the application.

Intellectual Property

All app content, branding and software remain the property of Saefra Run unless otherwise stated.

Third-Party Services

The app relies on third-party services including mapping, analytics and cloud hosting providers.

Disclaimer

The application is provided "as is" without warranties of any kind.

Limitation of Liability

To the maximum extent permitted by law, Saefra Run is not liable for damages resulting from your use of the application.

Termination

We may suspend or terminate accounts that violate these Terms.

Changes to the Terms

We may update these Terms from time to time. Continued use of the app constitutes acceptance of the revised Terms.

Governing Law

These Terms are governed by the laws of the Commonwealth of Massachusetts.
''';
