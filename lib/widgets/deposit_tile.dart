// lib/widgets/deposit_tile.dart

import 'package:flutter/material.dart';
import '../models/deposit_model.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class DepositTile extends StatelessWidget {
  final DepositModel deposit;

  const DepositTile({super.key, required this.deposit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Source icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.blueSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(_sourceEmoji(deposit.source),
                  style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          // Source label + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deposit.sourceLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                ),
                if (deposit.note != null && deposit.note!.isNotEmpty)
                  Text(
                    deposit.note!,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    DateFormatter.relative(deposit.date),
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 12),
                  ),
              ],
            ),
          ),
          // Amount + approval status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${PesoFormatter.format(deposit.amount)}',
                style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
              if (!deposit.isApprovedByParent)
                const Text('Pending ⏳',
                    style: TextStyle(
                        color: AppColors.warning, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  String _sourceEmoji(String source) {
    switch (source) {
      case 'allowance': return '💵';
      case 'baon': return '🍱';
      case 'gift': return '🎁';
      default: return '💰';
    }
  }
}


// lib/widgets/streak_banner.dart — in same file for brevity
// (move to separate file if you prefer)

class StreakBanner extends StatelessWidget {
  final int streak;
  const StreakBanner({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3CD), Color(0xFFFFE082)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.philippineYellow, width: 1.5),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak-Day Streak!',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary),
                ),
                Text(
                  streak >= 7
                      ? 'Kahanga-hanga! Keep it up! 💪'
                      : 'Nag-ipon ka ng $streak araw sunod-sunod!',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
