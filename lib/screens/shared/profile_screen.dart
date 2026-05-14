// lib/screens/shared/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_router.dart';
import '../../utils/formatters.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isBilingual = false;

  Future<void> _loadLanguagePref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isBilingual = prefs.getBool('bilingual') ?? false);
  }

  Future<void> _toggleLanguage(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bilingual', val);
    setState(() => _isBilingual = val);
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mag-logout?'),
        content: const Text(
            'Mawawala ang iyong session. Kailangan mong mag-login ulit.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huwag'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mag-logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(repositoryProvider);
      await repo.clearUser();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('iponko_pin');
      if (context.mounted) context.go(AppRoutes.splash);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLanguagePref();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (user) {
        if (user == null) return const Scaffold(body: SizedBox.shrink());

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Profile & Settings'),
            centerTitle: false,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── Profile Card ─────────────────────────────────────
              _ProfileCard(user: user),

              const SizedBox(height: 20),

              // ── Account Settings ─────────────────────────────────
              _SettingsSection(
                title: 'Account',
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline_rounded,
                    label: 'I-edit ang Profile',
                    sublabel: 'Pangalan, school, grade level',
                    onTap: () => _showEditProfile(context, user),
                  ),
                  _SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Baguhin ang PIN',
                    sublabel: '4-digit PIN para sa quick login',
                    onTap: () =>
                        context.push(AppRoutes.pin, extra: true),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Preferences ──────────────────────────────────────
              _SettingsSection(
                title: 'Preferences',
                children: [
                  _SettingsSwitchTile(
                    icon: Icons.language_rounded,
                    label: 'Bilingual Mode',
                    sublabel: 'English + Filipino labels',
                    value: _isBilingual,
                    onChanged: _toggleLanguage,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── About ─────────────────────────────────────────────
              _SettingsSection(
                title: 'About',
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    label: 'IponKo',
                    sublabel: 'Version 1.0.0 — Integ 2 Final Project',
                    onTap: () {},
                    showArrow: false,
                  ),
                  _SettingsTile(
                    icon: Icons.code_rounded,
                    label: 'Developed by',
                    sublabel: 'Joshua & Jhed',
                    onTap: () {},
                    showArrow: false,
                  ),
                  _SettingsTile(
                    icon: Icons.school_outlined,
                    label: 'BSIT — AI & Robotics',
                    sublabel: 'Integ 2 Final Project',
                    onTap: () {},
                    showArrow: false,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Logout Button ────────────────────────────────────
              OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout_rounded,
                    color: AppColors.error),
                label: const Text('Mag-logout',
                    style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(
                      color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfile(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        user: user,
        onSave: (updated) async {
          final repo = ref.read(repositoryProvider);
          await repo.saveUser(updated);
          ref.invalidate(currentUserProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Na-update ang profile! ✅'),
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
      ),
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final UserModel user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.philippineBlue, AppColors.blueLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.philippineYellow,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'I',
              style: const TextStyle(
                  color: AppColors.philippineBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                Text(user.email,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _RoleChip(
                        label: user.isStudent ? '🎒 Student' : '👨‍👩‍👧 Parent'),
                    if (user.school != null) ...[
                      const SizedBox(width: 8),
                      _RoleChip(label: '🏫 ${user.school}'),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  const _RoleChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ── Settings Section ──────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection(
      {required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            children: children
                .asMap()
                .entries
                .map((e) => Column(
                      children: [
                        e.value,
                        if (e.key < children.length - 1)
                          const Divider(
                              height: 1,
                              indent: 56,
                              color: AppColors.divider),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ── Settings Tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  final bool showArrow;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.blueSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.philippineBlue, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary)),
      subtitle: Text(sublabel,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary)),
      trailing: showArrow
          ? const Icon(Icons.chevron_right_rounded,
              color: AppColors.textHint)
          : null,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.blueSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.philippineBlue, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary)),
      subtitle: Text(sublabel,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.philippineBlue,
      ),
    );
  }
}

// ── Edit Profile Bottom Sheet ─────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final UserModel user;
  final ValueChanged<UserModel> onSave;

  const _EditProfileSheet({required this.user, required this.onSave});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _schoolController;
  int? _gradeLevel;
  bool _isSaving = false;

  final _grades = List.generate(12, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.user.name);
    _schoolController =
        TextEditingController(text: widget.user.school ?? '');
    _gradeLevel = widget.user.gradeLevel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('I-edit ang Profile',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),

            const Text('Pangalan',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Buong pangalan',
                prefixIcon: Icon(Icons.person_outline_rounded,
                    color: AppColors.philippineBlue),
              ),
            ),
            const SizedBox(height: 14),

            const Text('Paaralan',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _schoolController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Pangalan ng paaralan (optional)',
                prefixIcon: Icon(Icons.school_outlined,
                    color: AppColors.philippineBlue),
              ),
            ),

            if (widget.user.isStudent) ...[
              const SizedBox(height: 14),
              const Text('Grade Level',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _gradeLevel,
                decoration: const InputDecoration(
                  hintText: 'Piliin ang grade',
                  prefixIcon: Icon(Icons.grade_outlined,
                      color: AppColors.philippineBlue),
                ),
                items: _grades
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g <= 6
                              ? 'Grade $g'
                              : g <= 10
                                  ? 'Grade $g (JHS)'
                                  : 'Grade $g (SHS)'),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _gradeLevel = v),
              ),
            ],

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      final updated = UserModel(
                        id: widget.user.id,
                        name: _nameController.text.trim(),
                        email: widget.user.email,
                        role: widget.user.role,
                        school: _schoolController.text.trim().isEmpty
                            ? null
                            : _schoolController.text.trim(),
                        gradeLevel: _gradeLevel,
                        linkedChildId: widget.user.linkedChildId,
                        linkedParentId: widget.user.linkedParentId,
                        createdAt: widget.user.createdAt,
                        isSynced: false,
                      );
                      widget.onSave(updated);
                      setState(() => _isSaving = false);
                      if (context.mounted) Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52)),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('I-save',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
