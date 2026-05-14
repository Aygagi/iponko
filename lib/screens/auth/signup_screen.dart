// lib/screens/auth/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_router.dart';

const _uuid = Uuid();

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _schoolController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'student';
  int? _selectedGrade;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  final List<int> _grades = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = UserModel(
        id: _uuid.v4(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        role: _selectedRole,
        school: _schoolController.text.trim().isEmpty
            ? null
            : _schoolController.text.trim(),
        gradeLevel: _selectedRole == 'student' ? _selectedGrade : null,
        createdAt: DateTime.now(),
        isSynced: false,
      );

      final repo = ref.read(repositoryProvider);
      await repo.saveUser(user);

      if (mounted) {
        // Go to PIN setup after registration
        context.go(AppRoutes.pin, extra: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Hindi na-register. Subukan ulit.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 24),

              // ── Header ──────────────────────────────────────────────
              _Header(),

              const SizedBox(height: 32),

              // ── Role Selector ────────────────────────────────────────
              const _FieldLabel(label: 'Sino ka?', sublabel: 'Role'),
              const SizedBox(height: 10),
              _RoleSelector(
                selected: _selectedRole,
                onChanged: (r) => setState(() {
                  _selectedRole = r;
                  _selectedGrade = null;
                }),
              ),

              const SizedBox(height: 24),

              // ── Full Name ────────────────────────────────────────────
              const _FieldLabel(label: 'Buong Pangalan', sublabel: 'Full name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'hal. Juan dela Cruz',
                  prefixIcon: Icon(Icons.person_outline_rounded,
                      color: AppColors.philippineBlue),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ilagay ang iyong pangalan';
                  }
                  if (v.trim().length < 2) return 'Masyadong maikli';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Email ────────────────────────────────────────────────
              const _FieldLabel(label: 'Email', sublabel: 'Email address'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                decoration: const InputDecoration(
                  hintText: 'hal. juan@email.com',
                  prefixIcon: Icon(Icons.email_outlined,
                      color: AppColors.philippineBlue),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ilagay ang iyong email';
                  }
                  if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(v.trim())) {
                    return 'Hindi valid na email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── School ───────────────────────────────────────────────
              const _FieldLabel(
                  label: 'Paaralan (optional)', sublabel: 'School'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _schoolController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'hal. Cebu Normal University',
                  prefixIcon: Icon(Icons.school_outlined,
                      color: AppColors.philippineBlue),
                ),
              ),

              // ── Grade Level (student only) ───────────────────────────
              if (_selectedRole == 'student') ...[
                const SizedBox(height: 16),
                const _FieldLabel(
                    label: 'Grade Level (optional)',
                    sublabel: 'Year/Grade'),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedGrade,
                  decoration: const InputDecoration(
                    hintText: 'Piliin ang grade level',
                    prefixIcon: Icon(Icons.grade_outlined,
                        color: AppColors.philippineBlue),
                  ),
                  items: _grades
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g <= 6
                                ? 'Grade $g (Elementary)'
                                : g <= 10
                                    ? 'Grade $g (JHS)'
                                    : 'Grade $g (SHS)'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGrade = v),
                ),
              ],

              const SizedBox(height: 16),

              // ── Password ─────────────────────────────────────────────
              const _FieldLabel(label: 'Password', sublabel: 'Para sa account'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Minimum 6 characters',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.philippineBlue),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ilagay ang password';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Confirm Password ─────────────────────────────────────
              const _FieldLabel(
                  label: 'Ulitin ang Password',
                  sublabel: 'Confirm password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: 'I-type ulit ang password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.philippineBlue),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ulitin ang password';
                  if (v != _passwordController.text) {
                    return 'Hindi magkatugma ang passwords';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // ── Register Button ──────────────────────────────────────
              ElevatedButton(
                onPressed: _isSaving ? null : _register,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  disabledBackgroundColor:
                      AppColors.philippineBlue.withOpacity(0.5),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Mag-Sign Up!',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),

              const SizedBox(height: 16),

              // ── Login Link ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('May account ka na? ',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.pin, extra: false),
                    child: const Text('Mag-login',
                        style: TextStyle(
                            color: AppColors.philippineBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🐷', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('IponKo',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.philippineBlue)),
                Text('Mag-ipon tayo!',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Gumawa ng Account',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        const Text('Libre at walang kailangan na bank account.',
            style: TextStyle(
                fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── Role Selector ─────────────────────────────────────────────────────────────

class _RoleSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _RoleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            emoji: '🎒',
            title: 'Student',
            subtitle: 'Para sa mag-aaral',
            isSelected: selected == 'student',
            onTap: () => onChanged('student'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleCard(
            emoji: '👨‍👩‍👧',
            title: 'Magulang',
            subtitle: 'Para sa parent/guardian',
            isSelected: selected == 'parent',
            onTap: () => onChanged('parent'),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.philippineBlue : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.philippineBlue
                : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.philippineBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? Colors.white70
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Field Label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final String sublabel;
  const _FieldLabel({required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(width: 6),
        Text(sublabel,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
