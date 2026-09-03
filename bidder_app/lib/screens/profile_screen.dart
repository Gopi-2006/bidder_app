import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/firebase/auth_service.dart';
import '../core/api_service.dart';
import '../models/tender_models.dart';
import 'login_screen.dart';

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
    final prof = await ApiService.fetchMeProfile();
    setState(() {
      _profile = prof;
      _isLoading = false;
    });
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
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
    final companyName = _profile?.companyName ?? FirebaseAuthService.currentCompanyName;
    final gstin = _profile?.gstin ?? '29ABCDE1234F1Z5';
    final email = user?.email ?? _profile?.email ?? 'tender.desk@bharatnetworks.in';
    final uid = FirebaseAuthService.currentUid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Profile & Credentials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: GemTheme.saffron))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Card Header
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: GemTheme.primaryNavy.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.business_rounded, color: GemTheme.primaryNavy, size: 32),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  companyName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: GemTheme.primaryNavy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Role: PUBLIC_BIDDER',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Government Registry Credentials Card
                  const Text(
                    'Government Registry Identifiers',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildProfileRow(
                            icon: Icons.receipt_long_outlined,
                            label: 'GSTIN Registration',
                            value: gstin,
                            verified: true,
                          ),
                          const Divider(height: 20),
                          _buildProfileRow(
                            icon: Icons.credit_card_outlined,
                            label: 'Company PAN',
                            value: 'AAACB1234F',
                            verified: true,
                          ),
                          const Divider(height: 20),
                          _buildProfileRow(
                            icon: Icons.workspace_premium_outlined,
                            label: 'Udyam MSME Number',
                            value: 'UDYAM-KR-03-0012345',
                            verified: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Platform Security & Architecture
                  const Text(
                    'Security & Trust Architecture',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildProfileRow(
                            icon: Icons.fingerprint,
                            label: 'Firebase Auth UID',
                            value: uid,
                            verified: null,
                          ),
                          const Divider(height: 20),
                          _buildProfileRow(
                            icon: Icons.cloud_done_outlined,
                            label: 'Google Drive Storage',
                            value: 'GEM-COMPLIANCE Active Vault',
                            verified: true,
                          ),
                          const Divider(height: 20),
                          _buildProfileRow(
                            icon: Icons.lock_clock_outlined,
                            label: 'Rule Engine Evaluation',
                            value: 'Deterministic Engine v1.0.0',
                            verified: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
                      label: const Text(
                        'Sign Out from GeM Portal',
                        style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
    required bool? verified,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ),
        if (verified != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: verified ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              verified ? 'VERIFIED' : 'PENDING',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: verified ? const Color(0xFF166534) : const Color(0xFF92400E),
              ),
            ),
          ),
      ],
    );
  }
}
