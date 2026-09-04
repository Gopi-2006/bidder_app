import 'package:flutter/material.dart';
import '../core/design_system.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Government-Grade Status Badge
/// Accessible, WCAG-compliant, never communicates state through color alone.
/// Always pairs: Icon + Text Label + Accessible Background + Clear Context
/// ─────────────────────────────────────────────────────────────────────────────

enum GovStatusType {
  pass,
  fail,
  review,
  verified,
  pending,
  submitted,
  inProgress,
  decided,
  statutory,
  financial,
  technical,
  neutral,
}

class StatusBadge extends StatelessWidget {
  final String? status;
  final GovStatusType? type;
  final String? customLabel;
  final bool compact;

  const StatusBadge({
    super.key,
    this.status,
    this.type,
    this.customLabel,
    this.compact = false,
  });

  factory StatusBadge.pass({String? label, bool compact = false}) {
    return StatusBadge(type: GovStatusType.pass, customLabel: label, compact: compact);
  }

  factory StatusBadge.fail({String? label, bool compact = false}) {
    return StatusBadge(type: GovStatusType.fail, customLabel: label, compact: compact);
  }

  factory StatusBadge.review({String? label, bool compact = false}) {
    return StatusBadge(type: GovStatusType.review, customLabel: label, compact: compact);
  }

  factory StatusBadge.verified({String? label, bool compact = false}) {
    return StatusBadge(type: GovStatusType.verified, customLabel: label, compact: compact);
  }

  factory StatusBadge.pending({String? label, bool compact = false}) {
    return StatusBadge(type: GovStatusType.pending, customLabel: label, compact: compact);
  }

  GovStatusType _resolveType() {
    if (type != null) return type!;
    final normalized = (status ?? '').trim().toUpperCase();
    switch (normalized) {
      case 'PASS':
      case 'COMPLIANT':
        return GovStatusType.pass;
      case 'FAIL':
      case 'REJECTED':
      case 'ACTION_REQUIRED':
        return GovStatusType.fail;
      case 'REVIEW':
      case 'NEEDS_REVIEW':
      case 'REVIEW_NEEDED':
        return GovStatusType.review;
      case 'VERIFIED':
      case 'ACTIVE':
        return GovStatusType.verified;
      case 'SUBMITTED':
        return GovStatusType.submitted;
      case 'IN_PROGRESS':
      case 'ANALYZING':
        return GovStatusType.inProgress;
      case 'DECIDED':
        return GovStatusType.decided;
      case 'STATUTORY':
        return GovStatusType.statutory;
      case 'FINANCIAL':
        return GovStatusType.financial;
      case 'TECHNICAL':
        return GovStatusType.technical;
      case 'PENDING':
      default:
        return GovStatusType.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveType();

    Color bg;
    Color border;
    Color text;
    IconData icon;
    String label;

    switch (resolved) {
      case GovStatusType.pass:
        bg = AppColors.successBg;
        border = AppColors.successBorder;
        text = AppColors.success;
        icon = Icons.check_circle_rounded;
        label = customLabel ?? 'PASS';
        break;
      case GovStatusType.fail:
        bg = AppColors.errorBg;
        border = AppColors.errorBorder;
        text = AppColors.error;
        icon = Icons.cancel_rounded;
        label = customLabel ?? 'FAIL';
        break;
      case GovStatusType.review:
        bg = AppColors.warningBg;
        border = AppColors.warningBorder;
        text = AppColors.warning;
        icon = Icons.warning_amber_rounded;
        label = customLabel ?? 'REVIEW';
        break;
      case GovStatusType.verified:
        bg = AppColors.successBg;
        border = AppColors.successBorder;
        text = AppColors.success;
        icon = Icons.verified_rounded;
        label = customLabel ?? 'Verified';
        break;
      case GovStatusType.submitted:
        bg = const Color(0xFFE0F2FE);
        border = const Color(0xFF7DD3FC);
        text = const Color(0xFF0369A1);
        icon = Icons.task_alt_rounded;
        label = customLabel ?? 'SUBMITTED';
        break;
      case GovStatusType.inProgress:
        bg = AppColors.infoBg;
        border = AppColors.infoBorder;
        text = AppColors.info;
        icon = Icons.pending_rounded;
        label = customLabel ?? 'IN PROGRESS';
        break;
      case GovStatusType.decided:
        bg = const Color(0xFFFAF5FF);
        border = const Color(0xFFE9D5FF);
        text = const Color(0xFF7E22CE);
        icon = Icons.gavel_rounded;
        label = customLabel ?? 'DECIDED';
        break;
      case GovStatusType.statutory:
        bg = const Color(0xFFF1F5F9);
        border = const Color(0xFFCBD5E1);
        text = AppColors.primaryNavy;
        icon = Icons.account_balance_rounded;
        label = customLabel ?? 'STATUTORY';
        break;
      case GovStatusType.financial:
        bg = const Color(0xFFECFDF5);
        border = const Color(0xFFA7F3D0);
        text = const Color(0xFF047857);
        icon = Icons.currency_rupee_rounded;
        label = customLabel ?? 'FINANCIAL';
        break;
      case GovStatusType.technical:
        bg = const Color(0xFFEFF6FF);
        border = const Color(0xFFBFDBFE);
        text = const Color(0xFF1D4ED8);
        icon = Icons.memory_rounded;
        label = customLabel ?? 'TECHNICAL';
        break;
      case GovStatusType.pending:
      case GovStatusType.neutral:
        bg = const Color(0xFFF1F5F9);
        border = const Color(0xFFCBD5E1);
        text = AppColors.textMuted;
        icon = Icons.radio_button_unchecked_rounded;
        label = customLabel ?? 'Pending';
        break;
    }

    final double padH = compact ? 6.0 : 9.0;
    final double padV = compact ? 2.5 : 4.5;
    final double iconSize = compact ? 12.0 : 14.0;
    final double fontSize = compact ? 11.0 : 12.0;

    return Semantics(
      label: 'Status: $label',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: text),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: text,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
