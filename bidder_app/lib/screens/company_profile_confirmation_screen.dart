import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'main_shell.dart';

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

    final companyName = company['name'] ?? panData['company_name'] ?? 'Verified Enterprise';

    return Scaffold(
      backgroundColor: GemTheme.background,
      appBar: AppBar(
        title: const Text('Company Profile Verified'),
        backgroundColor: GemTheme.primaryNavy,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Verification Success Header Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.green.shade200, width: 2),
                            ),
                            child: const Icon(Icons.verified_rounded, size: 48, color: Colors.green),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            companyName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: GemTheme.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 16, color: Colors.green.shade800),
                                const SizedBox(width: 6),
                                Text(
                                  'GOVERNMENT VERIFIED ENTERPRISE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'All 4 government documents and authentication credentials have been verified.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                    child: Text(
                      'VERIFIED GOVERNMENT RECORDS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.0,
                      ),
                    ),
                   ),
                  const SizedBox(height: 8),

                  // 1. PAN Document Card
                  _buildDetailCard(
                    title: 'Income Tax PAN Details',
                    icon: Icons.badge_outlined,
                    color: Colors.blue.shade700,
                    fields: [
                      _DetailItem('PAN Number', panData['pan_number']?.toString() ?? 'N/A', isBold: true),
                      _DetailItem('PAN Status', panData['pan_status']?.toString() ?? 'Active', statusColor: Colors.green),
                      _DetailItem('Date of Birth', panData['date_of_birth']?.toString() ?? ''),
                      _DetailItem('Entity Type', panData['pan_holder_type']?.toString() ?? 'Company'),
                      _DetailItem('Aadhaar Linking', panData['aadhaar_linking_status']?.toString() ?? 'Linked'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. GSTIN Document Card
                  _buildDetailCard(
                    title: 'GST Identification (GSTIN)',
                    icon: Icons.account_balance_outlined,
                    color: Colors.indigo.shade700,
                    fields: [
                      _DetailItem('GSTIN', gstData['gstin']?.toString() ?? 'N/A', isBold: true),
                      _DetailItem('Registration Status', gstData['registration_status']?.toString() ?? 'Active', statusColor: Colors.green),
                      _DetailItem('Date of Registration', gstData['date_of_registration']?.toString() ?? ''),
                      _DetailItem('Business Type', gstData['business_type']?.toString() ?? ''),
                      _DetailItem('State', gstData['state']?.toString() ?? 'Maharashtra'),
                      _DetailItem('Filing Status', gstData['filing_status']?.toString() ?? 'Compliant', statusColor: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. Udyam Registration Card
                  _buildDetailCard(
                    title: 'MSME Udyam Registration',
                    icon: Icons.factory_outlined,
                    color: Colors.teal.shade700,
                    fields: [
                      _DetailItem('Udyam Number', udyamData['udyam_number']?.toString() ?? 'N/A', isBold: true),
                      _DetailItem('Registration Status', udyamData['registration_status']?.toString() ?? 'Active', statusColor: Colors.green),
                      _DetailItem('Date of Registration', udyamData['date_of_registration']?.toString() ?? ''),
                      _DetailItem('Enterprise Type', udyamData['enterprise_type']?.toString() ?? 'Manufacturing'),
                      _DetailItem('Investment', udyamData['investment']?.toString() ?? ''),
                      _DetailItem('Turnover', udyamData['turnover']?.toString() ?? ''),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 4. OEM Authorization Card
                  _buildDetailCard(
                    title: 'OEM Authorization Certificate',
                    icon: Icons.verified_user_outlined,
                    color: Colors.amber.shade900,
                    fields: [
                      _DetailItem('Authorization No.', oemData['authorization_number']?.toString() ?? 'N/A', isBold: true),
                      _DetailItem('Status', oemData['authorization_status']?.toString() ?? 'Active', statusColor: Colors.green),
                      _DetailItem('Date of Issue', oemData['date_of_issue']?.toString() ?? ''),
                      _DetailItem('Valid Till', oemData['valid_till']?.toString() ?? '', statusColor: Colors.green),
                      _DetailItem('OEM Brand', oemData['oem_name']?.toString() ?? 'Dell'),
                      _DetailItem('Product Category', oemData['product_category']?.toString() ?? 'Hardware'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Continue Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MainShellScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GemTheme.primaryNavy,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'CONTINUE TO APP',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<_DetailItem> fields,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Column(
              children: fields.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          item.value,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: item.isBold ? FontWeight.bold : FontWeight.w600,
                            color: item.statusColor ?? Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem {
  final String label;
  final String value;
  final bool isBold;
  final Color? statusColor;

  _DetailItem(this.label, this.value, {this.isBold = false, this.statusColor});
}
