// lib/utils/app_router.dart

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../screens/stub_screens.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/pin_screen.dart';
import '../screens/student/student_dashboard.dart';
import '../screens/student/add_deposit_screen.dart';
import '../screens/student/create_goal_screen.dart';
import '../screens/student/goals_screen.dart';
import '../screens/student/deposit_log_screen.dart';
import '../screens/student/badges_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const signup = '/signup';
  static const pin = '/pin';
  static const studentDashboard = '/student';
  static const goals = '/student/goals';
  static const createGoal = '/student/goals/create';
  static const depositLog = '/student/deposits';
  static const addDeposit = '/student/deposits/add';
  static const badges = '/student/badges';
  static const profile = '/profile';
  static const parentDashboard = '/parent';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.signup, builder: (_, __) => const SignupScreen()),
      GoRoute(path: AppRoutes.pin, builder: (_, state) {
        final isSetup = state.extra as bool? ?? false;
        return PinScreen(isSetup: isSetup);
      }),
      GoRoute(path: AppRoutes.studentDashboard, builder: (_, __) => const StudentDashboard()),
      GoRoute(path: AppRoutes.goals, builder: (_, __) => const GoalsScreen()),
      GoRoute(path: AppRoutes.createGoal, builder: (_, __) => const CreateGoalScreen()),
      GoRoute(path: AppRoutes.depositLog, builder: (_, __) => const DepositLogScreen()),
      GoRoute(path: AppRoutes.addDeposit, builder: (_, state) {
        final goalId = state.extra as String?;
        return AddDepositScreen(preselectedGoalId: goalId);
      }),
      GoRoute(path: AppRoutes.badges, builder: (_, __) => const BadgesScreen()),
      GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
      GoRoute(path: AppRoutes.parentDashboard, builder: (_, __) => const ParentDashboard()),
    ],
  );
});
