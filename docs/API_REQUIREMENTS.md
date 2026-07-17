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
| GET | `/api/community/routes/popular` | — |
| GET | `/api/community/routes/top-rated` | — |
| GET | `/api/community/routes/{id}` | Path: route id |
| GET | `/api/community/routes/{id}/reviews` | Path: route id |
| POST | `/api/community/routes/{id}/reviews` | `rating`, `comment` |
| POST | `/api/community/routes/{id}/like` | — (optional) |

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
| POST | `/api/v1/sos-activate` | `latitude` (optional), `longitude` (optional), `address_link` (optional URL) |
| POST | `/api/v1/sos-cancel` | — |
| POST | `/api/runs/summary` | See below |
| POST | `/api/runs/{runId}/review` | See run review |

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

**Run review payload (`POST /api/runs/{runId}/review`):**
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
| `CommunityService` | `community_service.dart` | `getPopularRoutes`, `getTopRatedRoutes`, `getCommunityRouteDetail`, `getRouteReviews` |
| `ActivityService` | `activity_service.dart` | `getActivitySummary`, `getRecentActivities`, `getLifetimeStats` |
| `RunService` | `run_service.dart` | `activateSos`, `cancelSos`, `submitRunSummary` |
| `RunReviewService` | `run_review_service.dart` | `submitRunReview` |
| `SettingsService` | `settings_service.dart` | `getCurrentUser`, `getPreferences`, `updateProfile`, `getEmergencyContacts`, etc. |
| `DashboardServices` | `dashboard_services.dart` | `generateSafeRoute` |

When adding a real endpoint, update the matching method in `lib/core/services/api_service.dart` — UI and providers stay unchanged.
