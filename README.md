# IponKo 🐷

**Student Savings App — Philippines**
Flutter • Offline-First • Backend-Ready

---

## Quick Start (Android Studio)

```bash
# 1. Open this folder in Android Studio
# 2. Get packages
flutter pub get

# 3. Generate Hive adapters (run once, re-run if you add model fields)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Run on emulator or device
flutter run
```

---

## Project Structure

```
lib/
├── main.dart                    # Entry point, Hive init, ProviderScope
├── models/
│   ├── user_model.dart          # UserModel (Hive + JSON)
│   ├── goal_model.dart          # GoalModel (Hive + JSON)
│   ├── deposit_model.dart       # DepositModel (Hive + JSON)
│   └── badge_model.dart         # BadgeModel + BadgeDefinitions
├── repositories/
│   ├── ipon_repository.dart     # Abstract interface (DO NOT touch when swapping to API)
│   └── hive_repository.dart     # Offline implementation using Hive
├── providers/
│   └── app_providers.dart       # Riverpod providers + Notifiers
├── theme/
│   └── app_theme.dart           # Colors, typography, component themes
├── utils/
│   ├── app_router.dart          # GoRouter navigation
│   └── formatters.dart          # Peso + Date formatters
├── screens/
│   ├── stub_screens.dart        # All stub screens (replace one by one)
│   └── student/
│       └── student_dashboard.dart  # ✅ DONE — Student home screen
└── widgets/
    ├── goal_progress_card.dart  # Goal card with progress bar
    ├── deposit_tile.dart        # Deposit list item + StreakBanner
    └── streak_banner.dart       # Re-export
```

---

## For Jhed (Backend Integration)

When backend is ready, only ONE file changes:

**lib/providers/app_providers.dart** — line ~12:

```dart
// BEFORE (offline):
return HiveRepository();

// AFTER (online):
return ApiRepository(baseUrl: 'http://your-server.com/api');
```

Create `lib/repositories/api_repository.dart` implementing `IponRepository`.
No UI changes needed.

### Agreed JSON Contract

```json
User:    { id, name, email, role, school, gradeLevel, linkedChildId, linkedParentId, createdAt }
Goal:    { id, userId, name, targetAmount, currentAmount, targetDate, createdAt, status, emoji }
Deposit: { id, userId, goalId, amount, source, date, note, isApprovedByParent, createdAt }
```

---

## Screens Build Order (Suggested)

- [x] Student Dashboard
- [ ] Splash Screen (real — with auto-login check)
- [ ] Sign Up Screen
- [ ] PIN Screen
- [ ] Create Goal Screen
- [ ] Add Deposit Screen
- [ ] Goals Screen (list all goals)
- [ ] Deposit Log Screen (with charts)
- [ ] Badges Screen
- [ ] Parent Dashboard
- [ ] Profile & Settings

---

## Tech Stack

| Layer         | Package                | Version |
| ------------- | ---------------------- | ------- |
| UI Framework  | Flutter                | 3.x     |
| Local DB      | hive + hive_flutter    | 2.x     |
| State         | flutter_riverpod       | 2.4.x   |
| Navigation    | go_router              | 13.x    |
| Charts        | fl_chart               | 0.67.x  |
| Animations    | lottie                 | 3.x     |
| Progress bars | percent_indicator      | 4.x     |
| Fonts         | google_fonts (Poppins) | 6.x     |
| Currency/Date | intl                   | 0.19.x  |
| IDs           | uuid                   | 4.x     |
