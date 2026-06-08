import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip(this.status, {super.key});

  Color get _color {
    switch (status) {
      case 'Completed':
      case 'Paid':
      case 'Verified':
        return AppColors.success;
      case 'Ongoing':
      case 'Submitted':
        return AppColors.primary;
      case 'Delayed':
      case 'Rejected':
        return AppColors.danger;
      case 'On Hold':
      case 'Draft':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _color,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
