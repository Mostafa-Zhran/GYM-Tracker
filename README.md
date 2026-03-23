# 🏋️ GYM Tracker — Flutter App

A full-stack gym coaching platform connecting **Coaches** and **Trainees** through a mobile-first Flutter app backed by an ASP.NET Core REST API.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Environment & Constants](#environment--constants)
- [API Reference](#api-reference)
- [Authentication Flow](#authentication-flow)
- [Registration & Coach Selection Flow](#registration--coach-selection-flow)
- [Navigation & Routing](#navigation--routing)
- [State Management](#state-management)
- [Screens](#screens)
- [Known Issues & Notes](#known-issues--notes)

---

## Overview

**GYM COACH** is a mobile coaching platform where:
- **Trainees** register, select a coach, receive daily workouts, log their sessions, and chat with their coach
- **Coaches** manage their trainee roster, assign workouts, and communicate via real-time chat

The Flutter frontend communicates with a hosted ASP.NET Core Web API at:
```
https://gymfluterapi.runasp.net/swagger/index.html
```

---

## Features

### Trainee
- Register as a Trainee
- Select and link to a Coach after registration
- View today's assigned workout
- Log completed workout sessions
- Real-time chat with assigned Coach
- JWT-secured session with auto-refresh

### Coach
- View all assigned Trainees
- Assign workouts to specific Trainees
- Real-time chat with Trainees
- Manage coaching schedule

---

## Tech Stack

### Frontend — Flutter
| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^2.5.1 | State management |
| `riverpod_annotation` | ^2.3.5 | Code generation for providers |
| `dio` | ^5.4.3 | HTTP client |
| `go_router` | ^13.2.0 | Declarative routing |
| `flutter_secure_storage` | ^9.0.0 | Secure JWT storage |
| `signalr_netcore` | ^1.3.7 | Real-time chat (SignalR) |
| `intl` | ^0.19.0 | Date/time formatting |
| `flutter_native_splash` | ^2.4.0 | Splash screen |
| `flutter_launcher_icons` | ^0.13.1 | App icon generation |

### Backend — ASP.NET Core
- REST API hosted at `https://gymfluterapi.runasp.net/swagger/index.html`
- JWT Bearer authentication
- SignalR for real-time chat
- Entity Framework Core

---

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart        # API endpoints, storage keys, roles
│   ├── navigation/
│   │   └── app_router.dart           # GoRouter config + AppRoutes
│   ├── network/
│   │   ├── dio_client.dart           # Dio instance + providers
│   │   └── jwt_interceptor.dart      # Bearer token injection on every request
│   └── widgets/
│       └── gym_shell.dart            # Coach/Trainee shell with nav + drawer
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart  # login, register, getCoaches, linkCoach
│   │   ├── models/
│   │   │   └── user_model.dart       # UserModel with fromJson
│   │   ├── providers/
│   │   │   └── auth_provider.dart    # authStateProvider (Notifier)
│   │   └── screens/
│   │       ├── login_page.dart
│   │       └── register_page.dart
│   │
│   ├── coach_selection/
│   │   ├── models/
│   │   │   └── coach_model.dart      # CoachModel { id, name, email }
│   │   └── pages/
│   │       └── coach_selection_page.dart
│   │
│   ├── coach/
│   │   ├── models/
│   │   │   └── trainee_model.dart
│   │   ├── providers/
│   │   │   └── coach_providers.dart  # traineesProvider, assignWorkoutProvider
│   │   ├── data/
│   │   │   └── coach_repository.dart
│   │   └── screens/
│   │       ├── trainees_list_screen.dart
│   │       └── assign_workout_screen.dart
│   │
│   ├── trainee/
│   │   └── screens/
│   │       ├── today_workout_screen.dart
│   │       └── log_workout_screen.dart
│   │
│   └── chat/
│       └── screens/
│           └── chat_screen.dart      # SignalR real-time chat
│
assets/
├── images/
│   ├── GYM.png                       # App launcher icon
│   └── logo.png                      # Splash screen logo
│
web/
│   └── index.html                    # Web splash customization
```

---

## Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Android Studio / VS Code
- Android emulator or physical device

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-username/gym_coaching_app.git
cd gym_coaching_app

# 2. Install dependencies
flutter pub get

# 3. Generate Riverpod providers (if using @riverpod annotation)
dart run build_runner build --delete-conflicting-outputs

# 4. Generate app icons
dart run flutter_launcher_icons

# 5. Generate splash screen
dart run flutter_native_splash:create

# 6. Run the app
flutter run
```

---

## Environment & Constants

All API endpoints and storage keys are defined in:
```
lib/core/constants/app_constants.dart
```

```dart
class AppConstants {
  AppConstants._();

  // ───────────────── Base URL ─────────────────
  static const String baseUrl = 'https://gymfluterapi.runasp.net';

  // ───────────────── Auth ─────────────────
  static const String loginEndpoint = '/api/Account/Login';
  static const String registerEndpoint = '/api/Account/Register/User';
  static const String coachesEndpoint =
      '/api/Account/Coahes'; // typo is intentional — matches backend
  static const String linkCoachEndpoint = '/assign-coach';
  // your POST link endpoint
  // ───────────────── Coach APIs ─────────────────
  static const String traineesEndpoint = '/trainees';
  static const String assignWorkoutEndpoint = '/assign';

  // ───────────────── Trainee APIs ─────────────────
  static const String todayWorkoutEndpoint = '/today';
  static const String logWorkoutEndpoint = '/log';

  // ───────────────── Chat ─────────────────
  static const String chatHistoryEndpoint = '/history';
  static const String chatSeenEndpoint = '/seen';

  // ── SignalR ───────────────────────────────────────────────────────────────
  static const String signalRHubUrl = 'https://gymfluterapi.runasp.net/chatHub';

  // ───────────────── Storage Keys ─────────────────
  static const String tokenKey = 'jwt_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String userNameKey = 'user_name';
  static const String coachIdKey = 'coach_id';

  // ───────────────── Roles ─────────────────
  static const String coachRole = 'Coach';
  static const String traineeRole = 'Trainee';
}

```

---

## API Reference

Base URL: `https://gymfluterapi.runasp.net`

> 🔒 = Requires `Authorization: Bearer <token>` header

### Account

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/api/Account/Register/User` | ❌ | Register new Trainee or Coach |
| `POST` | `/api/Account/Login` | ❌ | Login and receive JWT token |
| `GET` | `/api/Account/Coahes` | 🔒 | Get all coaches list |

### Coach

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/api/Coach/assign-coach` | 🔒 | Link trainee to coach (traineeId from JWT) |
| `POST` | `/api/Coach/assign` | 🔒 | Assign workout to trainee |
| `GET` | `/api/Coach/trainees` | 🔒 | Get coach's trainee list |

---

### Request / Response Examples

#### POST `/api/Account/Register/User`
```json
// Request
{
  "userName": "john_smith",
  "email": "john@example.com",
  "password": "Pass@123",
  "confirmPassword": "Pass@123",
  "role": "Trainee"
}
// Response: 200 OK (no body)
```

#### POST `/api/Account/Login`
```json
// Request
{
  "email": "john@example.com",
  "password": "Pass@123"
}
// Response
{
  "id": "3ce91a77-...",
  "userName": "john_smith",
  "email": "john@example.com",
  "roles": ["Trainee"],
  "token": "eyJhbGci..."
}
```

#### GET `/api/Account/Coahes`
```json
// Response
[
  {
    "id": "3ce91a77-8891-4f69-93e8-b7250d8381af",
    "name": "AhmedO11@gmail.com",
    "email": "AhmedO11@gmail.com"
  }
]
```

#### POST `/api/Coach/assign-coach`
```json
// Request (traineeId is read from JWT token by backend)
{
  "coachId": "3ce91a77-8891-4f69-93e8-b7250d8381af"
}
// Response: 200 OK
```

---

## Authentication Flow

```
App Start
    │
    ├── getStoredUser() from SecureStorage
    │       │
    │       ├── Token found → restore session → navigate to role home
    │       └── No token   → navigate to /login
    │
Login Page
    │
    └── POST /api/Account/Login
            │
            ├── Success → save token + userId + role + name to SecureStorage
            │           → navigate to /coach or /trainee based on role
            └── Failure → show error banner
```

### JWT Interceptor

Every request (except Login and Register) automatically gets:
```
Authorization: Bearer <token>
```
Token is read fresh from `FlutterSecureStorage` before each request using `.then()` chain (not `async/await`) to ensure Dio waits for the read to complete.

If any request returns **401**, all stored credentials are cleared and the user is redirected to login.

---

## Registration & Coach Selection Flow

```
Register Page  (role = Trainee only)
    │
    ├── POST /api/Account/Register/User
    │
    ├── POST /api/Account/Login  (auto-login to get real userId + token)
    │
    └── Navigate to /select-coach
            │
            ├── GET /api/Account/Coahes  (loads coach list with JWT)
            │
            ├── User selects a coach
            │
            └── POST /api/Coach/assign-coach { coachId }
                    │
                    └── Navigate to /login  (user signs in manually)
```

---

## Navigation & Routing

Handled by **GoRouter** with role-based redirect logic.

### Routes

| Path | Page | Auth Required |
|---|---|---|
| `/login` | GymLoginPage | ❌ |
| `/register` | GymRegisterPage | ❌ |
| `/select-coach` | CoachSelectionPage | ❌ |
| `/coach` | TraineesListScreen (CoachShell) | ✅ Coach |
| `/coach/assign-workout` | AssignWorkoutScreen (CoachShell) | ✅ Coach |
| `/trainee` | TodayWorkoutScreen (TraineeShell) | ✅ Trainee |
| `/trainee/log-workout` | LogWorkoutScreen (TraineeShell) | ✅ Trainee |
| `/chat` | ChatScreen | ✅ Any |

### Redirect Logic
```dart
// Not logged in → /login (except /register and /select-coach)
// Logged in + on /login → /coach or /trainee based on role
```

---

## State Management

Using **Riverpod** with a mix of `Provider`, `FutureProvider`, and `StateNotifierProvider`.

### Key Providers

| Provider | Type | Purpose |
|---|---|---|
| `authStateProvider` | `StateNotifierProvider` | Current auth state (isLoggedIn, role, userId, token) |
| `authRepositoryProvider` | `Provider` | Auth API calls |
| `coachesProvider` | `FutureProvider` | Fetch coaches list |
| `traineesProvider` | `FutureProvider` | Fetch coach's trainees |
| `assignWorkoutProvider` | `StateNotifierProvider` | Assign workout state |
| `dioProvider` | `Provider` | Configured Dio instance |
| `secureStorageProvider` | `Provider` | FlutterSecureStorage instance |

---

## Screens

### Auth
- **Login Page** — Email + Password, animated entrance, role-based redirect
- **Register Page** — Username + Email + Password + Confirm, Trainee only, password strength bar

### Coach Selection
- **CoachSelectionPage** — Shows all coaches after registration, animated cards with name/email/initials avatar, links trainee to selected coach

### Coach
- **TraineesListScreen** — Lists all assigned trainees
- **AssignWorkoutScreen** — Assign workout with title, description, date to a specific trainee

### Trainee
- **TodayWorkoutScreen** — Shows today's assigned workout
- **LogWorkoutScreen** — Log completed session

### Chat
- **ChatScreen** — Real-time messaging via SignalR between Trainee and Coach

---

## Known Issues & Notes

| Issue | Notes |
|---|---|
| `/api/Account/Coahes` typo | Backend has "Coahes" instead of "Coaches" — must match exactly |
| `coachesProvider` caching | Invalidated on page open via `WidgetsBinding.instance.addPostFrameCallback` |
| `async void` in Dio interceptor | Fixed — uses `.then()` chain instead of `async/await` to ensure Dio waits for token read |
| Web splash screen | `flutter_native_splash` doesn't support web — splash customized manually in `web/index.html` |
| Profile screens | Not yet implemented — routes removed temporarily, will be added in next milestone |
| `traineeId` in assign-coach | Backend reads `traineeId` from JWT token — do NOT send in request body |

---

## Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'Add my feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

---

## License

This project is private and not licensed for public use.

---

*Built with ❤️ using Flutter & ASP.NET Core*
