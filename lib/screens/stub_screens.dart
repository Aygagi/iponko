// lib/screens/stub_screens.dart
// Only SplashScreen and OnboardingScreen remain here.
// All other screens have been moved to their own files.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../providers/app_providers.dart';
import '../utils/app_router.dart';

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
              onPressed: () => context.go(AppRoutes.signup),
              child: const Text('Mag-Sign Up',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
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
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: const Center(
        child: Text('📖', style: TextStyle(fontSize: 48)),
      ),
    );
  }
}
