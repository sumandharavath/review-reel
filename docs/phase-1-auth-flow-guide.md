# Phase 1: Authentication & Mobile Shell Guide

This document details the complete production-grade authentication flow, MVVM + BLoC architecture, session preservation, and navigation setup for **Review Reel**.

---

## 1. Overview of Implementation

### A. Mobile Architecture (`apps/mobile`)
- **Package / Bundle ID**: `com.reviewreel.app` (both Android and iOS)
- **Architecture Pattern**: Clean Architecture + MVVM + BLoC (`flutter_bloc`)
- **State Management**: `AuthBloc` (`AuthInitial`, `AuthLoading`, `Authenticated`, `Unauthenticated`, `AuthFailure`)
- **Navigation**: `go_router` with `StatefulShellRoute.indexedStack` (preserving bottom nav state across 4 tabs: Movies, Explore, Bookings, Profile)
- **Session Preservation**: `flutter_secure_storage` (AES encrypted on Android via KeyStore, Keychain on iOS)
- **Onboarding Flag**: `shared_preferences` (persists `has_seen_onboarding`)
- **App Launcher Icons**: Generated 1024x1024 cinematic icon and integrated for all Android densities & iOS asset catalogs via `flutter_launcher_icons`.

### B. Backend Services (`services/api`)
- **Database**: PostgreSQL (`review_reel_dev`) updated with `password_hash`, `avatar_url`, and `phone` columns on `users`.
- **Security**: Password hashing with `bcryptjs` (salt rounds: 10), stateless tokens with `jsonwebtoken` (7-day validity).
- **Validation**: Strict input schema validation with `zod`.
- **Endpoints**:
  - `POST /api/v1/auth/register`: Create account -> returns `{ user, token }`
  - `POST /api/v1/auth/login`: Authenticate -> returns `{ user, token }`
  - `GET /api/v1/auth/me`: Authenticated profile via `Bearer <token>` header -> returns `{ user }`
  - `POST /api/v1/auth/logout`: Invalidate client session confirmation.

---

## 2. Directory Structure (`apps/mobile/lib`)

```
lib/
├── core/
│   ├── constants/
│   │   ├── api_constants.dart      # Intelligent baseUrl (10.0.2.2 for Android emulator, localhost for iOS/Web)
│   │   ├── app_colors.dart         # Obsidian cinema dark theme colors
│   │   └── app_theme.dart          # Material 3 dark theme with GoogleFonts.poppins
│   ├── network/
│   │   ├── api_exception.dart      # Custom exception for backend error messages
│   │   └── dio_client.dart         # Dio with JWT bearer token auto-injection
│   ├── router/
│   │   ├── app_routes.dart         # Central route path constants
│   │   └── app_router.dart         # GoRouter with auth-guard and StatefulShellRoute
│   └── storage/
│       ├── local_storage_service.dart   # SharedPreferences (onboarding flags)
│       └── secure_storage_service.dart  # FlutterSecureStorage (JWT token & user JSON)
├── data/
│   ├── datasources/
│   │   └── auth_remote_datasource.dart  # Dio REST API calls
│   ├── models/
│   │   ├── auth_response.dart
│   │   └── user_model.dart
│   └── repositories/
│       └── auth_repository_impl.dart    # Implements domain repository, caches token
├── domain/
│   ├── entities/
│   │   └── user_entity.dart
│   └── repositories/
│       └── auth_repository.dart         # Clean domain repository interface
├── presentation/
│   ├── bloc/
│   │   └── auth/
│   │       ├── auth_bloc.dart           # BLoC logic
│   │       ├── auth_event.dart          # Events (Check, Login, Register, Logout)
│   │       └── auth_state.dart          # States (Initial, Loading, Authenticated, etc.)
│   ├── screens/
│   │   ├── splash/
│   │   │   └── splash_screen.dart       # Animated logo, session check & onboarding branch
│   │   ├── onboarding/
│   │   │   └── onboarding_screen.dart   # 3 cinematic slides with PageView indicator
│   │   ├── auth/
│   │   │   ├── login_screen.dart        # Email/password form with demo account shortcut
│   │   │   └── register_screen.dart     # Full registration with password match validation
│   │   └── shell/
│   │       ├── main_shell_screen.dart   # BottomNavigationBar (Movies, Explore, Bookings, Profile)
│   │       ├── home_screen.dart         # Featured hero banner & Now Showing carousel
│   │       ├── explore_screen.dart      # Search bar & genre filter pills
│   │       ├── bookings_screen.dart     # Empty state ticket illustration
│   │       └── profile_screen.dart      # User details, role badge, and working Sign Out dialog
│   └── widgets/
│       ├── brand_logo.dart
│       ├── custom_button.dart
│       └── custom_text_field.dart
└── main.dart
```

---

## 3. App Entry & Session Flow Logic

```
                    ┌─────────────────────────┐
                    │      Launch App         │
                    └───────────┬─────────────┘
                                │
                                ▼
                    ┌─────────────────────────┐
                    │      SplashScreen       │
                    │  (Animates Brand Logo)  │
                    └───────────┬─────────────┘
                                │
                                ▼
                    ┌─────────────────────────┐
                    │   Check Secure Storage  │
                    │    for Auth JWT Token   │
                    └───────────┬─────────────┘
                                │
               ┌────────────────┴────────────────┐
          Token exists?                     No token?
               │                                 │
               ▼                                 ▼
   ┌───────────────────────┐         ┌───────────────────────┐
   │  Call GET /auth/me    │         │ Has Seen Onboarding?  │
   │  to validate session  │         └───────────┬───────────┘
   └───────────┬───────────┘                     │
         ┌─────┴─────┐                     ┌─────┴─────┐
       Valid       Invalid                No          Yes
         │           │                     │           │
         ▼           ▼                     ▼           ▼
   ┌──────────┐ ┌─────────┐         ┌───────────┐ ┌─────────┐
   │  /home   │ │ /login  │         │/onboarding│ │ /login  │
   └──────────┘ └─────────┘         └───────────┘ └─────────┘
```

---

## 4. How to Run & Test

### A. Run Backend API
```bash
cd services/api
npm run dev
```

### B. Run Flutter Mobile App
```bash
cd apps/mobile
flutter run
```

### C. Testing the Auth Flow
1. **Fresh Install**:
   - Opens **Splash Screen** with animated cinematic logo.
   - Redirects to **Onboarding** (3 slides).
   - Tapping **Get Started** sets the onboarding flag and routes to **Login Screen**.
2. **Login / Register**:
   - You can click **"Use Demo Account (Alex)"** to instantly pre-fill test credentials (`alex@example.com` / `password123`) or create a new account via the **Sign Up** link.
   - Tapping **Sign In** authenticates against your local Node/Express backend, saves the JWT in secure storage, and lands on the **Movies / Home** tab.
3. **Session Preservation**:
   - Close the app and restart it. The Splash Screen detects the saved token, verifies `/auth/me`, and opens directly to `/home` without requiring login again!
4. **Sign Out**:
   - Go to the **Profile** tab (4th tab).
   - Click **"Sign Out of Session"** -> confirm in the dialog.
   - The token is purged from secure storage and the app immediately routes back to **Login Screen**.
