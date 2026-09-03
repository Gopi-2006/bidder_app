import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import 'company_profile_confirmation_screen.dart';
import 'login_screen.dart';

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

  // Verified Document Payloads (Temporary in-memory session)
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

  // Step 1: PAN Verification
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
        setState(() { _errorMessage = res['message']; });
      }
    } catch (e) {
      setState(() { _errorMessage = 'PAN verification error: $e'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Step 2: Udyam Verification
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
        setState(() { _errorMessage = res['message']; });
      }
    } catch (e) {
      setState(() { _errorMessage = 'Udyam verification error: $e'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Step 3: GST Verification
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
        setState(() { _errorMessage = res['message']; });
      }
    } catch (e) {
      setState(() { _errorMessage = 'GST verification error: $e'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Step 4: OEM Verification
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
        setState(() { _errorMessage = res['message']; });
      }
    } catch (e) {
      setState(() { _errorMessage = 'OEM verification error: $e'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Finalize Verification
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
        setState(() { _errorMessage = res['message']; });
      }
    } catch (e) {
      setState(() { _errorMessage = 'Finalization error: $e'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GemTheme.background,
      appBar: AppBar(
        title: const Text('Government Verification'),
        backgroundColor: GemTheme.primaryNavy,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Emblem & Portal Title
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: GemTheme.primaryNavy.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_outlined, size: 36, color: GemTheme.primaryNavy),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Bidder Government Verification',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'One-time sequential verification against simulated DigiLocker datasets',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Step Progress Indicator Bar
                    _buildStepProgress(),
                    const SizedBox(height: 16),

                    // Quick Demo Fill Chips
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.flash_on, size: 16, color: GemTheme.primaryNavy),
                          label: const Text('Fill Nexora Tech (Demo)', style: TextStyle(fontSize: 11)),
                          onPressed: _fillSampleNexora,
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.flash_on, size: 16, color: Colors.indigo),
                          label: const Text('Fill BluePeak Sol (Demo)', style: TextStyle(fontSize: 11)),
                          onPressed: _fillSampleBluePeak,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Dynamic Step Content Card
                    _buildCurrentStepCard(),

                    // Error Message Banner
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Switch to Email Login Link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                        },
                        child: const Text('Prefer standard email / password sign in? Click here', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Progress Tracker Widget — responsive to narrow phone widths (320–412px)
  Widget _buildStepProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Decide chip style based on available width
          final useCompact = constraints.maxWidth < 340;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: _buildStepChip(
                  useCompact ? 'PAN' : '1. PAN',
                  _verifiedPan != null,
                  _currentStep == VerificationStep.pan,
                  compact: useCompact,
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
              Flexible(
                child: _buildStepChip(
                  useCompact ? 'UDYAM' : '2. Udyam',
                  _verifiedUdyam != null,
                  _currentStep == VerificationStep.udyam,
                  compact: useCompact,
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
              Flexible(
                child: _buildStepChip(
                  useCompact ? 'GST' : '3. GST',
                  _verifiedGst != null,
                  _currentStep == VerificationStep.gst,
                  compact: useCompact,
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
              Flexible(
                child: _buildStepChip(
                  useCompact ? 'OEM' : '4. OEM',
                  _verifiedOem != null,
                  _currentStep == VerificationStep.oem,
                  compact: useCompact,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepChip(String label, bool isDone, bool isActive, {bool compact = false}) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade600;
    IconData icon = Icons.circle_outlined;

    if (isDone) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      icon = Icons.check_circle;
    } else if (isActive) {
      bg = GemTheme.primaryNavy.withValues(alpha: 0.1);
      fg = GemTheme.primaryNavy;
      icon = Icons.radio_button_checked;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 7,
        vertical: compact ? 3 : 4,
      ),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: fg),
          const SizedBox(width: 3),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.bold,
                  color: fg,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // Card Selector per Step
  Widget _buildCurrentStepCard() {
    switch (_currentStep) {
      case VerificationStep.pan:
        return _buildPanStepWidget();
      case VerificationStep.udyam:
        return _buildUdyamStepWidget();
      case VerificationStep.gst:
        return _buildGstStepWidget();
      case VerificationStep.oem:
        return _buildOemStepWidget();
      case VerificationStep.finalized:
        return _buildFinalizeWidget();
    }
  }

  // STEP 1: PAN Widget
  Widget _buildPanStepWidget() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.badge_outlined, color: Colors.blue, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Step 1: Verify PAN Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy)),
                      Text('Source: Income Tax PAN Dataset', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            if (_verifiedPan == null) ...[
              _buildFieldLabel('PAN Number', isRequired: true),
              const SizedBox(height: 6),
              TextFormField(
                controller: _panController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                  hintText: 'e.g. ABCDE1234F',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => (v == null || v.trim().length != 10) ? 'Enter a valid 10-character PAN' : null,
              ),
              const SizedBox(height: 14),

              _buildFieldLabel('Verification PIN', isRequired: true),
              const SizedBox(height: 6),
              TextFormField(
                controller: _panPinController,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                  hintText: 'e.g. 123456 or 1',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter verification PIN' : null,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyPan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GemTheme.primaryNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const Text('VERIFYING...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      : const Text('VERIFY PAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ] else ...[
              _buildSuccessBanner('PAN Verified ✓'),
              const SizedBox(height: 12),
              _buildSummaryRow('PAN Number', _verifiedPan!['pan_number'] ?? ''),
              _buildSummaryRow('Company Name', _verifiedPan!['company_name'] ?? ''),
              _buildSummaryRow('PAN Status', _verifiedPan!['pan_status'] ?? '', statusColor: Colors.green),
              _buildSummaryRow('Date of Birth', _verifiedPan!['date_of_birth'] ?? ''),
              _buildSummaryRow('PAN Holder Type', _verifiedPan!['pan_holder_type'] ?? ''),
              _buildSummaryRow('Aadhaar Linking', _verifiedPan!['aadhaar_linking_status'] ?? ''),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => setState(() => _currentStep = VerificationStep.udyam),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('CONTINUE TO UDYAM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // STEP 2: UDYAM Widget
  Widget _buildUdyamStepWidget() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.factory_outlined, color: Colors.teal, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Step 2: Verify Udyam Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy)),
                      Text('Source: MSME Udyam Registration Dataset', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            if (_verifiedUdyam == null) ...[
              _buildFieldLabel('Udyam Registration Number', isRequired: true),
              const SizedBox(height: 6),
              TextFormField(
                controller: _udyamController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.factory_outlined, size: 20),
                  hintText: 'e.g. UDYAM-MH-01-0000001',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => (v == null || v.trim().length < 8) ? 'Enter valid Udyam Registration Number' : null,
              ),
              const SizedBox(height: 14),

              _buildFieldLabel('Verification PIN', isRequired: true),
              const SizedBox(height: 6),
              TextFormField(
                controller: _udyamPinController,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                  hintText: 'e.g. 123456 or 3',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter verification PIN' : null,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyUdyam,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GemTheme.primaryNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const Text('VERIFYING...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      : const Text('VERIFY UDYAM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ] else ...[
              _buildSuccessBanner('Udyam Verified ✓'),
              const SizedBox(height: 12),
              _buildSummaryRow('Udyam Registration Number', _verifiedUdyam!['udyam_number'] ?? ''),
              _buildSummaryRow('Company Name', _verifiedUdyam!['company_name'] ?? ''),
              _buildSummaryRow('Registration Status', _verifiedUdyam!['registration_status'] ?? '', statusColor: Colors.green),
              _buildSummaryRow('Date of Registration', _verifiedUdyam!['date_of_registration'] ?? ''),
              _buildSummaryRow('Enterprise Type', _verifiedUdyam!['enterprise_type'] ?? ''),
              _buildSummaryRow('Investment', _verifiedUdyam!['investment'] ?? ''),
              _buildSummaryRow('Turnover', _verifiedUdyam!['turnover'] ?? ''),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => setState(() => _currentStep = VerificationStep.gst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('CONTINUE TO GST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // STEP 3: GST Widget
  Widget _buildGstStepWidget() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.account_balance_outlined, color: Colors.indigo, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Step 3: Verify GST Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy)),
                      Text('Source: GST Portal Dataset', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            if (_verifiedGst == null) ...[
              _buildFieldLabel('GST Number', isRequired: true),
              const SizedBox(height: 6),
              TextFormField(
                controller: _gstController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.account_balance_outlined, size: 20),
                  hintText: 'e.g. 22AAAAA1234A1Z5',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => (v == null || v.trim().length != 15) ? 'Enter valid 15-digit GSTIN' : null,
              ),
              const SizedBox(height: 14),

              _buildFieldLabel('Verification PIN', isRequired: true),
              const SizedBox(height: 6),
              TextFormField(
                controller: _gstPinController,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                  hintText: 'e.g. 123456 or 2',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter verification PIN' : null,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyGst,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GemTheme.primaryNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const Text('VERIFYING...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      : const Text('VERIFY GST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ] else ...[
              _buildSuccessBanner('GST Verified ✓'),
              const SizedBox(height: 12),
              _buildSummaryRow('GSTIN', _verifiedGst!['gstin'] ?? ''),
              _buildSummaryRow('Company Name', _verifiedGst!['company_name'] ?? ''),
              _buildSummaryRow('Registration Status', _verifiedGst!['registration_status'] ?? '', statusColor: Colors.green),
              _buildSummaryRow('Date of Registration', _verifiedGst!['date_of_registration'] ?? ''),
              _buildSummaryRow('Business Type', _verifiedGst!['business_type'] ?? ''),
              _buildSummaryRow('State', _verifiedGst!['state'] ?? 'Maharashtra'),
              _buildSummaryRow('Filing Status', _verifiedGst!['filing_status'] ?? 'Compliant', statusColor: Colors.green),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => setState(() => _currentStep = VerificationStep.oem),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('CONTINUE TO OEM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // STEP 4: OEM Widget
  Widget _buildOemStepWidget() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.verified_user_outlined, color: Colors.amber, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Step 4: Verify OEM Authorization', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy)),
                      Text('Source: Manufacturer Authorization Dataset', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            if (_verifiedOem == null) ...[
              _buildFieldLabel('OEM Authorization Number', isRequired: true),
              const SizedBox(height: 6),
              TextFormField(
                controller: _oemController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.verified_user_outlined, size: 20),
                  hintText: 'e.g. OEM-MH-2026-001',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => (v == null || v.trim().length < 4) ? 'Enter valid OEM Authorization Number' : null,
              ),
              const SizedBox(height: 14),

              _buildFieldLabel('Verification PIN', isRequired: true),
              const SizedBox(height: 6),
              TextFormField(
                controller: _oemPinController,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                  hintText: 'e.g. 123456 or 4',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter verification PIN' : null,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GemTheme.primaryNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const Text('VERIFYING...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      : const Text('VERIFY OEM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ] else ...[
              _buildSuccessBanner('OEM Authorization Verified ✓'),
              const SizedBox(height: 12),
              _buildSummaryRow('Authorization Number', _verifiedOem!['authorization_number'] ?? ''),
              _buildSummaryRow('Company Name', _verifiedOem!['company_name'] ?? ''),
              _buildSummaryRow('Authorization Status', _verifiedOem!['authorization_status'] ?? '', statusColor: Colors.green),
              _buildSummaryRow('Date of Issue', _verifiedOem!['date_of_issue'] ?? ''),
              _buildSummaryRow('Valid Till', _verifiedOem!['valid_till'] ?? '', statusColor: Colors.green),
              _buildSummaryRow('OEM Name', _verifiedOem!['oem_name'] ?? 'Dell'),
              _buildSummaryRow('Product Category', _verifiedOem!['product_category'] ?? 'Hardware'),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _finalizeAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GemTheme.saffron,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const Text('FINALIZING PROFILE...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('FINALIZE & SAVE PROFILE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(width: 8),
                            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                          ],
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // STEP 5: Finalized Placeholder
  Widget _buildFinalizeWidget() {
    return const SizedBox.shrink();
  }

  // Helper Widgets
  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy)),
        if (isRequired) const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSuccessBanner(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor ?? Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
