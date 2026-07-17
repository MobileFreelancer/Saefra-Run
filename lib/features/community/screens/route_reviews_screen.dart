import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/mock/feature_mock_data.dart';
import 'package:saefra_run/core/models/review_model.dart';
import 'package:saefra_run/core/services/community_service.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/asset_or_fallback.dart';
import 'package:saefra_run/core/widgets/primary_button.dart';
import 'package:saefra_run/generated/assets.dart';

class RouteReviewsScreen extends StatefulWidget {
  const RouteReviewsScreen({super.key, required this.routeId});

  final String routeId;

  @override
  State<RouteReviewsScreen> createState() => _RouteReviewsScreenState();
}

class _RouteReviewsScreenState extends State<RouteReviewsScreen> {
  final _comment = TextEditingController();
  double _rating = 0;
  bool _isSubmitting = false;
  int _selectedTab = 0;

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

  TextStyle _body(BuildContext context, {Color? color, FontWeight? weight}) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: color ?? AppColors.white,
          fontWeight: weight,
        );
  }

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityService>();
    final route = community.selectedRoute;
    final bodyStyle = _body(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Reviews'),
            if (route != null) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    Text(
                      route.name,
                      style: bodyStyle.copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14.sp,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          route.location,
                          style: bodyStyle.copyWith(color: AppColors.textMuted),
                        ),
                        SizedBox(width: 12.w),
                        Icon(Icons.star, color: Colors.amber, size: 14.sp),
                        SizedBox(width: 4.w),
                        Text(
                          '${route.rating.toStringAsFixed(1)} (${route.reviewCount} Reviews)',
                          style: bodyStyle.copyWith(color: Colors.amber),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],
            Expanded(
              child: community.isLoading && community.reviews.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : ListView(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      children: [
                        if (route != null) ...[
                          _RatingSummaryCard(
                            routeName: route.name,
                            location: route.location,
                            distanceKm: route.distanceKm,
                            rating: route.rating,
                            imageAsset: route.imageAsset,
                            distribution: FeatureMockData.ratingDistribution,
                            bodyStyle: bodyStyle,
                          ),
                          SizedBox(height: 20.h),
                        ],
                        _ReviewTabs(
                          selectedIndex: _selectedTab,
                          bodyStyle: bodyStyle,
                          onChanged: (index) =>
                              setState(() => _selectedTab = index),
                        ),
                        SizedBox(height: 16.h),
                        if (_selectedTab == 0)
                          ...community.reviews.map(
                            (review) => Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: _ReviewTile(
                                review: review,
                                bodyStyle: bodyStyle,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.h),
                            child: Center(
                              child: Text(
                                'No photos yet',
                                style: bodyStyle.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: 16.h),
                        _AddReviewCard(
                          rating: _rating,
                          commentController: _comment,
                          bodyStyle: bodyStyle,
                          onRatingChanged: (value) =>
                              setState(() => _rating = value),
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: PrimaryButton(
                label: _isSubmitting ? 'Submitting...' : 'Submit Review',
                onPressed: _isSubmitting || _rating <= 0
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

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard({
    required this.routeName,
    required this.location,
    required this.distanceKm,
    required this.rating,
    required this.imageAsset,
    required this.distribution,
    required this.bodyStyle,
  });

  final String routeName;
  final String location;
  final double distanceKm;
  final double rating;
  final String? imageAsset;
  final Map<int, double> distribution;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surfaced1B,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: SizedBox(
                  width: 64.w,
                  height: 64.w,
                  child: AssetOrFallback(
                    assetPath: imageAsset ?? Assets.background,
                    fallback: Container(
                      color: AppColors.surfaced2C,
                      child: const Icon(Icons.route, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeName,
                      style: bodyStyle.copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      location,
                      style: bodyStyle.copyWith(color: AppColors.textMuted),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${distanceKm.toStringAsFixed(2)} km',
                      style: bodyStyle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text(
                    rating.toStringAsFixed(1),
                    style: bodyStyle.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 32.sp,
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < rating.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 16.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final fraction = distribution[star] ?? 0;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: bodyStyle.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11.sp,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.r),
                              child: LinearProgressIndicator(
                                value: fraction,
                                minHeight: 6.h,
                                backgroundColor: AppColors.surfaced,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewTabs extends StatelessWidget {
  const _ReviewTabs({
    required this.selectedIndex,
    required this.bodyStyle,
    required this.onChanged,
  });

  final int selectedIndex;
  final TextStyle bodyStyle;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabItem(
          label: 'All Reviews',
          isSelected: selectedIndex == 0,
          bodyStyle: bodyStyle,
          onTap: () => onChanged(0),
        ),
        SizedBox(width: 24.w),
        _TabItem(
          label: 'Photos',
          isSelected: selectedIndex == 1,
          bodyStyle: bodyStyle,
          onTap: () => onChanged(1),
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.bodyStyle,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final TextStyle bodyStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: bodyStyle.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            height: 3.h,
            width: label.length * 8.w,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.bodyStyle});

  final ReviewModel review;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surfaced1B,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: AppColors.surfaced,
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0] : '?',
                  style: bodyStyle.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  review.userName,
                  style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < review.rating.round() ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 14.sp,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(review.comment, style: bodyStyle),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                review.timeAgo ?? '',
                style: bodyStyle.copyWith(color: AppColors.textMuted),
              ),
              const Spacer(),
              Icon(Icons.favorite_border, size: 14.sp, color: AppColors.textMuted),
              SizedBox(width: 4.w),
              Text(
                '${review.likeCount}',
                style: bodyStyle.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddReviewCard extends StatelessWidget {
  const _AddReviewCard({
    required this.rating,
    required this.commentController,
    required this.bodyStyle,
    required this.onRatingChanged,
  });

  final double rating;
  final TextEditingController commentController;
  final TextStyle bodyStyle;
  final ValueChanged<double> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surfaced1B,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Your Review',
            style: bodyStyle.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12.h),
          Row(
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => onRatingChanged(i + 1.0),
                child: Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 28.sp,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: commentController,
            maxLines: 4,
            style: bodyStyle,
            decoration: InputDecoration(
              hintText: 'Write your experience about this route...',
              hintStyle: bodyStyle.copyWith(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaced,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(12.w),
            ),
          ),
        ],
      ),
    );
  }
}
