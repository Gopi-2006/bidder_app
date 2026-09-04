import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../core/firebase/auth_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/gov_card.dart';
import '../widgets/gov_buttons.dart';
import 'main_shell.dart';
import 'government_verification_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GeM Compliance — Professional Government Bidder Login
/// Section 6: Secure, Minimal, Structured, Accessible
/// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: "tender.desk@bharatnetworks.in");
  final _passController = TextEditingController(text: "password123");
  final _companyController = TextEditingController(text: "Bharat Infotech & Networks Pvt Ltd");
  final _gstinController = TextEditingController(text: "29ABCDE1234F1Z5");

  bool _isRegister = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _companyController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegister) {
        await FirebaseAuthService.register(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
          companyName: _companyController.text.trim(),
          gstin: _gstinController.text.trim(),
        );
      } else {
        await FirebaseAuthService.login(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShellScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid credentials or verification required. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Brand Header
                  const Center(
                    child: Column(
                      children: [
                        AppLogo(size: 58, showText: false),
                        SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'GeM',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.saffron,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Compliance',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryNavy,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Secure bidder access',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Main Authentication Card
                  GovCard(
                    elevated: true,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isRegister ? 'Register Enterprise Account' : 'Sign In to Your Account',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isRegister
                              ? 'Enter registered business details'
                              : 'Enter registered mobile or official email',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),
                        const Divider(),
                        const SizedBox(height: AppSpacing.lg),

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
                          const SizedBox(height: AppSpacing.md),
                        ],

                        if (_isRegister) ...[
                          const Text('Company Legal Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _companyController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Bharat Infotech & Networks Pvt Ltd',
                              prefixIcon: Icon(Icons.business_rounded, size: 18),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text('GSTIN Identifier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _gstinController,
                            decoration: const InputDecoration(
                              hintText: '15-digit GSTIN (e.g. 29ABCDE1234F1Z5)',
                              prefixIcon: Icon(Icons.badge_rounded, size: 18),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        const Text('Mobile / Email Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'bidder@domain.in',
                            prefixIcon: Icon(Icons.mail_outline_rounded, size: 18),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            if (!_isRegister)
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Password reset instructions sent to registered email.')),
                                  );
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 18,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        PrimaryGovButton(
                          label: _isRegister ? 'Complete Registration' : 'Sign In',
                          isLoading: _isLoading,
                          onPressed: _submit,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        SecondaryGovButton(
                          label: _isRegister ? 'Already have an account? Sign In' : 'Create Bidder Account',
                          onPressed: () {
                            setState(() {
                              _isRegister = !_isRegister;
                              _errorMessage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Government Business Verification Direct Access
                  GovCard(
                    backgroundColor: AppColors.surfaceElevated,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, color: AppColors.success, size: 20),
                        const SizedBox(width: AppSpacing.md),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'First-Time Business Onboarding?',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                              ),
                              Text(
                                'Verify PAN, Udyam, GST & OEM details',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const GovernmentVerificationScreen()),
                            );
                          },
                          child: const Text('Verify', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Official Security Indicator
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded, size: 14, color: AppColors.textMuted),
                      SizedBox(width: 6),
                      Text(
                        'Secure Government-Service Access',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
