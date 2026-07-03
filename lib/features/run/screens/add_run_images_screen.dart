import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/run_review_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';

class AddRunImagesScreen extends StatelessWidget {
  const AddRunImagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final review = context.watch<RunReviewService>();
    final images = review.form.imagePaths;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Add Images'),
            Expanded(
              child: images.isEmpty
                  ? Center(
                      child: Text(
                        'No images yet. Tap + to add placeholders.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final path = images[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 10.h),
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.image, color: AppColors.primary),
                              SizedBox(width: 10.w),
                              Expanded(child: Text(path)),
                              IconButton(
                                onPressed: () => review.removeImage(path),
                                icon: const Icon(Icons.close, color: AppColors.primary),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: ElevatedButton(
                onPressed: () {
                  review.addImage('assets/images/background.png');
                },
                child: const Text('Add placeholder image'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
