// Stub screens — replace these one by one as you build each screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../providers/app_providers.dart';

// ─── Auth Screens ────────────────────────────────────────────────────────────

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.philippineBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🐷', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('IponKo',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800)),
            const Text('Mag-ipon tayo!',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 48),

            // New user → Sign Up
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.philippineYellow,
                  foregroundColor: AppColors.philippineBlue,
                  minimumSize: const Size(220, 52)),
              onPressed: () => context.go(AppRoutes.signup),
              child: const Text('Mag-Sign Up',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),

            // Returning user → PIN
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  minimumSize: const Size(220, 52)),
              onPressed: () => context.go(AppRoutes.pin, extra: false),
              child: const Text('Mag-Login',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),

            const SizedBox(height: 24),

            // Demo shortcut — remove before final submission
            TextButton(
              onPressed: () async {
                final repo = ref.read(repositoryProvider);
                var user = await repo.getCurrentUser();
                if (user == null) {
                  user = UserModel(
                    id: 'demo_student_001',
                    name: 'Joshua',
                    email: 'joshua@iponko.ph',
                    role: 'student',
                    school: 'BSIT School',
                    gradeLevel: 3,
                    createdAt: DateTime.now(),
                    isSynced: false,
                  );
                  await repo.saveUser(user);
                }
                if (context.mounted) context.go('/student');
              },
              child: const Text('🧪 Demo Mode',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) => _StubScreen(title: 'Onboarding', emoji: '📖');
}

// SignupScreen moved to lib/screens/auth/signup_screen.dart
// PinScreen moved to lib/screens/auth/pin_screen.dart

// ─── Student Screens ─────────────────────────────────────────────────────────

// GoalsScreen moved to lib/screens/student/goals_screen.dart

// CreateGoalScreen moved to lib/screens/student/create_goal_screen.dart

// DepositLogScreen moved to lib/screens/student/deposit_log_screen.dart

// AddDepositScreen moved to lib/screens/student/add_deposit_screen.dart

// BadgesScreen moved to lib/screens/student/badges_screen.dart

// ─── Parent Screens ──────────────────────────────────────────────────────────

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});
  @override
  Widget build(BuildContext context) => _StubScreen(title: 'Parent Dashboard', emoji: '👨‍👩‍👧');
}

// ─── Shared Screens ──────────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => _StubScreen(title: 'Profile', emoji: '👤');
}

// ─── Generic Stub Widget ─────────────────────────────────────────────────────

class _StubScreen extends StatelessWidget {
  final String title;
  final String emoji;
  const _StubScreen({required this.title, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Coming soon — build this next!',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
