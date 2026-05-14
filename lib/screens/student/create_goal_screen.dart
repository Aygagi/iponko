// lib/screens/student/create_goal_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../models/goal_model.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

const _uuid = Uuid();

// Emoji options for goal icons
const _goalEmojis = [
  '🎯',
  '👟',
  '📱',
  '💻',
  '🎮',
  '📚',
  '🎒',
  '✏️',
  '🍔',
  '🎵',
  '🏀',
  '⚽',
  '🎨',
  '✈️',
  '🎁',
  '💡',
  '🏠',
  '🚲',
  '📷',
  '🎤',
  '💄',
  '⌚',
  '🧸',
  '🌟',
];

class CreateGoalScreen extends ConsumerStatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedEmoji = '🎯';
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ── Computed: daily savings needed ───────────────────────────────────────
  double get _targetAmount =>
      double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

  int get _daysRemaining =>
      _targetDate.difference(DateTime.now()).inDays.clamp(1, 9999);

  double get _dailySavingsNeeded =>
      _targetAmount > 0 ? _targetAmount / _daysRemaining : 0;

  double get _weeklySavingsNeeded => _dailySavingsNeeded * 7;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      helpText: 'Piliin ang target date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.philippineBlue,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _saveGoal(String userId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final goal = GoalModel(
        id: _uuid.v4(),
        userId: userId,
        name: _nameController.text.trim(),
        targetAmount: _targetAmount,
        currentAmount: 0.0,
        targetDate: _targetDate,
        createdAt: DateTime.now(),
        status: 'active',
        emoji: _selectedEmoji,
        isSynced: false,
      );

      await ref.read(goalNotifierProvider(userId).notifier).addGoal(goal);
      ref.invalidate(goalsProvider(userId));

      if (mounted) _showSuccess(goal);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Hindi na-save. Subukan ulit.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccess(GoalModel goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _SuccessSheet(
        goal: goal,
        onDone: () {
          Navigator.of(context).pop();
          context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Hindi naka-login.')));
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Bagong Goal 🎯'),
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Emoji Picker ───────────────────────────────────────
                _SectionLabel(label: 'Piliin ang icon', sublabel: 'Icon'),
                const SizedBox(height: 12),
                _EmojiPicker(
                  selected: _selectedEmoji,
                  onChanged: (e) => setState(() => _selectedEmoji = e),
                ),

                const SizedBox(height: 24),

                // ── Goal Name ──────────────────────────────────────────
                _SectionLabel(label: 'Anong goal mo?', sublabel: 'Goal name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 40,
                  decoration: InputDecoration(
                    hintText: 'hal. Bagong Sapatos, iPad, Lakbay...',
                    counterText: '',
                    prefixText: '$_selectedEmoji  ',
                    prefixStyle: const TextStyle(fontSize: 16),
                  ),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ilagay ang pangalan ng goal';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 24),

                // ── Target Amount ──────────────────────────────────────
                _SectionLabel(
                    label: 'Magkano ang kailangan?', sublabel: 'Target amount'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.philippineBlue,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₱ ',
                    prefixStyle: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.philippineBlue,
                    ),
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textHint.withOpacity(0.4),
                    ),
                    filled: true,
                    fillColor: AppColors.blueSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                          color: AppColors.philippineBlue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ilagay ang halaga';
                    final amount = double.tryParse(v.replaceAll(',', ''));
                    if (amount == null || amount <= 0) {
                      return 'Dapat higit sa ₱0';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 24),

                // ── Target Date ────────────────────────────────────────
                _SectionLabel(
                    label: 'Kailan mo gusto?', sublabel: 'Target date'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            color: AppColors.philippineBlue, size: 22),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormatter.full(_targetDate),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: AppColors.textPrimary),
                            ),
                            Text(
                              '$_daysRemaining araw mula ngayon',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textHint),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Auto Calculator ────────────────────────────────────
                if (_targetAmount > 0) ...[
                  _SavingsCalculator(
                    targetAmount: _targetAmount,
                    daysRemaining: _daysRemaining,
                    dailyNeeded: _dailySavingsNeeded,
                    weeklyNeeded: _weeklySavingsNeeded,
                    goalName: _nameController.text.trim().isEmpty
                        ? 'goal mo'
                        : _nameController.text.trim(),
                    emoji: _selectedEmoji,
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Save Button ────────────────────────────────────────
                ElevatedButton(
                  onPressed: _isSaving ? null : () => _saveGoal(user.id),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: AppColors.philippineBlue,
                    disabledBackgroundColor:
                        AppColors.philippineBlue.withOpacity(0.5),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flag_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Gawa na ang Goal!',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                          ],
                        ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final String sublabel;
  const _SectionLabel({required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        Text(sublabel,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── Emoji Picker ──────────────────────────────────────────────────────────────

class _EmojiPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _EmojiPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: _goalEmojis.length,
        itemBuilder: (_, i) {
          final emoji = _goalEmojis[i];
          final isSelected = emoji == selected;
          return GestureDetector(
            onTap: () => onChanged(emoji),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.philippineBlue
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.philippineBlue
                      : Colors.transparent,
                ),
              ),
              child: Center(
                child: Text(emoji,
                    style: TextStyle(fontSize: isSelected ? 22 : 20)),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Savings Calculator Card ───────────────────────────────────────────────────

class _SavingsCalculator extends StatelessWidget {
  final double targetAmount;
  final int daysRemaining;
  final double dailyNeeded;
  final double weeklyNeeded;
  final String goalName;
  final String emoji;

  const _SavingsCalculator({
    required this.targetAmount,
    required this.daysRemaining,
    required this.dailyNeeded,
    required this.weeklyNeeded,
    required this.goalName,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final isAchievable = dailyNeeded <= 500;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAchievable
              ? [AppColors.successSurface, const Color(0xFFD1FAE5)]
              : [
                  AppColors.yellowSurface,
                  AppColors.yellowLight.withOpacity(0.3)
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAchievable
              ? AppColors.success.withOpacity(0.3)
              : AppColors.philippineYellow,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(isAchievable ? '📊' : '💪',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text('Auto-Kalkula',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Para maabot ang $emoji $goalName:',
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CalcChip(
                  label: 'Bawat araw',
                  amount: dailyNeeded,
                  icon: '📅',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CalcChip(
                  label: 'Bawat linggo',
                  amount: weeklyNeeded,
                  icon: '🗓️',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(isAchievable ? '✅' : '⚠️',
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAchievable
                        ? 'Kaya mo yan! Mag-ipon ng ${PesoFormatter.format(dailyNeeded)} bawat araw.'
                        : 'Medyo malaki. Subukan mo palawigin ang target date.',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalcChip extends StatelessWidget {
  final String label;
  final double amount;
  final String icon;

  const _CalcChip({
    required this.label,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$icon $label',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 3),
          Text(
            PesoFormatter.format(amount),
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.philippineBlue),
          ),
        ],
      ),
    );
  }
}

// ── Success Bottom Sheet ──────────────────────────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback onDone;

  const _SuccessSheet({required this.goal, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(goal.emoji ?? '🎯', style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Goal created!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(
            goal.name,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.philippineBlue),
          ),
          const SizedBox(height: 8),
          Text(
            'Target: ${PesoFormatter.format(goal.targetAmount)}',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          Text(
            'Deadline: ${DateFormatter.full(goal.targetDate)}',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'Simulan na mag-ipon para sa goal na ito! 💪',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.philippineBlue,
            ),
            child: const Text('Bumalik sa Dashboard',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
