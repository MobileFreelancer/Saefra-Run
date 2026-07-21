import 'package:saefra_run/core/models/activity_model.dart';
import 'package:saefra_run/core/models/community_route_model.dart';
import 'package:saefra_run/core/models/review_model.dart';
import 'package:saefra_run/generated/assets.dart';

/// Temporary mock data for Activity, Community, and Reviews screens.
class FeatureMockData {
  FeatureMockData._();

  static const recentRuns = [
    RecentActivityModel(
      id: '1',
      name: 'Sunset Loop',
      dateLabel: 'Yesterday, 6:30 PM',
      distanceKm: 5.02,
      durationMinutes: 40,
      difficulty: 'Easy',
      location: 'Central Park, NY',
      safetyScore: 92,
      mapImageAsset: Assets.homeRouteThumbnailImg,
    ),
    RecentActivityModel(
      id: '2',
      name: 'Morning Coastal',
      dateLabel: 'Yesterday, 6:30 PM',
      distanceKm: 5.02,
      durationMinutes: 40,
      difficulty: 'Easy',
      location: 'Central Park, NY',
      safetyScore: 92,
      mapImageAsset: Assets.homeRoutePreviewImg,
    ),
    RecentActivityModel(
      id: '3',
      name: 'Sunset Loop',
      dateLabel: 'Yesterday, 6:30 PM',
      distanceKm: 5.02,
      durationMinutes: 40,
      difficulty: 'Easy',
      location: 'Central Park, NY',
      safetyScore: 92,
      mapImageAsset: Assets.generateRouteMapPreview,
    ),
  ];

  static const lifetime = LifetimeStatsModel(
    totalDistanceKm: 1248.5,
    totalHours: 114,
    totalMinutesRemainder: 22,
    totalSteps: 84200,
    avgPaceMinPerKm: 5.57,
    paceTrend: [0.35, 0.55, 0.45, 0.7, 0.5, 0.65, 0.4],
  );

  static const popularRoutes = [
    CommunityRouteModel(
      id: 'p1',
      name: 'Sunset Loop',
      location: 'Central Park, NY',
      distanceKm: 5.02,
      rating: 4.8,
      reviewCount: 128,
      likeCount: 25,
      commentCount: 5,
      difficultyTag: 'Easy',
      imageAsset: Assets.homeRouteThumbnailImg,
    ),
    CommunityRouteModel(
      id: 'p2',
      name: 'Riverside Path',
      location: 'Central Park, NY',
      distanceKm: 5.02,
      rating: 4.8,
      reviewCount: 75,
      likeCount: 28,
      commentCount: 8,
      difficultyTag: 'Easy',
      imageAsset: Assets.homeRoutePreviewImg,
    ),
  ];

  static const recentRoutes = [
    CommunityRouteModel(
      id: 'r1',
      name: 'Lake track',
      location: 'Central Park, NY',
      distanceKm: 5.02,
      rating: 4.8,
      reviewCount: 75,
      likeCount: 28,
      commentCount: 8,
      difficultyTag: 'Hard',
      imageAsset: Assets.generateRouteMapPreview,
    ),
  ];

  static const reviewRoute = CommunityRouteModel(
    id: 'p1',
    name: 'Sunset Loop',
    location: 'Central Park, NY',
    distanceKm: 5.02,
    rating: 4.8,
    reviewCount: 128,
    difficultyTag: 'Easy',
    imageAsset: Assets.homeRouteThumbnailImg,
  );

  static const ratingDistribution = <int, double>{
    5: 0.71,
    4: 0.16,
    3: 0.11,
    2: 0.02,
    1: 0.0,
  };

  static const reviews = [
    ReviewModel(
      id: '1',
      userName: 'Priya S.',
      rating: 5,
      comment: 'Amazing route! Very safe and scenic.',
      timeAgo: '2d ago',
      likeCount: 12,
    ),
    ReviewModel(
      id: '2',
      userName: 'Arjun Verma',
      rating: 5,
      comment: 'Loved the route. Well-lit and clean.',
      timeAgo: '1w ago',
      likeCount: 8,
    ),
    ReviewModel(
      id: '3',
      userName: 'Neha Kapoor',
      rating: 4,
      comment: 'Perfect for evening runs!',
      timeAgo: '2w ago',
      likeCount: 6,
    ),
  ];
}
