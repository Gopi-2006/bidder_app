import 'package:flutter/material.dart';
import '../core/design_system.dart';
import 'gov_card.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AI Compliance Readiness Score Visualizer
/// Positioned as an official automated pre-submission compliance engine
/// ─────────────────────────────────────────────────────────────────────────────

class ComplianceScoreRing extends StatelessWidget {
  final double score; // 0.0 to 1.0 (e.g. 0.92 = 92%)
  final double size;
  final double strokeWidth;

  const ComplianceScoreRing({
    super.key,
    required this.score,
    this.size = 110.0,
    this.strokeWidth = 10.0,
  });

  Color _resolveColor() {
    if (score >= 0.85) return AppColors.success;
    if (score >= 0.60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final percent = (score * 100).round();
    final activeColor = _resolveColor();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Track
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              color: AppColors.surfaceElevated,
            ),
          ),
          // Active Value Progress
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              color: activeColor,
            ),
          ),
          // Center Text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: size * 0.26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'COMPLIANCE',
                style: TextStyle(
                  fontSize: size * 0.09,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ComplianceSummaryCard extends StatelessWidget {
  final double score;
  final int passCount;
  final int reviewCount;
  final int failCount;
  final int totalCount;
  final VoidCallback? onReviewPressed;

  const ComplianceSummaryCard({
    super.key,
    required this.score,
    required this.passCount,
    required this.reviewCount,
    required this.failCount,
    required this.totalCount,
    this.onReviewPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isCompliant = score >= 0.85 && failCount == 0;

    return GovCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.infoBorder),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Compliance Analysis',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    Text(
                      'Automated pre-submission verification engine',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),

          // Ring + Summary Metrics
          Row(
            children: [
              ComplianceScoreRing(score: score),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompliant
                          ? 'High Compliance Readiness'
                          : reviewCount > 0
                              ? 'Verification Review Needed'
                              : 'Requirements Incomplete',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isCompliant ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$passCount of $totalCount mandatory requirements satisfied based on deterministic rules.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Mini Metric Blocks
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCount('Satisfied', '$passCount/$totalCount', AppColors.success),
                _buildDivider(),
                _buildCount('Needs Review', '$reviewCount', AppColors.warning),
                _buildDivider(),
                _buildCount('Action Req.', '$failCount', AppColors.error),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCount(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: AppColors.border,
    );
  }
}
