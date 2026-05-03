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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.philippineYellow,
                  foregroundColor: AppColors.philippineBlue,
                  minimumSize: const Size(220, 52)),
              onPressed: () async {
                // Seed a demo student user for testing
                final repo = ref.read(repositoryProvider);
                var user = await repo.getCurrentUser();
                if (user == null) {
                  user = UserModel(
                    id: 'demo_student_001',
                    name: 'Joshua',
                    email: 'joshua@iponko.ph',
                    role: 'student',
                    school: 'Your School',
                    gradeLevel: 3,
                    createdAt: DateTime.now(),
                    isSynced: false,
                  );
                  await repo.saveUser(user);
                }
                if (context.mounted) context.go('/student');
              },
              child: const Text('Student Demo',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  minimumSize: const Size(220, 52)),
              onPressed: () => context.go('/parent'),
              child: const Text('Parent Demo'),
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

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});
  @override
  Widget build(BuildContext context) => _StubScreen(title: 'Sign Up', emoji: '✍️');
}

class PinScreen extends StatelessWidget {
  final bool isSetup;
  const PinScreen({super.key, required this.isSetup});
  @override
  Widget build(BuildContext context) => _StubScreen(
      title: isSetup ? 'Set PIN' : 'Enter PIN', emoji: '🔐');
}

// ─── Student Screens ─────────────────────────────────────────────────────────

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});
  @override
  Widget build(BuildContext context) => _StubScreen(title: 'Goals', emoji: '🎯');
}

class CreateGoalScreen extends StatelessWidget {
  const CreateGoalScreen({super.key});
  @override
  Widget build(BuildContext context) => _StubScreen(title: 'Create Goal', emoji: '✨');
}

class DepositLogScreen extends StatelessWidget {
  const DepositLogScreen({super.key});
  @override
  Widget build(BuildContext context) => _StubScreen(title: 'Deposit Log', emoji: '📋');
}

// AddDepositScreen moved to lib/screens/student/add_deposit_screen.dart

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});
  @override
  Widget build(BuildContext context) => _StubScreen(title: 'Badges', emoji: '🏆');
}

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
