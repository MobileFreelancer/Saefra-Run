import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saefra_run/core/models/activity_model.dart';
import 'package:saefra_run/core/models/community_route_model.dart';
import 'package:saefra_run/core/models/notification_model.dart';
import 'package:saefra_run/core/models/review_model.dart';
import 'package:saefra_run/core/models/route_model.dart';

/// Static dummy data — swap [ApiService] calls when backend endpoints are ready.
class AppMockData {
  AppMockData._();

  static const defaultMapTarget = LatLng(21.205194905801783, 72.77568113625402);

  static const List<LatLng> defaultPolyline = [
    LatLng(21.20519, 72.77568),
    LatLng(21.20650, 72.77710),
    LatLng(21.20820, 72.77840),
    LatLng(21.20980, 72.77690),
    LatLng(21.20810, 72.77480),
    LatLng(21.20519, 72.77568),
  ];

  static Map<String, dynamic> get recommendedRouteJson => {
        'route_id': '2',
        'route_name': 'North Loop Patrol',
        'route_image': 'assets/images/background.png',
        'distance': 3.2,
        'estimated_duration': 18,
        'safepoints': 14,
        'safety_score': '94%',
        'runner_count': 23,
        'is_secure': true,
        'start_latitude': 21.20519,
        'start_longitude': 72.77568,
        'end_latitude': 21.20980,
        'end_longitude': 72.77690,
        'starting_point': 'Central Park',
        'ending_point': 'North Loop',
        'route_coordinates': 'orl`Cu_e{L',
      };

  static List<dynamic> get recentRoutesJson => [
        {
          'route_id': '1',
          'route_name': 'Lakeside Perimeter',
          'route_image': 'assets/images/background.png',
          'date': '2026-06-09T10:00:00+00:00',
          'distance': 3.2,
          'duration': 24,
          'tag': 'Popular',
        },
        {
          'route_id': '3',
          'route_name': 'River Trail Loop',
          'route_image': 'assets/images/background.png',
          'date': '2026-06-08T18:30:00+00:00',
          'distance': 5.0,
          'duration': 35,
          'tag': 'Safe path',
        },
      ];

  static List<RouteModel> get searchRoutes => const [
        RouteModel(
          id: '1',
          name: 'Lakeside Perimeter',
          distanceKm: 3.2,
          durationMinutes: 24,
          tag: 'Popular',
          dateIso: '2026-06-09',
          imageAsset: 'assets/images/background.png',
        ),
        RouteModel(
          id: '2',
          name: 'North Loop Patrol',
          distanceKm: 2.3,
          durationMinutes: 18,
          safePoints: 14,
          tag: 'Route Secure',
          imageAsset: 'assets/images/background.png',
        ),
        RouteModel(
          id: '3',
          name: 'Sunset Loop',
          distanceKm: 5.02,
          durationMinutes: 42,
          tag: 'Scenic',
          imageAsset: 'assets/images/background.png',
        ),
      ];

  static List<CommunityRouteModel> get communityRoutes => const [
        CommunityRouteModel(
          id: 'c1',
          name: 'Sunset Loop',
          location: 'Central Park, NY',
          distanceKm: 5.02,
          durationMinutes: 42,
          rating: 4.8,
          likeCount: 128,
          commentCount: 24,
          difficultyTag: 'Beginner',
          tags: ['Hill', 'Forest', 'Nature'],
          elevationGainM: 154,
          imageAsset: 'assets/images/background.png',
          description:
              'A scenic loop through tree-lined paths with excellent lighting and steady foot traffic.',
        ),
        CommunityRouteModel(
          id: 'c2',
          name: 'Lakeside Perimeter',
          location: 'Hudson River',
          distanceKm: 3.2,
          durationMinutes: 24,
          rating: 4.6,
          likeCount: 86,
          commentCount: 11,
          difficultyTag: 'Easy',
          tags: ['Waterfront', 'Flat'],
          elevationGainM: 42,
          imageAsset: 'assets/images/background.png',
        ),
        CommunityRouteModel(
          id: 'c3',
          name: 'North Loop Patrol',
          location: 'Brooklyn Bridge',
          distanceKm: 2.3,
          durationMinutes: 18,
          rating: 4.9,
          likeCount: 210,
          commentCount: 45,
          difficultyTag: 'Moderate',
          tags: ['Urban', 'Well-lit'],
          elevationGainM: 88,
          imageAsset: 'assets/images/background.png',
        ),
      ];

  static List<ReviewModel> get routeReviews => const [
        ReviewModel(
          id: '1',
          userName: 'Sarah M.',
          rating: 5,
          comment:
              'Always well lit and plenty of other runners around. Feel very safe here!',
          timeAgo: '2 days ago',
        ),
        ReviewModel(
          id: '2',
          userName: 'James K.',
          rating: 4,
          comment: 'Great route, a bit crowded on weekends.',
          timeAgo: '1 week ago',
        ),
      ];

  static ActivitySummaryModel activitySummary(ActivityPeriod period) {
    return switch (period) {
      ActivityPeriod.weekly => const ActivitySummaryModel(
          totalDistanceKm: 18.4,
          totalMinutes: 142,
          totalCalories: 980,
          avgPaceMinPerKm: 6.2,
        ),
      ActivityPeriod.monthly => const ActivitySummaryModel(
          totalDistanceKm: 72.5,
          totalMinutes: 540,
          totalCalories: 3820,
          avgPaceMinPerKm: 6.5,
        ),
      ActivityPeriod.yearly => const ActivitySummaryModel(
          totalDistanceKm: 412.0,
          totalMinutes: 3180,
          totalCalories: 21400,
          avgPaceMinPerKm: 6.4,
        ),
    };
  }

  static List<RecentActivityModel> get recentActivities => const [
        RecentActivityModel(
          id: 'a1',
          name: 'Sunset Loop',
          dateLabel: 'Today • 7:30 AM',
          distanceKm: 5.02,
          durationMinutes: 32,
          paceLabel: '6\'32"/km',
        ),
        RecentActivityModel(
          id: 'a2',
          name: 'Lakeside Perimeter',
          dateLabel: 'Yesterday • 6:10 PM',
          distanceKm: 3.2,
          durationMinutes: 24,
          paceLabel: '7\'05"/km',
        ),
      ];

  static const LifetimeStatsModel lifetimeStats = LifetimeStatsModel(
    totalDistanceKm: 1248.5,
    totalHours: 186,
    totalCalories: 68420,
    avgPaceMinPerKm: 6.3,
    paceTrend: [0.4, 0.6, 0.5, 0.8, 0.7, 0.9, 0.6],
  );

  static List<AppNotificationModel> get notifications => const [
        AppNotificationModel(
          id: '1',
          userName: 'Milly Jane',
          message:
              'invited to join their group "Bicycle Riders Group".',
          timestamp: '12:45pm',
          isRead: false,
        ),
        AppNotificationModel(
          id: '2',
          userName: 'Milly Jane',
          message: 'reviewed your route "North Loop Patrol".',
          timestamp: '10:30',
          isRead: false,
        ),
        AppNotificationModel(
          id: '3',
          userName: 'Milly Jane',
          message: 'posted a picture on your route.',
          timestamp: '11:00',
          isRead: false,
        ),
      ];

  static RouteModel routeDetail(String id) => RouteModel(
        id: id,
        name: 'North Loop Patrol',
        distanceKm: 2.3,
        durationMinutes: 18,
        runnerCount: 23,
        safePoints: 14,
        saefraScore: 94,
        safetyScore: '94%',
        locationLabel: 'Central Park, NY',
        visibilityLabel: 'High Visibility Route',
        trafficLevel: 'Low',
        lightingLevel: 'High',
        communityRating: 4.8,
        isSecure: true,
        imageAsset: 'assets/images/background.png',
      );
}
