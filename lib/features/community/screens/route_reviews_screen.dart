import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/services/community_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';

class RouteReviewsScreen extends StatefulWidget {
  const RouteReviewsScreen({super.key, required this.routeId});

  final String routeId;

  @override
  State<RouteReviewsScreen> createState() => _RouteReviewsScreenState();
}

class _RouteReviewsScreenState extends State<RouteReviewsScreen> {
  final _comment = TextEditingController();
  double _rating = 5;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityService>().loadRouteDetail(widget.routeId);
    });
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityService>();
    final route = community.selectedRoute;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Reviews'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  if (route != null) ...[
                    Text(route.name, style: Theme.of(context).textTheme.titleMedium),
                    Text(route.location, style: Theme.of(context).textTheme.bodySmall),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Text(
                          route.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 36.sp),
                        ),
                        SizedBox(width: 12.w),
                        const Icon(Icons.star, color: Colors.amber),
                      ],
                    ),
                    SizedBox(height: 16.h),
                  ],
                  ...community.reviews.map(
                    (review) => Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16.r,
                                child: Text(review.userName[0]),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(review.userName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13.sp)),
                              ),
                              Text(review.timeAgo ?? '', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < review.rating.round() ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 14,
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(review.comment, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text('Add Your Review', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 8.h),
                  Row(
                    children: List.generate(
                      5,
                      (i) => IconButton(
                        onPressed: () => setState(() => _rating = i + 1.0),
                        icon: Icon(
                          i < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ),
                  TextField(
                    controller: _comment,
                    maxLines: 4,
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(hintText: 'Write your review...'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: PrimaryButton(
                label: _isSubmitting ? 'Submitting...' : 'Submit Review',
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        setState(() => _isSubmitting = true);
                        final ok = await context
                            .read<CommunityService>()
                            .submitReview(
                              routeId: widget.routeId,
                              rating: _rating,
                              comment: _comment.text.trim(),
                            );
                        if (!mounted) return;
                        setState(() => _isSubmitting = false);
                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                community.error ?? 'Failed to submit review.',
                              ),
                            ),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Review submitted.')),
                        );
                        context.pop();
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
