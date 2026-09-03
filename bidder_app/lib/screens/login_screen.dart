import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/firebase/auth_service.dart';
import 'main_shell.dart';
import 'government_verification_screen.dart';

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
  bool _isLoading = false;
  String? _errorMessage;

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
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _companyController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GemTheme.background,
      appBar: AppBar(
        title: const Text('GeM Bidder Authentication'),
        backgroundColor: GemTheme.primaryNavy,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top GeM Emblem Header
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
                      const SizedBox(height: 12),
                      const Text(
                        'National Public Procurement Portal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: GemTheme.primaryNavy,
                        ),
                      ),
                      const Text(
                        'Automated Compliance & Verification Engine',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: GemTheme.primaryNavy.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.security, color: GemTheme.primaryNavy, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isRegister ? 'Register Enterprise Account' : 'Bidder Sign In',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: GemTheme.primaryNavy,
                                    ),
                                  ),
                                  const Text(
                                    'Role: Public Registered Vendor (BIDDER)',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28),
                        if (_isRegister) ...[
                          const Text('Company Legal Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _companyController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.business, size: 20),
                              hintText: 'e.g. Bharat Infotech & Networks Pvt Ltd',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text('GSTIN Identifier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _gstinController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                              hintText: '15-digit GSTIN number',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        const Text('Official Email Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email_outlined, size: 20),
                            hintText: 'bidder@domain.in',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text('Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passController,
                          obscureText: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            hintText: '••••••••',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GemTheme.primaryNavy,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    _isRegister ? 'Register Enterprise & Continue' : 'Sign In to GeM Bidder Portal',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isRegister ? 'Already registered enterprise?' : 'New bidder on GeM platform?',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isRegister = !_isRegister;
                          _errorMessage = null;
                        });
                      },
                      child: Text(
                        _isRegister ? 'Sign In' : 'Register Now',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: GemTheme.saffron, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.verified_user, size: 18, color: GemTheme.primaryNavy),
                    label: const Text(
                      'Government Details Verification (PAN • GST • MSME • OEM)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: GemTheme.primaryNavy),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GovernmentVerificationScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

