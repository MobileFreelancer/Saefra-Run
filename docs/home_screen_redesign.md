# Home Screen Redesign Documentation

This document describes the changes made to the Home Screen (Dashboard) and navigation flow, so that subsequent developer agents (or tools) can understand the architecture.

## Overview
The goal was to replace the old home screen with a template-based route guide for beginner runners, while preserving all original APIs and commenting out the old home screen layout for future reference.

## Modified Files and Abstractions

### 1. `app_router.dart`
- **Location**: `lib/core/router/app_router.dart`
- **Changes**: Added optional query parameters parsing to the `/routes/generate` (`generateRoute`) path:
  - `difficulty`: String, maps to `RouteDifficulty`.
  - `distance`: Double, maps to distance in kilometers.
  - `shape`: String, maps to `RouteShape`.
- This allows presets to be passed from the Home template cards directly into the generation screen.

### 2. `app_bottom_nav.dart`
- **Location**: `lib/core/widgets/app_bottom_nav.dart`
- **Changes**: Updated the center bottom navigation button (originally pointing to live running with a route ID) to point directly to `generateRoute` (`/routes/generate`) screen without parameters (serving as the "Generate My Own" custom flow).

### 3. `generate_route_screen.dart`
- **Location**: `lib/features/routes/screens/generate_route_screen.dart`
- **Changes**: 
  - Updated the constructor of `GenerateRouteScreen` to receive `difficulty`, `distance`, and `shape`.
  - In `initState`, these arguments are passed to the `GenerateRouteService` via `setDifficulty`, `setDistance`, and `setShape` respectively, which updates the state of the active filters on load.

### 4. `dashboard_screen.dart`
- **Location**: `lib/features/dashboard/screens/dashboard_screen.dart`
- **Changes**:
  - The entire old `DashboardScreen` widget class and auxiliary widgets have been commented out at the bottom of the file (marked with `OLD DASHBOARD SCREEN IMPLEMENTATION FOR FUTURE REFERENCE`).
  - The new `DashboardScreen` widget implements the following sections matching the client mockup:
    1. **Top Profile Bar**: User name, profile avatar, and notification inbox link.
    2. **Template Options**: Vertical select list of 4 cards (Easy & Relaxing, Medium Challenge, Community Favorite, and Generate My Own).
    3. **Find My Route Action**: Button at the bottom of templates that processes the selected card:
       - *Easy & Relaxing* -> Goes to generator with Easy difficulty, 3.0 km, Loop shape defaults.
       - *Medium Challenge* -> Goes to generator with Moderate difficulty, 10.0 km, Loop shape defaults.
       - *Community Favorite* -> Switches tab / navigates to the Community screen.
       - *Generate My Own* -> Opens generator screen without presets (keeps last-used settings).
    4. **Fitness Stats Section**: Integrates `ActivityService` to fetch weekly statistics (`totalCalories` as kcal, `totalMinutes` as minutes, and `totalDistanceKm` as km) with premium look visual stat cards.
    5. **Recent Routes**: Pulls the last 2 recent routes from `DashboardServices`.
    6. **Map Overview**: Embedded rounded-corner card wrapper for the `DashboardMap`.
