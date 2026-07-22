import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saefra_run/core/constants/app_colors.dart';
import 'package:saefra_run/core/mock/feature_mock_data.dart';
import 'package:saefra_run/core/models/review_model.dart';
import 'package:saefra_run/core/services/community_service.dart';
import 'package:saefra_run/core/utils/navigation_utils.dart';
import 'package:saefra_run/core/widgets/app_page_header.dart';
import 'package:saefra_run/core/widgets/asset_or_fallback.dart';
import 'package:saefra_run/generated/assets.dart';

class RouteReviewsScreen extends StatefulWidget {
  const RouteReviewsScreen({super.key, required this.routeId});

  final String routeId;

  @override
  State<RouteReviewsScreen> createState() => _RouteReviewsScreenState();
}

class _RouteReviewsScreenState extends State<RouteReviewsScreen> {
  static const _maxCommentLength = 500;
  static const _starOrange = Color(0xFFFF9800);

  final _comment = TextEditingController();
  final Set<String> _likedReviewIds = {};

  double _rating = 0;
  bool _isSubmitting = false;
  int _selectedTab = 0;
  int _commentLength = 0;

  @override
  void initState() {
    super.initState();
    _comment.addListener(() {
      setState(() => _commentLength = _comment.text.length);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityService>().loadRouteDetail(widget.routeId);
    });
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  TextStyle _body(BuildContext context, {Color? color, FontWeight? weight, double? size}) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: color ?? AppColors.white,
          fontWeight: weight,
          fontSize: size,
        );
  }

  Future<void> _submitReview() async {
    if (_isSubmitting || _rating <= 0) return;

    setState(() => _isSubmitting = true);
    final community = context.read<CommunityService>();
    final ok = await community.submitReview(
      routeId: widget.routeId,
      rating: _rating,
      comment: _comment.text.trim(),
    );
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(community.error ?? 'Failed to submit review.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted.')),
    );
    safePop(context, fallback: '/community');
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppPageHeader(title: 'Reviews'),
            if (route != null) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
                child: Text(
                  route.name,
                  style: bodyStyle.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 22.sp,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16.sp, color: AppColors.textMuted),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        route.location,
                        style: bodyStyle.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 13.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: Text('|', style: bodyStyle.copyWith(color: AppColors.textMuted)),
                    ),
                    Icon(Icons.star_rounded, color: _starOrange, size: 16.sp),
                    SizedBox(width: 4.w),
                    Text(
                      '${route.rating.toStringAsFixed(1)} (${route.reviewCount} Reviews)',
                      style: bodyStyle.copyWith(
                        color: _starOrange,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
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
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                      children: [
                        if (route != null) ...[
                          _RatingSummaryCard(
                            routeName: route.name,
                            location: route.location,
                            distanceKm: route.distanceKm,
                            rating: route.rating,
                            reviewCount: route.reviewCount,
                            imageAsset: route.imageAsset,
                            distribution: FeatureMockData.ratingDistribution,
                            bodyStyle: bodyStyle,
                            starOrange: _starOrange,
                          ),
                          SizedBox(height: 20.h),
                        ],
                        _ReviewTabs(
                          selectedIndex: _selectedTab,
                          bodyStyle: bodyStyle,
                          onChanged: (index) => setState(() => _selectedTab = index),
                        ),
                        SizedBox(height: 20.h),
                        if (_selectedTab == 0)
                          ...community.reviews.map(
                            (review) => Padding(
                              padding: EdgeInsets.only(bottom: 20.h),
                              child: _ReviewTile(
                                review: review,
                                bodyStyle: bodyStyle,
                                starOrange: _starOrange,
                                isLiked: _likedReviewIds.contains(review.id),
                                onLikeToggle: () {
                                  setState(() {
                                    if (_likedReviewIds.contains(review.id)) {
                                      _likedReviewIds.remove(review.id);
                                    } else {
                                      _likedReviewIds.add(review.id);
                                    }
                                  });
                                },
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 48.h),
                            child: Center(
                              child: Text(
                                'No photos yet',
                                style: bodyStyle.copyWith(color: AppColors.textMuted),
                              ),
                            ),
                          ),
                        SizedBox(height: 8.h),
                        _AddReviewSection(
                          rating: _rating,
                          commentController: _comment,
                          commentLength: _commentLength,
                          maxLength: _maxCommentLength,
                          isSubmitting: _isSubmitting,
                          bodyStyle: bodyStyle,
                          starOrange: _starOrange,
                          onRatingChanged: (value) => setState(() => _rating = value),
                          onSubmit: _submitReview,
                        ),
                      ],
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
    required this.reviewCount,
    required this.imageAsset,
    required this.distribution,
    required this.bodyStyle,
    required this.starOrange,
  });

  final String routeName;
  final String location;
  final double distanceKm;
  final double rating;
  final int reviewCount;
  final String? imageAsset;
  final Map<int, double> distribution;
  final TextStyle bodyStyle;
  final Color starOrange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaced1B,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: SizedBox(
                  width: 72.w,
                  height: 72.w,
                  child: AssetOrFallback(
                    assetPath: imageAsset ?? Assets.background,
                    fallback: Container(
                      color: AppColors.surfaced2C,
                      child: Icon(Icons.route, color: AppColors.primary, size: 28.sp),
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
                      style: bodyStyle.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      location,
                      style: bodyStyle.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '${distanceKm.toStringAsFixed(2)} km',
                      style: bodyStyle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rating.toStringAsFixed(1),
                    style: bodyStyle.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 36.sp,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                        color: starOrange,
                        size: 18.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '($reviewCount Reviews)',
                    style: bodyStyle.copyWith(
                      color: starOrange,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final fraction = distribution[star] ?? 0;
                    final percent = (fraction * 100).round();
                    return Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 12.w,
                            child: Text(
                              '$star',
                              style: bodyStyle.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3.r),
                              child: LinearProgressIndicator(
                                value: fraction,
                                minHeight: 7.h,
                                backgroundColor: AppColors.surfaced2C,
                                color: starOrange,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          SizedBox(
                            width: 32.w,
                            child: Text(
                              '$percent%',
                              textAlign: TextAlign.right,
                              style: bodyStyle.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11.sp,
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
        SizedBox(width: 28.w),
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
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: bodyStyle.copyWith(
              color: isSelected ? AppColors.primary : AppColors.white,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              fontSize: 15.sp,
            ),
          ),
          SizedBox(height: 8.h),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3.h,
            width: label == 'All Reviews' ? 88.w : 52.w,
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
  const _ReviewTile({
    required this.review,
    required this.bodyStyle,
    required this.starOrange,
    required this.isLiked,
    required this.onLikeToggle,
  });

  final ReviewModel review;
  final TextStyle bodyStyle;
  final Color starOrange;
  final bool isLiked;
  final VoidCallback onLikeToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22.r,
          backgroundColor: AppColors.surfaced2C,
          backgroundImage:
              review.avatarUrl != null ? NetworkImage(review.avatarUrl!) : null,
          child: review.avatarUrl == null
              ? Text(
                  review.userName.isNotEmpty ? review.userName[0] : '?',
                  style: bodyStyle.copyWith(fontWeight: FontWeight.w700),
                )
              : null,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      review.userName,
                      style: bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  if (review.timeAgo != null && review.timeAgo!.isNotEmpty) ...[
                    Text(
                      review.timeAgo!,
                      style: bodyStyle.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                  ],
                  GestureDetector(
                    onTap: onLikeToggle,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 16.sp,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${review.likeCount}',
                          style: bodyStyle.copyWith(
                            color: AppColors.primary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: starOrange,
                    size: 16.sp,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                review.comment,
                style: bodyStyle.copyWith(
                  color: AppColors.textThird,
                  fontSize: 13.sp,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddReviewSection extends StatelessWidget {
  const _AddReviewSection({
    required this.rating,
    required this.commentController,
    required this.commentLength,
    required this.maxLength,
    required this.isSubmitting,
    required this.bodyStyle,
    required this.starOrange,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  final double rating;
  final TextEditingController commentController;
  final int commentLength;
  final int maxLength;
  final bool isSubmitting;
  final TextStyle bodyStyle;
  final Color starOrange;
  final ValueChanged<double> onRatingChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaced1B,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add Your Review',
            style: bodyStyle.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => onRatingChanged(i + 1.0),
                child: Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child: Icon(
                    i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: starOrange,
                    size: 32.sp,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              TextField(
                controller: commentController,
                maxLines: 5,
                maxLength: maxLength,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    null,
                style: bodyStyle.copyWith(fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'Share your experience about this route...',
                  hintStyle: bodyStyle.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 14.sp,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1),
                  ),
                  contentPadding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 32.h),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 12.w, bottom: 10.h),
                child: Text(
                  '$commentLength/$maxLength',
                  style: bodyStyle.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting || rating <= 0 ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                ),
              ),
              child: isSubmitting
                  ? SizedBox(
                      height: 22.h,
                      width: 22.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      'Submit Review',
                      style: bodyStyle.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
