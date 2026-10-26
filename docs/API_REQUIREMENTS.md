# Saefra Run — API Requirements

This document lists backend endpoints the Flutter app expects.  
All methods use the base URL from `.env` (`BASE_URL`).  
Authenticated routes require `Authorization: Bearer {token}`.

Toggle mock data locally with `USE_MOCK_API=true` in `.env` — no backend needed for UI development.

---

## Auth (implemented)

| Method | Path | Body / Params |
|--------|------|----------------|
| POST | `/api/auth/login` | `email`, `password` |
| POST | `/api/auth/register` | `email`, `password`, `gender`, `birthdate`, `visit_reason`, `run_preference` |
| POST | `/api/auth/forgot-password` | `email` |
| POST | `/api/auth/reset-password` | `email`, `password`, `otp`, `password_confirmation` |
| POST | `/api/auth/change-password` | `old_password`, `password`, `password_confirmation` |

---

## Profile & preferences (implemented)

| Method | Path | Body / Params |
|--------|------|----------------|
| GET | `/api/profile` | — |
| POST | `/api/profile` | `gender`, `birthdate` (M-d-yyyy) |
| GET | `/api/preferences` | — |
| POST | `/api/preferences` | `visit_reason`, `run_preference`, `share_live_location`, `emergency_alerts_enabled`, `push_notifications_enabled`, `email_notifications_enabled` |

---

## Dashboard routes (partial — safe route wired)

| Method | Path | Body / Params |
|--------|------|----------------|
| POST | `/api/routes/generate-safe-route` | JSON: `origin`, `destination`, `travelMode`, etc. |
| GET | `/api/routes/search` | Query: `q` (string) |
| GET | `/api/routes/{id}` | Path: route id |
| POST | `/api/routes/generate` | Query: `distance_km`, `difficulty`, `route_type`, `lighting` |

**Search response shape:**
```json
{
  "success": true,
  "routes": [
    {
      "id": "1",
      "name": "Lakeside Perimeter",
      "distance_km": 3.2,
      "duration": 24,
      "tag": "Popular",
      "route_image": "https://..."
    }
  ]
}
```

---

## Community

| Method | Path | Params |
|--------|------|--------|
| POST | `/api/v1/community-routes` | `page`, `perPage`, `search` (optional) |
| POST | `/api/v1/popular-routes-list` | `page`, `perPage`, `search` (optional) |
| POST | `/api/v1/recent-routes-list` | `page`, `perPage`, `search` (optional) |
| GET | `/api/community/routes/{id}` | Path: route id |
| GET | `/api/community/routes/{id}/reviews` | Path: route id |
| POST | `/api/community/routes/{id}/reviews` | `rating`, `comment` |

**Community routes response (`POST /api/v1/community-routes`):**
```json
{
  "status": "success",
  "data": {
    "popular_routes": [ { "...Community route object..." } ],
    "recent_routes": [ { "...Community route object..." } ],
    "total": 50,
    "last_page": 3
  }
}
```

Legacy endpoints (deprecated):

| Method | Path |
|--------|------|
| GET | `/api/community/routes/popular` |
| GET | `/api/community/routes/top-rated` |

**Community route object:**
```json
{
  "id": "c1",
  "name": "Sunset Loop",
  "location": "Central Park, NY",
  "distance_km": 5.02,
  "estimated_duration": 42,
  "rating": 4.8,
  "like_count": 128,
  "comment_count": 24,
  "difficulty": "Beginner",
  "tags": ["Hill", "Forest"],
  "elevation_gain": 154,
  "description": "...",
  "route_image": "https://..."
}
```

---

## Activity / stats

| Method | Path | Params |
|--------|------|--------|
| GET | `/api/v1/activity-dashboard` | — |

**Activity dashboard response:**
```json
{
  "status": "success",
  "data": {
    "statistics": {
      "total_distance": "0.1 km",
      "total_running_time": "0h 5m",
      "total_steps": 130,
      "average_pace": "56:13/km",
      "total_runs": 12
    },
    "activities": [
      {
        "run_id": 16,
        "route_name": "ShreePad Residency...",
        "location": "Santa Monica, CA",
        "image": "",
        "date": "Yesterday, 12:28 PM",
        "distance": "0.06 km",
        "duration": "1 min",
        "calories": "12"
      }
    ]
  }
}
```

Legacy endpoints (deprecated):

| Method | Path | Params |
|--------|------|--------|
| GET | `/api/activity/summary` | Query: `period` = `weekly` \| `monthly` \| `yearly` |
| GET | `/api/activity/recent` | — |
| GET | `/api/activity/lifetime` | — |

**Summary response:**
```json
{
  "summary": {
    "total_distance_km": 18.4,
    "total_minutes": 142,
    "total_calories": 980,
    "avg_pace_min_per_km": 6.2
  }
}
```

---

## Live run & SOS

| Method | Path | Body |
|--------|------|------|
| POST | `/api/v1/run-start` | `route_id`, `latitude`, `longitude`, `started_at` (Y-m-d H:i:s) |
| POST | `/api/v1/run-update` | `run_id`, `latitude`, `longitude`, `timestamp` (Y-m-d H:i:s), `distance`, `duration`, `speed`, `pace`, `steps` |
| POST | `/api/v1/run-pause` | `run_id` |
| POST | `/api/v1/run-resume` | `run_id` |
| POST | `/api/v1/run-finish` | `run_id`, `ended_at` (Y-m-d H:i:s), `polyline`, `latitude`, `longitude` |
| GET | `/api/v1/run-summary/{run_id}` | Query: `run_id` |
| POST | `/api/v1/route-review` | `route_id`, `overall_rating`, `comment`, optional `run_id`, optional `route_feel`, `route_surface`, `route_sidewalk`, `route_image[]` |
| POST | `/api/v1/route-review-list` | `route_id`, `page`, `perPage` |
| POST | `/api/v1/contact-us` | `name`, `email`, `message` |
| POST | `/api/v1/run-feeling` | `run_id`, `run_feeling` (`great`, `good`, `okay`, `tough`, `exhausted`) |
| POST | `/api/v1/sos-activate` | `latitude` (optional), `longitude` (optional), `address_link` (optional URL) |
| POST | `/api/v1/sos-cancel` | — |

**Run summary payload (`POST /api/runs/summary`):**
```json
{
  "route_id": "2",
  "distance_km": 5.02,
  "elapsed_seconds": 1965,
  "pace": "6'32\"/km",
  "calories": 386,
  "mood": "good",
  "splits": [
    { "km": 1, "time": "5:20", "pace_factor": 0.6 }
  ]
}
```

**Route review payload (`POST /api/v1/route-review`):**
```json
{
  "route_id": "2",
  "run_id": "12",
  "overall_rating": 5,
  "route_feel": "balanced",
  "route_surface": "mixed_surfaces",
  "route_sidewalk": "some_sections",
  "comment": "Great route!",
  "route_image[]": ["file uploads"]
}
```

`run_id` is optional. One review per user per route.

**Route review list (`POST /api/v1/route-review-list`):**
```json
{
  "status": "success",
  "data": {
    "reviews": [
      {
        "id": 1,
        "user_name": "Jane",
        "overall_rating": 5,
        "comment": "Great route",
        "created_at": "2 days ago"
      }
    ],
    "currentPage": 1,
    "totalPage": 1,
    "perPage": 20,
    "totalRecords": 1
  }
}
```

**Contact us (`POST /api/v1/contact-us`):**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "message": "Need help with my account"
}
```

**Run review payload (legacy `/api/runs/{runId}/review`):**
```json
{
  "who_with": "noOne",
  "environment_tags": ["Pedestrians", "Well-lit"],
  "accuracy_rating": "yes",
  "run_mode": "felt_good",
  "feedback": "Great route!",
  "surface": "asphalt",
  "weather": "sunny",
  "image_paths": ["https://..."]
}
```

---

## Emergency contacts (implemented)

| Method | Path | Body |
|--------|------|------|
| GET | `/api/v1/get-emergency-contacts` | — |
| POST | `/api/v1/add-emergency-contacts` | `name` (required), `phone` (required), `image` (optional, max 2MB, jpg/jpeg/png/gif) |
| DELETE | `/api/v1/delete-emergency-contacts/{id}` | `id` (query param) |

---

## Notifications & FCM (implemented)

| Method | Path | Body / Params |
|--------|------|----------------|
| POST | `/api/v1/update-fcm-token` | `fcm_token` (required) |
| POST | `/api/v1/get-notifications` | `category` (optional), `page` (optional), `perPage` (optional) |
| POST | `/api/v1/read-notification/{id}` | `id` (path + query param) |
| DELETE | `/api/v1/delete-notification/{id}` | `id` (path + query param) |
| DELETE | `/api/v1/clear-all-notifications` | — |

**Get notifications response:**
```json
{
  "message": "Notifications found successfully!",
  "data": {
    "notifications": [
      {
        "id": 2,
        "notification_type": "sos_cancelled",
        "category": "Safety Alerts",
        "title": "SOS Cancelled",
        "message": "You cancelled the SOS alert...",
        "payload": [],
        "is_read": false,
        "read_at": null,
        "created_at": "2026-07-17 13:16:01",
        "updated_at": "2026-07-17 13:16:01"
      }
    ]
  }
}
```

---

## Standard response format

The app parser (`ApiResponseParser`) expects Laravel-style responses:

```json
{
  "success": true,
  "message": "Optional message",
  "data": { }
}
```

Or top-level keys like `user`, `routes`, `contacts`, `preferences`, `route`, `reviews`, `summary`, `activities`, `lifetime`.

Errors: HTTP 4xx/5xx with `message` and optional `errors` object.

---

## Flutter integration map

| Provider | Service file | API methods used |
|----------|--------------|------------------|
| `RouteSearchService` | `route_search_service.dart` | `searchRoutes` |
| `GenerateRouteService` | `generate_route_service.dart` | `generateRoute` |
| `RouteDetailService` | `route_detail_service.dart` | `getRouteDetail` |
| `CommunityService` | `community_service.dart` | `getCommunityRoutes`, `getRouteReviewList`, `submitRouteReview` |
| `ActivityService` | `activity_service.dart` | `getActivitySummary`, `getRecentActivities`, `getLifetimeStats` |
| `RunService` | `run_service.dart` | `startRunSession`, `updateRunSession`, `pauseRunSession`, `resumeRunSession`, `finishRunSession`, `getRunSummary`, `submitRunFeeling`, `activateSos`, `cancelSos` |
| `RunReviewService` | `run_review_service.dart` | `submitRunReview` (`/api/v1/route-review`) |
| `SettingsService` | `settings_service.dart` | `getCurrentUser`, `updateProfile`, `submitContactUs`, etc. |
| `NotificationInboxService` | `notification_inbox_service.dart` | `getNotifications`, `markNotificationRead`, `deleteNotification`, `clearAllNotifications` |
| `FcmService` | `fcm_service.dart` | `updateFcmToken` |
| `DashboardServices` | `dashboard_services.dart` | `generateSafeRoute` |

When adding a real endpoint, update the matching method in `lib/core/services/api_service.dart` — UI and providers stay unchanged.
