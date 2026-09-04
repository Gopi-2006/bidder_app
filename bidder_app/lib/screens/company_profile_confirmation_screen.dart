import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../widgets/gov_card.dart';
import '../widgets/gov_buttons.dart';
import '../widgets/status_badge.dart';
import '../widgets/state_views.dart';
import 'main_shell.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GeM Compliance — Final Business Verified Screen
/// Section 10: Official government verification completion
/// ─────────────────────────────────────────────────────────────────────────────

class CompanyProfileConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> company;
  final Map<String, dynamic> governmentDetails;

  const CompanyProfileConfirmationScreen({
    super.key,
    required this.company,
    required this.governmentDetails,
  });

  @override
  Widget build(BuildContext context) {
    final panData = governmentDetails['pan'] as Map<String, dynamic>? ?? {};
    final gstData = governmentDetails['gst'] as Map<String, dynamic>? ?? {};
    final udyamData = governmentDetails['udyam'] as Map<String, dynamic>? ?? {};
    final oemData = governmentDetails['oem'] as Map<String, dynamic>? ?? {};

    final companyName = company['name'] ?? panData['company_name'] ?? 'Nexora Technologies Pvt. Ltd.';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Business Verification Complete'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Large Official Success Icon & Title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.successBorder, width: 2),
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            size: 46,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Text(
                          'Business Successfully Verified',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryNavy,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'All submitted business credentials have been cross-checked successfully against official records.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Government Credentials Verified Checklist
                  GovCard(
                    elevated: true,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VERIFIED GOVERNMENT CREDENTIALS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMuted,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildVerificationRow(
                          title: 'PAN Record',
                          identifier: panData['pan_number'] ?? 'Permanent Account Number',
                          status: 'Verified',
                        ),
                        const Divider(height: 16),
                        _buildVerificationRow(
                          title: 'Udyam Registration',
                          identifier: udyamData['udyam_number'] ?? 'MSME Enterprise',
                          status: 'Verified',
                        ),
                        const Divider(height: 16),
                        _buildVerificationRow(
                          title: 'GSTIN Identifier',
                          identifier: gstData['gstin'] ?? 'GST Network Active',
                          status: 'Verified',
                        ),
                        const Divider(height: 16),
                        _buildVerificationRow(
                          title: 'OEM Authorization',
                          identifier: oemData['oem_authorization_number'] ?? 'Authorized Vendor',
                          status: 'Verified',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Registered Business Details Card
                  GovCard(
                    elevated: true,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'REGISTERED ENTERPRISE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMuted,
                                letterSpacing: 0.6,
                              ),
                            ),
                            StatusBadge.verified(label: 'Active & Verified', compact: true),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          companyName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        InfoRow(label: 'Registration Type', value: udyamData['enterprise_type'] ?? 'Medium Enterprise'),
                        InfoRow(label: 'Jurisdiction State', value: gstData['state_jurisdiction'] ?? 'Maharashtra'),
                        const InfoRow(label: 'Audit Status', value: 'Government Verified', valueColor: AppColors.success),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Primary Button
                  PrimaryGovButton(
                    label: 'Continue to GeM Compliance',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainShellScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationRow({
    required String title,
    required String identifier,
    required String status,
  }) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                identifier,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        StatusBadge.verified(label: status, compact: true),
      ],
    );
  }
}
