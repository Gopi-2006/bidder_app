import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../widgets/gov_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/gov_buttons.dart';
import '../widgets/state_views.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GeM Compliance — Verified Document Vault
/// Reusable enterprise compliance certificates & schedules
/// ─────────────────────────────────────────────────────────────────────────────

class DocumentVaultScreen extends StatefulWidget {
  const DocumentVaultScreen({super.key});

  @override
  State<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends State<DocumentVaultScreen> {
  final List<Map<String, dynamic>> _vaultItems = [
    {
      'title': 'GSTIN Tax Registration Certificate',
      'type': 'GST_CERTIFICATE',
      'file': 'Bharat_GSTIN_Active_2026.pdf',
      'validity': 'Valid till 2027',
      'version': 'v2.1',
      'verified': true,
      'issuer': 'Goods & Services Tax Network (GSTN)',
      'sha256': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    },
    {
      'title': 'Company PAN Card',
      'type': 'PAN_CARD',
      'file': 'Company_PAN_Bharat.pdf',
      'validity': 'Permanent',
      'version': 'v1.0',
      'verified': true,
      'issuer': 'Income Tax Department (NSDL)',
      'sha256': 'a6b328bc12a591e1d0f81d42898fc2149e3b0c44298fc1c149afbf4c8996fb92',
    },
    {
      'title': 'Udyam MSME Registration Certificate',
      'type': 'UDYAM_CERTIFICATE',
      'file': 'Udyam_MSME_Certificate.pdf',
      'validity': 'Permanent • Medium Enterprise',
      'version': 'v1.2',
      'verified': true,
      'issuer': 'Ministry of Micro, Small and Medium Enterprises',
      'sha256': 'b2d8f93e1c2a498b76541234abcd5678ef901234567890abcdef1234567890ab',
    },
    {
      'title': 'Audited Turnover Statement & UDIN',
      'type': 'CA_TURNOVER_CERTIFICATE',
      'file': 'CA_Audited_Turnover_Statement.pdf',
      'validity': 'FY 2022-25 • ₹24.50 Cr avg',
      'version': 'v2.0',
      'verified': true,
      'issuer': 'ICAI Practicing Chartered Accountant',
      'sha256': 'c9e8d7c6b5a49382716059483726150493827160594837261504938271605948',
    },
    {
      'title': 'OEM Cisco Manufacturer Authorization Form (MAF)',
      'type': 'OEM_AUTHORIZATION',
      'file': 'Cisco_OEM_MAF_Letter.pdf',
      'validity': 'Valid for GeM 2026-27',
      'version': 'v1.0',
      'verified': true,
      'issuer': 'Cisco Systems India Pvt Ltd',
      'sha256': 'd1e2f3a4b5c6d7e8f901a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f901a2b3c4',
    },
    {
      'title': 'Signed Technical Compliance Schedule',
      'type': 'TECHNICAL_DECLARATION',
      'file': 'Signed_Technical_Compliance_Sheet.pdf',
      'validity': 'Executed 2026',
      'version': 'v1.0',
      'verified': true,
      'issuer': 'Bharat Infotech & Networks Pvt Ltd',
      'sha256': 'f9e8d7c6b5a432109876543210fedcba9876543210fedcba9876543210fedcba',
    },
  ];

  String _searchQuery = '';

  void _showAddDocumentDialog() {
    final titleController = TextEditingController();
    final fileController = TextEditingController();
    String selectedType = 'GST_CERTIFICATE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add New Document to Vault',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Store reusable enterprise credentials for instant attachment.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            const Text('Document Title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: 'e.g. ISO 9001:2015 Quality Certificate'),
            ),
            const SizedBox(height: AppSpacing.md),

            const Text('File Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: fileController,
              decoration: const InputDecoration(hintText: 'e.g. ISO_Quality_Cert_2026.pdf'),
            ),
            const SizedBox(height: AppSpacing.xl),

            PrimaryGovButton(
              label: 'Save to Vault',
              icon: Icons.save_rounded,
              onPressed: () {
                if (titleController.text.isNotEmpty && fileController.text.isNotEmpty) {
                  setState(() {
                    _vaultItems.add({
                      'title': titleController.text,
                      'type': selectedType,
                      'file': fileController.text,
                      'validity': 'Permanent',
                      'version': 'v1.0',
                      'verified': true,
                      'issuer': 'Self Declared • Secure Encrypted Storage',
                      'sha256': 'fa3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b12',
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('Document successfully added to vault!'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _vaultItems.where((item) {
      return _searchQuery.isEmpty ||
          item['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['file'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Document Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Document',
            onPressed: _showAddDocumentDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: const InputDecoration(
                hintText: 'Search vault certificates...',
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
              ),
            ),
          ),
          const Divider(height: 1),

          // Vault Items List
          Expanded(
            child: filtered.isEmpty
                ? const GovEmptyState(
                    icon: Icons.folder_open_rounded,
                    title: 'No documents match your search',
                    description: 'Try searching by document title or filename.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return GovCard(
                        elevated: true,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.infoBg,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.info, size: 22),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['title'],
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      StatusBadge.verified(label: 'Verified', compact: true),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['file'],
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item['issuer']} • ${item['validity']}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
