import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../core/api_service.dart';
import '../widgets/gov_card.dart';
import '../widgets/gov_buttons.dart';
import '../widgets/status_badge.dart';
import '../widgets/state_views.dart';
import 'company_profile_confirmation_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GeM Compliance — Government Business Verification
/// Sections 7, 8, 9: Step-based official cross-check (PAN -> UDYAM -> GST -> OEM)
/// ─────────────────────────────────────────────────────────────────────────────

enum VerificationStep { pan, udyam, gst, oem, finalized }

class GovernmentVerificationScreen extends StatefulWidget {
  const GovernmentVerificationScreen({super.key});

  @override
  State<GovernmentVerificationScreen> createState() => _GovernmentVerificationScreenState();
}

class _GovernmentVerificationScreenState extends State<GovernmentVerificationScreen> {
  final _formKey = GlobalKey<FormState>();

  VerificationStep _currentStep = VerificationStep.pan;

  // Controllers
  final _panController = TextEditingController(text: "ABCDE1234F");
  final _panPinController = TextEditingController(text: "123456");

  final _udyamController = TextEditingController(text: "UDYAM-MH-01-0000001");
  final _udyamPinController = TextEditingController(text: "123456");

  final _gstController = TextEditingController(text: "22AAAAA1234A1Z5");
  final _gstPinController = TextEditingController(text: "123456");

  final _oemController = TextEditingController(text: "OEM-MH-2026-001");
  final _oemPinController = TextEditingController(text: "123456");

  bool _obscurePin = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Verified Document Payloads
  Map<String, dynamic>? _verifiedPan;
  Map<String, dynamic>? _verifiedUdyam;
  Map<String, dynamic>? _verifiedGst;
  Map<String, dynamic>? _verifiedOem;

  @override
  void dispose() {
    _panController.dispose();
    _panPinController.dispose();
    _udyamController.dispose();
    _udyamPinController.dispose();
    _gstController.dispose();
    _gstPinController.dispose();
    _oemController.dispose();
    _oemPinController.dispose();
    super.dispose();
  }

  void _fillSampleNexora() {
    setState(() {
      _panController.text = "ABCDE1234F";
      _panPinController.text = "123456";
      _udyamController.text = "UDYAM-MH-01-0000001";
      _udyamPinController.text = "123456";
      _gstController.text = "22AAAAA1234A1Z5";
      _gstPinController.text = "123456";
      _oemController.text = "OEM-MH-2026-001";
      _oemPinController.text = "123456";
      _errorMessage = null;
    });
  }

  void _fillSampleBluePeak() {
    setState(() {
      _panController.text = "BCDEF2345G";
      _panPinController.text = "123456";
      _udyamController.text = "UDYAM-KA-02-0000002";
      _udyamPinController.text = "123456";
      _gstController.text = "22BBBBB2345B1Z6";
      _gstPinController.text = "123456";
      _oemController.text = "OEM-KA-2026-002";
      _oemPinController.text = "123456";
      _errorMessage = null;
    });
  }

  Future<void> _verifyPan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final res = await ApiService.verifyPanStep(
        panNumber: _panController.text.trim(),
        pin: _panPinController.text.trim(),
      );

      if (!mounted) return;
      if (res['success'] == true) {
        setState(() {
          _verifiedPan = res['details'];
          _errorMessage = null;
        });
      } else {
        setState(() { _errorMessage = res['message'] ?? 'PAN verification failed. Check credentials.'; });
      }
    } catch (_) {
      setState(() { _errorMessage = 'Unable to connect to government records. Please check your connection.'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyUdyam() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final res = await ApiService.verifyUdyamStep(
        udyamNumber: _udyamController.text.trim(),
        pin: _udyamPinController.text.trim(),
      );

      if (!mounted) return;
      if (res['success'] == true) {
        setState(() {
          _verifiedUdyam = res['details'];
          _errorMessage = null;
        });
      } else {
        setState(() { _errorMessage = res['message'] ?? 'Udyam verification failed.'; });
      }
    } catch (_) {
      setState(() { _errorMessage = 'Unable to connect to government records. Please check your connection.'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyGst() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final res = await ApiService.verifyGstStep(
        gstNumber: _gstController.text.trim(),
        pin: _gstPinController.text.trim(),
      );

      if (!mounted) return;
      if (res['success'] == true) {
        setState(() {
          _verifiedGst = res['details'];
          _errorMessage = null;
        });
      } else {
        setState(() { _errorMessage = res['message'] ?? 'GST verification failed.'; });
      }
    } catch (_) {
      setState(() { _errorMessage = 'Unable to connect to government records. Please check your connection.'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOem() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final res = await ApiService.verifyOemStep(
        oemAuthorizationNumber: _oemController.text.trim(),
        pin: _oemPinController.text.trim(),
      );

      if (!mounted) return;
      if (res['success'] == true) {
        setState(() {
          _verifiedOem = res['details'];
          _errorMessage = null;
        });
      } else {
        setState(() { _errorMessage = res['message'] ?? 'OEM authorization verification failed.'; });
      }
    } catch (_) {
      setState(() { _errorMessage = 'Unable to connect to government records. Please check your connection.'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _finalizeAll() async {
    if (_verifiedPan == null || _verifiedUdyam == null || _verifiedGst == null || _verifiedOem == null) {
      setState(() { _errorMessage = 'Please complete verification for all four documents.'; });
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final res = await ApiService.finalizeGovernmentVerification(
        pan: _verifiedPan!,
        udyam: _verifiedUdyam!,
        gst: _verifiedGst!,
        oem: _verifiedOem!,
      );

      if (!mounted) return;
      if (res['success'] == true) {
        final company = res['company'] as Map<String, dynamic>? ?? {};
        final govDetails = {
          'pan': _verifiedPan,
          'udyam': _verifiedUdyam,
          'gst': _verifiedGst,
          'oem': _verifiedOem,
        };

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CompanyProfileConfirmationScreen(
              company: company,
              governmentDetails: govDetails,
            ),
          ),
        );
      } else {
        setState(() { _errorMessage = res['message'] ?? 'Failed to finalize enterprise profile.'; });
      }
    } catch (_) {
      setState(() { _errorMessage = 'Service temporarily unavailable. Please try again.'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify Your Business'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Load Sample Records',
            icon: const Icon(Icons.dataset_rounded),
            onSelected: (val) {
              if (val == 'nexora') _fillSampleNexora();
              if (val == 'bluepeak') _fillSampleBluePeak();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'nexora', child: Text('Prefill: Nexora Tech Pvt Ltd')),
              PopupMenuItem(value: 'bluepeak', child: Text('Prefill: BluePeak Systems LLP')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    _buildHeaderBanner(),
                    const SizedBox(height: AppSpacing.lg),

                    // Progress Stepper Bar
                    _buildStepperBar(),
                    const SizedBox(height: AppSpacing.xl),

                    // Error Message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.errorBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(fontSize: 12, color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Current Step View
                    _buildStepContent(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return GovCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded, color: AppColors.primaryNavy, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify Your Business',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Confirm your registered business details before accessing tender applications.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperBar() {
    return GovCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _buildStepPill('PAN', VerificationStep.pan, _verifiedPan != null),
          _buildStepDivider(),
          _buildStepPill('UDYAM', VerificationStep.udyam, _verifiedUdyam != null),
          _buildStepDivider(),
          _buildStepPill('GST', VerificationStep.gst, _verifiedGst != null),
          _buildStepDivider(),
          _buildStepPill('OEM', VerificationStep.oem, _verifiedOem != null),
        ],
      ),
    );
  }

  Widget _buildStepPill(String label, VerificationStep step, bool isVerified) {
    final isCurrent = _currentStep == step;

    Color bg;
    Color text;
    IconData icon;

    if (isVerified) {
      bg = AppColors.successBg;
      text = AppColors.success;
      icon = Icons.check_circle_rounded;
    } else if (isCurrent) {
      bg = AppColors.primaryNavy;
      text = Colors.white;
      icon = Icons.radio_button_checked_rounded;
    } else {
      bg = AppColors.surfaceElevated;
      text = AppColors.textMuted;
      icon = Icons.radio_button_unchecked_rounded;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentStep = step;
            _errorMessage = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: text),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 14,
      height: 1,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case VerificationStep.pan:
        return _buildPanStep();
      case VerificationStep.udyam:
        return _buildUdyamStep();
      case VerificationStep.gst:
        return _buildGstStep();
      case VerificationStep.oem:
        return _buildOemStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: PAN
  Widget _buildPanStep() {
    final isVerified = _verifiedPan != null;

    return GovCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PAN Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
              if (isVerified)
                StatusBadge.verified(label: 'PAN Verified')
              else
                StatusBadge.pending(label: 'Step 1 of 4'),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Enter your registered Permanent Account Number (PAN).', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),

          if (!isVerified) ...[
            const Text('PAN Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _panController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'e.g. ABCDE1234F',
                prefixIcon: Icon(Icons.badge_rounded, size: 18),
              ),
              validator: (v) => (v == null || v.trim().length != 10) ? 'Enter valid 10-character PAN' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Verification PIN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _panPinController,
              obscureText: _obscurePin,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter 6-digit PIN',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter PIN' : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryGovButton(
              label: _isLoading ? 'Connecting to government records...' : 'Verify PAN',
              isLoading: _isLoading,
              icon: Icons.check_circle_outline_rounded,
              onPressed: _verifyPan,
            ),
          ] else ...[
            // Verified Details Result Card
            _buildResultCard(
              title: 'PAN RECORD DETAILS',
              rows: [
                InfoRow(label: 'Company Name', value: _verifiedPan!['company_name'] ?? 'N/A', isBold: true),
                InfoRow(label: 'PAN Status', value: _verifiedPan!['pan_status'] ?? 'Active', valueColor: AppColors.success),
                InfoRow(label: 'Holder Type', value: _verifiedPan!['holder_type'] ?? 'Company'),
                InfoRow(label: 'Incorporation', value: _verifiedPan!['date_of_birth_or_incorporation'] ?? 'N/A'),
                InfoRow(label: 'Aadhaar Linkage', value: _verifiedPan!['aadhaar_seeding_status'] ?? 'Linked', valueColor: AppColors.success),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryGovButton(
              label: 'Continue to UDYAM',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => setState(() => _currentStep = VerificationStep.udyam),
            ),
          ],
        ],
      ),
    );
  }

  // STEP 2: UDYAM
  Widget _buildUdyamStep() {
    final isVerified = _verifiedUdyam != null;

    return GovCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('UDYAM Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
              if (isVerified)
                StatusBadge.verified(label: 'UDYAM Verified')
              else
                StatusBadge.pending(label: 'Step 2 of 4'),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Enter your registered MSME Udyam registration details.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),

          if (!isVerified) ...[
            const Text('Udyam Registration Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _udyamController,
              decoration: const InputDecoration(
                hintText: 'e.g. UDYAM-MH-01-0000001',
                prefixIcon: Icon(Icons.corporate_fare_rounded, size: 18),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Udyam number' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Verification PIN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _udyamPinController,
              obscureText: _obscurePin,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter 6-digit PIN',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter PIN' : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryGovButton(
              label: _isLoading ? 'Connecting to government records...' : 'Verify UDYAM',
              isLoading: _isLoading,
              icon: Icons.check_circle_outline_rounded,
              onPressed: _verifyUdyam,
            ),
          ] else ...[
            _buildResultCard(
              title: 'UDYAM MSME DETAILS',
              rows: [
                InfoRow(label: 'Enterprise Name', value: _verifiedUdyam!['enterprise_name'] ?? _verifiedUdyam!['company_name'] ?? 'N/A', isBold: true),
                InfoRow(label: 'Registration Status', value: _verifiedUdyam!['status'] ?? 'Active', valueColor: AppColors.success),
                InfoRow(label: 'Enterprise Type', value: _verifiedUdyam!['enterprise_type'] ?? 'Medium Enterprise'),
                InfoRow(label: 'Major Activity', value: _verifiedUdyam!['major_activity'] ?? 'Services / Manufacturing'),
                InfoRow(label: 'Annual Turnover', value: _verifiedUdyam!['turnover'] ?? '₹12.00 Cr'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryGovButton(
              label: 'Continue to GST',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => setState(() => _currentStep = VerificationStep.gst),
            ),
          ],
        ],
      ),
    );
  }

  // STEP 3: GST
  Widget _buildGstStep() {
    final isVerified = _verifiedGst != null;

    return GovCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('GSTIN Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
              if (isVerified)
                StatusBadge.verified(label: 'GST Verified')
              else
                StatusBadge.pending(label: 'Step 3 of 4'),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Enter your registered 15-digit GSTIN details.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),

          if (!isVerified) ...[
            const Text('GSTIN Identifier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _gstController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'e.g. 22AAAAA1234A1Z5',
                prefixIcon: Icon(Icons.receipt_long_rounded, size: 18),
              ),
              validator: (v) => (v == null || v.trim().length != 15) ? 'Enter valid 15-digit GSTIN' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Verification PIN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _gstPinController,
              obscureText: _obscurePin,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter 6-digit PIN',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter PIN' : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryGovButton(
              label: _isLoading ? 'Connecting to government records...' : 'Verify GSTIN',
              isLoading: _isLoading,
              icon: Icons.check_circle_outline_rounded,
              onPressed: _verifyGst,
            ),
          ] else ...[
            _buildResultCard(
              title: 'GST RECORD DETAILS',
              rows: [
                InfoRow(label: 'Legal Name', value: _verifiedGst!['legal_name'] ?? _verifiedGst!['company_name'] ?? 'N/A', isBold: true),
                InfoRow(label: 'Trade Name', value: _verifiedGst!['trade_name'] ?? 'N/A'),
                InfoRow(label: 'GST Status', value: _verifiedGst!['status'] ?? 'Active', valueColor: AppColors.success),
                InfoRow(label: 'Taxpayer Type', value: _verifiedGst!['taxpayer_type'] ?? 'Regular'),
                InfoRow(label: 'State / Jurisdiction', value: _verifiedGst!['state_jurisdiction'] ?? 'Maharashtra'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryGovButton(
              label: 'Continue to OEM',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => setState(() => _currentStep = VerificationStep.oem),
            ),
          ],
        ],
      ),
    );
  }

  // STEP 4: OEM
  Widget _buildOemStep() {
    final isVerified = _verifiedOem != null;
    final allVerified = _verifiedPan != null && _verifiedUdyam != null && _verifiedGst != null && isVerified;

    return GovCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('OEM Authorization', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
              if (isVerified)
                StatusBadge.verified(label: 'OEM Verified')
              else
                StatusBadge.pending(label: 'Step 4 of 4'),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Enter your Manufacturer Authorization Form (MAF) reference.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),

          if (!isVerified) ...[
            const Text('OEM Authorization Code', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _oemController,
              decoration: const InputDecoration(
                hintText: 'e.g. OEM-MH-2026-001',
                prefixIcon: Icon(Icons.verified_rounded, size: 18),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter OEM code' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Verification PIN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _oemPinController,
              obscureText: _obscurePin,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter 6-digit PIN',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter PIN' : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryGovButton(
              label: _isLoading ? 'Connecting to government records...' : 'Verify OEM',
              isLoading: _isLoading,
              icon: Icons.check_circle_outline_rounded,
              onPressed: _verifyOem,
            ),
          ] else ...[
            _buildResultCard(
              title: 'OEM AUTHORIZATION DETAILS',
              rows: [
                InfoRow(label: 'Authorized Brand', value: _verifiedOem!['oem_brand'] ?? 'Nexora Enterprise OEM', isBold: true),
                InfoRow(label: 'Authorization No.', value: _verifiedOem!['oem_authorization_number'] ?? _oemController.text),
                InfoRow(label: 'Validity', value: _verifiedOem!['valid_until'] ?? '31-Dec-2027'),
                const InfoRow(label: 'Verification Status', value: 'Verified Active', valueColor: AppColors.success),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (allVerified)
              PrimaryGovButton(
                label: 'Finalize Business Verification',
                icon: Icons.task_alt_rounded,
                isLoading: _isLoading,
                backgroundColor: AppColors.success,
                onPressed: _finalizeAll,
              )
            else
              const Text(
                'Complete any remaining verification steps to finalize.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard({required String title, required List<Widget> rows}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.xs),
          ...rows,
        ],
      ),
    );
  }
}
