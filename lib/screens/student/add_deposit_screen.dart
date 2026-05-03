// lib/screens/student/add_deposit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../models/deposit_model.dart';
import '../../models/goal_model.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

const _uuid = Uuid();

class AddDepositScreen extends ConsumerStatefulWidget {
  final String? preselectedGoalId;
  const AddDepositScreen({super.key, this.preselectedGoalId});

  @override
  ConsumerState<AddDepositScreen> createState() => _AddDepositScreenState();
}

class _AddDepositScreenState extends ConsumerState<AddDepositScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedSource = 'baon';
  String? _selectedGoalId;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  // Source options with emoji + Filipino label
  final _sources = [
    {'value': 'baon',      'label': 'Baon',       'emoji': '🍱'},
    {'value': 'allowance', 'label': 'Allowance',   'emoji': '💵'},
    {'value': 'gift',      'label': 'Regalo/Gift', 'emoji': '🎁'},
    {'value': 'other',     'label': 'Iba pa',      'emoji': '💰'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedGoalId = widget.preselectedGoalId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.philippineBlue,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveDeposit(String userId) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(
        _amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      _showError('Ilagay ang tamang halaga.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final deposit = DepositModel(
        id: _uuid.v4(),
        userId: userId,
        goalId: _selectedGoalId,
        amount: amount,
        source: _selectedSource,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        isApprovedByParent: false,
        isSynced: false,
        createdAt: DateTime.now(),
      );

      // Save via notifier — auto-refreshes dashboard
      await ref
          .read(depositNotifierProvider(userId).notifier)
          .addDeposit(deposit);

      // Invalidate all dashboard providers so they reload
      ref.invalidate(totalBalanceProvider(userId));
      ref.invalidate(recentDepositsProvider(userId));
      ref.invalidate(streakProvider(userId));
      if (_selectedGoalId != null) {
        ref.invalidate(goalsProvider(userId));
      }

      if (mounted) {
        _showSuccess(amount);
      }
    } catch (e) {
      if (mounted) _showError('Hindi na-save. Subukan ulit.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccess(double amount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _SuccessSheet(
        amount: amount,
        onDone: () {
          Navigator.of(context).pop(); // close sheet
          context.pop(); // go back to dashboard
        },
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(
              body: Center(child: Text('Hindi naka-login.')));
        }

        final goalsAsync = ref.watch(goalsProvider(user.id));

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Mag-ipon! 💰'),
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
                // ── Amount Input ─────────────────────────────────────
                _SectionLabel(label: 'Magkano?', sublabel: 'Amount'),
                const SizedBox(height: 8),
                _AmountField(controller: _amountController),

                const SizedBox(height: 24),

                // ── Source Selector ──────────────────────────────────
                _SectionLabel(label: 'Saan galing?', sublabel: 'Source'),
                const SizedBox(height: 8),
                _SourceSelector(
                  sources: _sources,
                  selected: _selectedSource,
                  onChanged: (v) => setState(() => _selectedSource = v),
                ),

                const SizedBox(height: 24),

                // ── Goal Selector ────────────────────────────────────
                _SectionLabel(
                    label: 'Para sa anong goal?',
                    sublabel: 'Goal (optional)'),
                const SizedBox(height: 8),
                goalsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (goals) {
                    final active =
                        goals.where((g) => g.status == 'active').toList();
                    return _GoalSelector(
                      goals: active,
                      selectedGoalId: _selectedGoalId,
                      onChanged: (id) =>
                          setState(() => _selectedGoalId = id),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ── Date Picker ──────────────────────────────────────
                _SectionLabel(label: 'Kailan?', sublabel: 'Date'),
                const SizedBox(height: 8),
                _DatePickerTile(
                  date: _selectedDate,
                  onTap: _pickDate,
                ),

                const SizedBox(height: 24),

                // ── Note Field ───────────────────────────────────────
                _SectionLabel(
                    label: 'Anong okasyon? (optional)',
                    sublabel: 'Note'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    hintText: 'hal. Baon ko ngayon, Kaarawan gift...',
                    counterText: '',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),

                const SizedBox(height: 36),

                // ── Save Button ──────────────────────────────────────
                ElevatedButton(
                  onPressed: _isSaving ? null : () => _saveDeposit(user.id),
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
                            Icon(Icons.savings_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('I-save ang Ipon!',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
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

// ── Section Label ────────────────────────────────────────────────────────────

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
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── Amount Field ─────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  const _AmountField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.philippineBlue,
      ),
      decoration: InputDecoration(
        prefixText: '₱ ',
        prefixStyle: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.philippineBlue,
        ),
        hintText: '0.00',
        hintStyle: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textHint.withOpacity(0.5),
        ),
        filled: true,
        fillColor: AppColors.blueSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.philippineBlue, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      autofocus: true,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ilagay ang halaga';
        final amount = double.tryParse(v.replaceAll(',', ''));
        if (amount == null || amount <= 0) return 'Dapat higit sa ₱0';
        return null;
      },
    );
  }
}

// ── Source Selector ──────────────────────────────────────────────────────────

class _SourceSelector extends StatelessWidget {
  final List<Map<String, String>> sources;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SourceSelector({
    required this.sources,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: sources.map((s) {
        final isSelected = s['value'] == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(s['value']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.philippineBlue
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.philippineBlue
                      : AppColors.divider,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.philippineBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Text(s['emoji']!,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    s['label']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Goal Selector ────────────────────────────────────────────────────────────

class _GoalSelector extends StatelessWidget {
  final List<GoalModel> goals;
  final String? selectedGoalId;
  final ValueChanged<String?> onChanged;

  const _GoalSelector({
    required this.goals,
    required this.selectedGoalId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Row(
          children: [
            Text('🎯', style: TextStyle(fontSize: 20)),
            SizedBox(width: 10),
            Text('Wala pang goals. Gumawa muna ng goal!',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // "No specific goal" option
        _GoalOption(
          emoji: '💼',
          name: 'General Savings',
          sublabel: 'Walang specific na goal',
          isSelected: selectedGoalId == null,
          onTap: () => onChanged(null),
        ),
        const SizedBox(height: 8),
        ...goals.map((g) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _GoalOption(
                emoji: g.emoji ?? '🎯',
                name: g.name,
                sublabel:
                    '${PesoFormatter.format(g.remainingAmount)} pa kulang',
                isSelected: selectedGoalId == g.id,
                onTap: () => onChanged(g.id),
                progress: g.progressPercent,
              ),
            )),
      ],
    );
  }
}

class _GoalOption extends StatelessWidget {
  final String emoji;
  final String name;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;
  final double? progress;

  const _GoalOption({
    required this.emoji,
    required this.name,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blueSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.philippineBlue
                : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isSelected
                              ? AppColors.philippineBlue
                              : AppColors.textPrimary)),
                  Text(sublabel,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
                  if (progress != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: AppColors.divider,
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.philippineBlue),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.philippineBlue, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Date Picker Tile ─────────────────────────────────────────────────────────

class _DatePickerTile extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerTile({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isToday = DateFormatter.relative(date) == 'Today';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: AppColors.philippineBlue, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormatter.full(date),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                ),
                if (isToday)
                  const Text('Ngayon',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.philippineBlue,
                          fontWeight: FontWeight.w500)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ── Success Bottom Sheet ──────────────────────────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  final double amount;
  final VoidCallback onDone;

  const _SuccessSheet({required this.amount, required this.onDone});

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
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),

          const Text(
            'Na-save ang ipon mo!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),

          Text(
            '+${PesoFormatter.format(amount)}',
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.success),
          ),
          const SizedBox(height: 8),

          const Text(
            'Magaling! Patuloy lang mag-ipon! 💪',
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
