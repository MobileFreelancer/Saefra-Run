import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/utils/navigation_utils.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/generated/assets.dart';
import 'package:share_plus/share_plus.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {



  @override
  void initState() {
    getAppVersion();
    super.initState();
  }

  String _getAppVersion="";
  String _getAppID="";

  Future<void> getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    print("App Name: ${packageInfo.appName}");
    print("Package Name: ${packageInfo.packageName}");
    print("Version: ${packageInfo.version}");
    print("Build Number: ${packageInfo.buildNumber}");
    _getAppVersion = packageInfo.version;
    _getAppID=packageInfo.packageName;
    setState(() {});
  }
  final InAppReview inAppReview = InAppReview.instance;

  Future<void> requestReview() async {
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      await inAppReview.openStoreListing(
        appStoreId: _getAppID, // Required for iOS
      );
    }
  }


  Future<void> shareApp() async {
    const String appName = "Your App Name";
    final String playStoreUrl =
        "https://play.google.com/store/apps/details?id=$_getAppID";

    final String appStoreUrl =
        "https://apps.apple.com/app/$_getAppID";

    await SharePlus.instance.share(
      ShareParams(
        text: '''
Check out $appName!

📱 Android:
$playStoreUrl

🍎 iPhone:
$appStoreUrl
''',
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'About Us'),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    Image.asset(
                      Assets.aboutlogo,
                      height: 72.h,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.directions_run,
                        size: 72.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Saefra Run',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700
                      ),
                    ),
                    SizedBox(height: 10.h,),
                    Text(
                      _getAppVersion,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 10.h,),
                    Text(
                      'Run Safe. Run Smart.',
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Saefra Run helps you discover safe running routes, track activity, and stay connected with your community.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFE1E1E1),
                        fontSize: 14.sp,
                        height: 1.5,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: AppColors.surfaced1B,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [ BoxShadow( color: AppColors.orangeShadow.withValues(alpha: 0.15), blurRadius: 20 ) ],
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Version", style: TextStyle(color: AppColors.white, fontSize: 14.sp,fontWeight: FontWeight.w500),),
                              Text(_getAppVersion, style: TextStyle(color: AppColors.white, fontSize: 14.sp,fontWeight: FontWeight.w500),),
                            ],
                          ),
                          SizedBox(height: 12.h,),
                          Divider(
                            height: 0.5,
                            thickness: 1.2,
                            color: AppColors.border,
                            indent: 16.w,
                            endIndent: 16.w,
                          ),
                          SizedBox(height: 12.h,),
                          InkWell(
                            onTap: (){
                              requestReview();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Rate App", style: TextStyle(color: AppColors.white, fontSize: 14.sp,fontWeight: FontWeight.w500),),
                                Icon(Icons.arrow_forward_ios, color: AppColors.white, size: 14.sp,),
                              ],
                            ),
                          ),
                          SizedBox(height: 12.h,),
                          Divider(
                            height: 0.5,
                            thickness: 1.2,
                            color: AppColors.border,
                            indent: 16.w,
                            endIndent: 16.w,
                          ),
                          SizedBox(height: 12.h,),
                          InkWell(
                            onTap: (){
                              shareApp();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Share App", style: TextStyle(color: AppColors.white, fontSize: 14.sp,fontWeight: FontWeight.w500),),
                                Icon(Icons.arrow_forward_ios, color: AppColors.white, size: 14.sp,),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
