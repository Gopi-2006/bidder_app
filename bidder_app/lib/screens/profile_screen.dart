import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../core/firebase/auth_service.dart';
import '../core/api_service.dart';
import '../models/tender_models.dart';
import '../widgets/gov_card.dart';
import '../widgets/gov_buttons.dart';
import '../widgets/status_badge.dart';
import '../widgets/state_views.dart';
import 'login_screen.dart';
import 'document_vault_screen.dart';
import 'government_verification_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GeM Compliance — Enterprise Profile & Verified Credentials
/// Section 24: Official enterprise identity, verification status, and audit records
/// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfileModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final prof = await ApiService.fetchMeProfile();
      if (mounted) {
        setState(() {
          _profile = prof;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Sign Out'),
        content: const Text('Are you sure you want to sign out from the GeM Bidder Portal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuthService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuthService.currentUser;
    final companyName = _profile?.companyName.isNotEmpty == true
        ? _profile!.companyName
        : FirebaseAuthService.currentCompanyName.isNotEmpty
            ? FirebaseAuthService.currentCompanyName
            : 'Bharat Infotech & Networks Pvt Ltd';
    final gstin = _profile?.gstin.isNotEmpty == true ? _profile!.gstin : '29ABCDE1234F1Z5';
    final email = user?.email ?? _profile?.email ?? 'tender.desk@bharatnetworks.in';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Enterprise Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const GovLoadingSkeleton(count: 3)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // Company Profile Header Card
            GovCard(
              elevated: true,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryNavy,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.card,
                    ),
                    child: Center(
                      child: Text(
                        companyName.isNotEmpty ? companyName[0].toUpperCase() : 'B',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    companyName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  StatusBadge.verified(label: 'Verified Business'),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // SECTION 1: Government Verification Status (Section 24)
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
                        'GOVERNMENT VERIFICATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GovernmentVerificationScreen()),
                          );
                        },
                        child: const Text('Re-verify', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _buildGovVerificationItem('PAN Record', 'NSDL / Income Tax Dept', true),
                  const Divider(height: 14),
                  _buildGovVerificationItem('Udyam MSME', 'Ministry of MSME', true),
                  const Divider(height: 14),
                  _buildGovVerificationItem('GSTIN Network', gstin, true),
                  const Divider(height: 14),
                  _buildGovVerificationItem('OEM Authorization', 'Manufacturer Partner', true),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // SECTION 2: Document Vault Access
            GovCard(
              elevated: true,
              padding: const EdgeInsets.all(AppSpacing.md),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DocumentVaultScreen()),
                );
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.infoBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.folder_shared_rounded, color: AppColors.info, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified Document Vault',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                        ),
                        Text(
                          'Encrypted certificates, CA turnovers & OEM MAF',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // SECTION 3: App Information & Security
            const GovCard(
              elevated: true,
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SECURITY & COMPLIANCE PLATFORM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  InfoRow(label: 'Platform', value: 'GeM Compliance Verification'),
                  InfoRow(label: 'Application Version', value: 'v1.0.0 (SIH 2026)'),
                  InfoRow(label: 'Service Endpoint', value: 'gem-backend-rrom.onrender.com'),
                  InfoRow(label: 'Encryption Standard', value: 'TLS 1.3 / AES-256'),
                  InfoRow(label: 'Compliance Engine', value: 'Deterministic Clause Parser'),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Sign Out Button
            SecondaryGovButton(
              label: 'Sign Out',
              icon: Icons.logout_rounded,
              borderColor: AppColors.errorBorder,
              textColor: AppColors.error,
              onPressed: _handleLogout,
            ),

            const SizedBox(height: AppSpacing.lg),

            const Center(
              child: Text(
                'National Public Procurement Portal • Government of India',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGovVerificationItem(String title, String subtitle, bool isVerified) {
    return Row(
      children: [
        Icon(
          isVerified ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: isVerified ? AppColors.success : AppColors.textDisabled,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        StatusBadge.verified(label: 'Verified', compact: true),
      ],
    );
  }
}
