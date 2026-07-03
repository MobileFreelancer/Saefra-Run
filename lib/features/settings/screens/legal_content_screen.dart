import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
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
                label: type == 'privacy' ? 'Close' : 'Accept',
                onPressed: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _termsText = '''
These Terms and Conditions govern your use of Saefra Run. By using the app, you agree to follow applicable laws, use accurate profile information, and respect community safety guidelines.

Saefra Run provides route recommendations and safety insights for informational purposes only. Always assess local conditions before running.

We may update these terms from time to time. Continued use of the app after updates constitutes acceptance of the revised terms.
''';

const _privacyText = '''
Saefra Run respects your privacy. We collect account, location, and activity data to personalize routes and improve safety features.

Your data is processed according to our security standards and is not sold to third parties. You can manage notification and sharing preferences in Settings.

Contact support if you have questions about data retention or deletion requests.
''';
