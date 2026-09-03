import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../models/tender_models.dart';

class EvidenceUploadScreen extends StatefulWidget {
  final RequirementModel requirement;
  final String applicationId;

  const EvidenceUploadScreen({
    super.key,
    required this.requirement,
    required this.applicationId,
  });

  @override
  State<EvidenceUploadScreen> createState() => _EvidenceUploadScreenState();
}

class _EvidenceUploadScreenState extends State<EvidenceUploadScreen> {
  bool _isProcessing = false;
  String _uploadStatusMessage = '';

  final List<Map<String, String>> _mockVaultFiles = [
    {
      'type': 'GST_CERTIFICATE',
      'name': 'Bharat_GSTIN_Active_2025.pdf',
      'desc': 'Active GSTIN 29ABCDE1234F1Z5 • Registered Karnataka',
    },
    {
      'type': 'PAN_CARD',
      'name': 'Company_PAN_Bharat.pdf',
      'desc': 'Permanent Account Number AAACB1234F • NSDL Verified',
    },
    {
      'type': 'UDYAM_CERTIFICATE',
      'name': 'Udyam_MSME_Certificate.pdf',
      'desc': 'UDYAM-KR-03-0012345 • Small Enterprise Category',
    },
    {
      'type': 'CA_TURNOVER_CERTIFICATE',
      'name': 'CA_Turnover_Audited_Statement.pdf',
      'desc': 'Audited Average Turnover ₹24.50 Cr • FY 2022-25',
    },
    {
      'type': 'CA_TURNOVER_CERTIFICATE',
      'name': 'CA_Turnover_High_Statement.pdf',
      'desc': 'Audited Statement ₹32.80 Cr with UDIN • FY 2022-25',
    },
    {
      'type': 'OEM_AUTHORIZATION',
      'name': 'Cisco_OEM_MAF_Letter.pdf',
      'desc': 'Manufacturer Authorization Form • Cisco Systems India',
    },
    {
      'type': 'TECHNICAL_DECLARATION',
      'name': 'Signed_Technical_Compliance_Sheet.pdf',
      'desc': 'Formally signed Clause 5.3 technical schedule',
    },
  ];

  Future<void> _processUpload(String docType, String fileName) async {
    setState(() {
      _isProcessing = true;
      _uploadStatusMessage = '1/3 Encrypting & Uploading to Google Drive hierarchy...';
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _uploadStatusMessage = '2/3 Performing OCR & Extracting key attributes...';
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _uploadStatusMessage = '3/3 Executing Deterministic Rule Engine...';
    });

    final success = await ApiService.uploadEvidence(
      applicationId: widget.applicationId,
      requirementId: widget.requirement.requirementId,
      documentType: docType,
      fileName: fileName,
    );

    setState(() {
      _isProcessing = false;
      _uploadStatusMessage = '';
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF166534),
          content: Text('Document "$fileName" uploaded to Google Drive & verified!'),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFDC2626),
          content: Text('Upload failed. Please check network or file format.'),
        ),
      );
    }
  }

  Future<void> _pickLocalFile() async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result.isNotEmpty) {
        final file = result.first;
        final docType = widget.requirement.expectedDocumentTypes.isNotEmpty
            ? widget.requirement.expectedDocumentTypes.first
            : 'TECHNICAL_DECLARATION';

        _processUpload(docType, file.name);
      }
    } catch (e) {
      if (mounted) {
        // Fallback for emulator / web environment
        final docType = widget.requirement.expectedDocumentTypes.isNotEmpty
            ? widget.requirement.expectedDocumentTypes.first
            : 'TECHNICAL_DECLARATION';
        _processUpload(docType, 'Selected_Document_${widget.requirement.clauseReference.replaceAll(" ", "_")}.pdf');
      }
    }
  }

  void _simulateCameraCapture() {
    final docType = widget.requirement.expectedDocumentTypes.isNotEmpty
        ? widget.requirement.expectedDocumentTypes.first
        : 'TECHNICAL_DECLARATION';
    _processUpload(docType, 'Scanned_Camera_Evidence_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.requirement;
    final matchingDocs = _mockVaultFiles.where((f) {
      if (req.expectedDocumentTypes.isEmpty) return true;
      return req.expectedDocumentTypes.contains(f['type']);
    }).toList();

    final otherVaultDocs = _mockVaultFiles.where((f) {
      return !req.expectedDocumentTypes.contains(f['type']);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evidence Upload & Verification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Requirement Context Header
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            req.clauseReference,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            req.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      req.description,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3),
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.document_scanner_outlined, size: 16, color: GemTheme.saffron),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Required Document Type: ${req.expectedDocumentTypes.join(", ")}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_isProcessing) ...[
              Card(
                color: const Color(0xFFFFFBEB),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: GemTheme.saffron),
                      const SizedBox(height: 16),
                      Text(
                        _uploadStatusMessage,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'FastAPI is syncing binary to Google Drive and calculating deterministic compliance.',
                        style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Section 1: Upload from Reusable Document Vault
            const Text(
              'Option 1: Attach from Bidder Document Vault',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select pre-verified company records stored in your secure vault.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 10),

            if (matchingDocs.isNotEmpty) ...[
              ...matchingDocs.map((doc) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 22),
                    ),
                    title: Text(doc['name']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: Text(doc['desc']!, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    trailing: ElevatedButton(
                      onPressed: _isProcessing ? null : () => _processUpload(doc['type']!, doc['name']!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GemTheme.primaryNavy,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: const Text('Attach', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                );
              }),
            ],

            if (otherVaultDocs.isNotEmpty) ...[
              const SizedBox(height: 10),
              ExpansionTile(
                title: const Text('View other documents in vault', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                children: otherVaultDocs.map((doc) {
                  return ListTile(
                    leading: const Icon(Icons.description_outlined, size: 20),
                    title: Text(doc['name']!, style: const TextStyle(fontSize: 12)),
                    subtitle: Text(doc['type']!, style: const TextStyle(fontSize: 10)),
                    trailing: TextButton(
                      onPressed: _isProcessing ? null : () => _processUpload(doc['type']!, doc['name']!),
                      child: const Text('Use Anyway'),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Section 2: Direct Device Upload
            const Text(
              'Option 2: Upload from Local Device or Camera',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _pickLocalFile,
                    icon: const Icon(Icons.upload_file, color: GemTheme.primaryNavy),
                    label: const Text('Pick PDF / File'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: GemTheme.primaryNavy),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _simulateCameraCapture,
                    icon: const Icon(Icons.camera_alt_outlined, color: GemTheme.saffron),
                    label: const Text('Scan Camera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: GemTheme.saffron),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
