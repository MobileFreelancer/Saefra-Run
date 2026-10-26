import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/services/settings_service.dart';
import 'package:saefra_run/core/utils/navigation_utils.dart';

class LegalContentScreen extends StatelessWidget {
  const LegalContentScreen({super.key, required this.type,});

  final String type;

  bool get _isPrivacy => type == 'privacy';

  String get _title => _isPrivacy ? 'Privacy & Policy' : 'Term & Condition';

  String get _rawBody => _isPrivacy ? _privacyText : _termsText;

  static const Color _headingColor = Color(0xFFFFFFFF);
  static const Color _bodyColor = Color(0xFFB4B4B4);
  static const Color _agreeColor = Color(0xFFD62142);

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(_rawBody);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _LegalHeader(
              title: _title,
              onBack: () => safePop(context, fallback: '/settings'),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final block in blocks) _buildBlock(block),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
              child: SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () async {
                    final settings = context.read<SettingsService>();
                    if (_isPrivacy) {
                      await settings.setPrivacyAccepted(true);
                    } else {
                      await settings.setTermsAccepted(true);
                    }
                    if (context.mounted) {
                      safePop(context, fallback: '/settings');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _agreeColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        _agreeColor.withValues(alpha: 0.4),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: const StadiumBorder(),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    'Agree',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlock(_LegalBlock block) {
    final bodyStyle = GoogleFonts.inter(color: _bodyColor, fontSize: 13.sp, fontWeight: FontWeight.w400, height: 1.4,);

    switch (block.type) {
      case _LegalBlockType.heading:
        return Padding(
          padding: EdgeInsets.only(top: 12.h, bottom: 3.h),
          child: Text(
            block.text,
            style: GoogleFonts.inter(
              color: _headingColor,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        );
      case _LegalBlockType.bullet:
        return Padding(
          padding: EdgeInsets.only(bottom: 1.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 14.w,
                child: Text('•', style: bodyStyle),
              ),
              Expanded(
                child: Text(block.text, style: bodyStyle),
              ),
            ],
          ),
        );
      case _LegalBlockType.paragraph:
        return Padding(
          padding: EdgeInsets.only(bottom: 5.h),
          child: Text(block.text, style: bodyStyle),
        );
    }
  }

  List<_LegalBlock> _parseBlocks(String rawText) {
    final blocks = <_LegalBlock>[];

    for (final line in rawText.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (_isHeading(trimmed)) {
        blocks.add(_LegalBlock(_LegalBlockType.heading, trimmed));
      } else if (trimmed.startsWith('•') || trimmed.startsWith('-')) {
        final bulletText = trimmed
            .replaceFirst(RegExp(r'^[•\-]\s*'), '')
            .trim();
        blocks.add(_LegalBlock(_LegalBlockType.bullet, bulletText));
      } else {
        blocks.add(_LegalBlock(_LegalBlockType.paragraph, trimmed));
      }
    }

    return blocks;
  }

  bool _isHeading(String text) {
    if (RegExp(r'^\d+\.\s+').hasMatch(text)) return true;

    const headings = {
      'Privacy Policy for Saefra Run',
      'Information We Collect',
      'Account Information',
      'Location Information',
      'Emergency Contacts',
      'Route Feedback',
      'Device Information',
      'How We Use Your Information',
      'Community Feedback',
      'Emergency Features',
      'How We Share Information',
      'Data Retention',
      'Your Choices',
      'Security',
      "Children's Privacy",
      'Third-Party Services',
      'Changes to this Privacy Policy',
      'Contact Us',
    };
    return headings.contains(text);
  }
}

class _LegalHeader extends StatelessWidget {
  const _LegalHeader({required this.title, required this.onBack,});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

enum _LegalBlockType { heading, paragraph, bullet }

class _LegalBlock {
  const _LegalBlock(this.type, this.text);

  final _LegalBlockType type;
  final String text;
}

// ============================================================
// TERMS OF SERVICE
// ============================================================

const _termsText = '''
Effective Date: July 28, 2026

Welcome to Saefra Run ("Saefra," "we," "our," or "us"). These Terms of Service ("Terms") govern your access to and use of the Saefra mobile application, website, and related services (collectively, the "Services").

By creating an account or using the Services, you agree to these Terms.

1. Eligibility

You must be at least 13 years old (or the minimum age required in your jurisdiction) to use Saefra.

If you are under the age of majority in your jurisdiction, you must have permission from a parent or legal guardian.

2. Your Account

You agree to:

• Provide accurate information
• Keep your login credentials secure
• Notify us of any unauthorized access
• Be responsible for all activity under your account

3. Description of the Services

Saefra provides tools designed to help users:

• Generate running routes
• Track runs
• Save running activity
• Submit community route feedback
• Use optional Safety Check-In features
• Receive personalized running experiences

Saefra is intended for informational and recreational purposes only.

4. Safety Disclaimer

Running involves inherent risks.

By using Saefra, you acknowledge that you are solely responsible for your own safety while running.

You agree to:

• Obey all traffic laws
• Be aware of your surroundings
• Exercise reasonable judgment
• Stop using the app if it distracts you from running safely

Saefra does not guarantee that any route is free from hazards, construction, traffic, weather conditions, crime, or other risks.

Route conditions may change without notice.

5. Safety Check-In & Emergency Features

Safety Check-In is an optional feature.

If enabled, Saefra may attempt to notify your selected emergency contact(s) if:

• You do not complete your configured Safety Check-In, and
• You fail to respond to follow-up prompts.

Emergency notifications are based on your selected settings and available device information.

Saefra cannot verify whether an actual emergency has occurred.

Emergency contacts should not assume an alert confirms an emergency, and the absence of an alert should not be interpreted as confirmation that a user is safe.

Saefra is not an emergency response service and should never be relied upon in place of calling local emergency services.

6. Location Services

Many features require location access.

By enabling location permissions, you authorize Saefra to use your location to:

• Generate routes
• Track your runs
• Provide navigation
• Support Safety Check-In

You may disable location access at any time, but certain features may no longer function.

7. Community Contributions

Users may submit:

• Route feedback
• Surface information
• Sidewalk availability
• Comments
• Other community insights

By submitting content, you grant Saefra a worldwide, non-exclusive, royalty-free license to use, display, analyze, modify, and distribute that content to improve the Services.

You remain the owner of your original submissions.

8. User Conduct

You agree not to:

• Use the app unlawfully
• Interfere with the Services
• Upload false or misleading information
• Harass other users
• Attempt to access another user's account
• Reverse engineer or copy the Services without permission

9. Intellectual Property

The Services, including:

• App design
• Logos
• Graphics
• Text
• Software
• Trademarks

are owned by Saefra Run or its licensors and are protected by applicable intellectual property laws.

You may not reproduce or distribute any part of the Services without written permission.

10. Third-Party Services

Saefra may integrate with third-party providers, including mapping, authentication, analytics, cloud hosting, and notification services.

Your use of those services may also be subject to their respective terms and privacy policies.

11. Disclaimer of Warranties

The Services are provided "as is" and "as available."

To the fullest extent permitted by law, Saefra disclaims all warranties, express or implied, including warranties of:

• Merchantability
• Fitness for a particular purpose
• Non-infringement
• Accuracy
• Reliability
• Availability

We do not guarantee uninterrupted or error-free operation.

12. Limitation of Liability

To the fullest extent permitted by law, Saefra Run, its officers, employees, contractors, and affiliates shall not be liable for any indirect, incidental, consequential, special, or punitive damages arising from your use of the Services.

This includes, but is not limited to:

• Personal injury
• Property damage
• Lost data
• Lost profits
• Missed Safety Check-In notifications
• Delayed notifications
• Route inaccuracies
• GPS inaccuracies
• Community-submitted information
• Third-party service outages

Your use of the Services is at your own risk.

13. Indemnification

You agree to defend, indemnify, and hold harmless Saefra Run and its affiliates from claims, liabilities, damages, losses, and expenses arising out of your use of the Services or your violation of these Terms.

14. Termination

We may suspend or terminate your account if you violate these Terms or misuse the Services.

You may stop using the Services and delete your account at any time.

15. Changes to the Services

We may modify, suspend, or discontinue any feature of the Services at any time without prior notice.

16. Changes to These Terms

We may update these Terms periodically.

The updated version will become effective when posted.

Continued use of the Services after changes are posted constitutes acceptance of the revised Terms.

17. Governing Law

These Terms shall be governed by the laws of the Commonwealth of Massachusetts, without regard to its conflict of law principles.

Any disputes arising from these Terms shall be resolved in the state or federal courts located in Massachusetts, unless otherwise required by applicable law.

18. Contact Us

If you have questions regarding these Terms, please contact us:

Saefra Run

Email: info@saefrarun.com
''';

// ============================================================
// PRIVACY POLICY
// ============================================================

const _privacyText = '''
Effective Date: July 27, 2026

Privacy Policy for Saefra Run

At Saefra Run ("Saefra," "we," "our," or "us"), your privacy is important to us. This Privacy Policy explains what information we collect, how we use it, and the choices you have regarding your information when using the Saefra mobile application.

By using Saefra, you agree to the collection and use of information in accordance with this Privacy Policy.

Information We Collect

Account Information

When you create an account, we may collect:

• First name
• Last name (if provided)
• Email address
• Date of birth
• Gender (optional)

We use this information to personalize your experience and manage your account.

Location Information

Saefra uses your device's location to:

• Generate running routes
• Track your run while it is active
• Navigate your selected route
• Support optional safety features such as Safety Check-In

Your location is only accessed while you have granted permission through your device settings.

Emergency Contacts

If you choose to use Safety Check-In, you may select one or more emergency contacts.

We only use the contact information you choose to provide for the purpose of Safety Check-In and emergency notifications that you enable.

We do not use your contacts for marketing purposes.

Route Feedback

After completing a run, you may choose to provide feedback such as:

• Route surface
• Sidewalk availability
• Whether the route felt open or secluded
• Optional comments

This information helps improve route recommendations and community insights for all users.

Device Information

We may automatically collect information such as:

• Device model
• Operating system
• App version
• Crash reports
• Diagnostic information

This information helps us improve app performance and reliability.

How We Use Your Information

We use your information to:

• Create and manage your account
• Generate personalized running routes
• Improve route recommendations
• Provide navigation during your run
• Enable Safety Check-In
• Notify emergency contacts when you have enabled safety features
• Improve app functionality
• Respond to customer support requests
• Analyze usage to improve the app

Community Feedback

Information submitted through post-run feedback may be aggregated and used to improve route quality for the Saefra community.

Individual feedback is never displayed with your personal information without your permission.

Emergency Features

Safety Check-In is an optional feature.

If enabled, Saefra may notify your selected emergency contact(s) if:

• You fail to complete a scheduled Safety Check-In, and
• You do not respond to multiple prompts within the configured time period.

Saefra cannot guarantee detection of emergencies and should not be relied upon as an emergency response service.

If you require immediate assistance, contact your local emergency services.

How We Share Information

We do not sell your personal information.

We may share information:

• With service providers that help us operate the app
• When required by law
• To protect the safety and rights of users
• With emergency contacts only when you have enabled Safety Check-In

Data Retention

We retain your information only as long as necessary to:

• Provide the Services
• Meet legal obligations
• Resolve disputes
• Improve our products

You may request deletion of your account at any time.

Your Choices

You may:

• Update your profile information
• Change or remove emergency contacts
• Disable location permissions
• Disable Safety Check-In
• Delete your account
• Request deletion of your personal information

Certain features may not function without location permissions.

Security

We use reasonable administrative, technical, and physical safeguards to protect your information.

However, no system can guarantee complete security.

Children's Privacy

Saefra is not intended for children under 13 years of age.

We do not knowingly collect personal information from children under 13.

If we become aware that such information has been collected, we will delete it promptly.

Third-Party Services

Saefra may use third-party services including, but not limited to:

• Google Maps Platform
• Google Routes API
• Authentication providers
• Cloud hosting providers
• Analytics providers
• Push notification services

These providers may collect information in accordance with their own privacy policies.

Changes to this Privacy Policy

We may update this Privacy Policy from time to time.

When changes are made, we will update the Effective Date above.

Continued use of Saefra after changes become effective constitutes acceptance of the updated Privacy Policy.

Contact Us

If you have questions about this Privacy Policy, please contact us at:

Saefra Run

Email: info@saefrarun.com
''';
