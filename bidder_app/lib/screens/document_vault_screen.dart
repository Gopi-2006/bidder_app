import 'package:flutter/material.dart';
import '../core/theme.dart';

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
      'file': 'Bharat_GSTIN_Active_2025.pdf',
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
      'validity': 'Permanent • Small Enterprise',
      'version': 'v1.2',
      'verified': true,
      'issuer': 'Ministry of Micro, Small and Medium Enterprises',
      'sha256': 'b2d8f93e1c2a498b76541234abcd5678ef901234567890abcdef1234567890ab',
    },
    {
      'title': 'Audited Turnover Statement & UDIN',
      'type': 'CA_TURNOVER_CERTIFICATE',
      'file': 'CA_Turnover_Audited_Statement.pdf',
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Document to Vault',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy),
            ),
            const SizedBox(height: 6),
            const Text(
              'Documents in your vault can be reused across multiple GeM tenders without re-uploading.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 24),
            const Text('Document Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              items: const [
                DropdownMenuItem(value: 'GST_CERTIFICATE', child: Text('GST Certificate')),
                DropdownMenuItem(value: 'PAN_CARD', child: Text('PAN Card')),
                DropdownMenuItem(value: 'UDYAM_CERTIFICATE', child: Text('Udyam MSME Registration')),
                DropdownMenuItem(value: 'CA_TURNOVER_CERTIFICATE', child: Text('CA Turnover Statement')),
                DropdownMenuItem(value: 'OEM_AUTHORIZATION', child: Text('OEM MAF Letter')),
                DropdownMenuItem(value: 'TECHNICAL_DECLARATION', child: Text('Technical Schedule')),
              ],
              onChanged: (val) {
                if (val != null) selectedType = val;
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Document Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'e.g. ISO 9001 Quality Certificate 2026',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 14),
            const Text('File Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: fileController,
              decoration: InputDecoration(
                hintText: 'e.g. ISO_9001_Quality_2026.pdf',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
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
                        'issuer': 'Self Declared • Stored on Google Drive',
                        'sha256': 'fa3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b12',
                      });
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF166534),
                        content: Text('Document successfully added to vault!'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Save to Secure Vault'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GemTheme.primaryNavy,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
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
      appBar: AppBar(
        title: const Text('Reusable Document Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Document',
            onPressed: _showAddDocumentDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search vault certificates...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Vault Items List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: GemTheme.primaryNavy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.folder_special, color: GemTheme.primaryNavy, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['title'] as String,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item['version'] as String,
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item['file']} • ${item['validity']}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Issuer: ${item['issuer']}',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDocumentDialog,
        backgroundColor: GemTheme.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file),
        label: const Text('Add Document'),
      ),
    );
  }
}
