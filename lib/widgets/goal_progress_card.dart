// lib/widgets/goal_progress_card.dart

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/goal_model.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class GoalProgressCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback? onTap;

  const GoalProgressCard({super.key, required this.goal, this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = goal.progressPercent;
    final isNearComplete = progress >= 0.8;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(goal.emoji ?? '🎯', style: const TextStyle(fontSize: 24)),
                const Spacer(),
                if (isNearComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Almost!',
                        style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              goal.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              PesoFormatter.format(goal.currentAmount),
              style: const TextStyle(
                  color: AppColors.philippineBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 15),
            ),
            Text(
              'of ${PesoFormatter.format(goal.targetAmount)}',
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 11),
            ),
            const SizedBox(height: 10),
            LinearPercentIndicator(
              percent: progress,
              lineHeight: 8,
              backgroundColor: AppColors.blueSurface,
              progressColor: isNearComplete
                  ? AppColors.success
                  : AppColors.philippineBlue,
              barRadius: const Radius.circular(8),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 6),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% • ${goal.daysRemaining}d left',
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
