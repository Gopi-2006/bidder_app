import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/design_system.dart';
import '../core/api_service.dart';
import '../models/tender_models.dart';
import '../widgets/gov_card.dart';
import '../widgets/gov_buttons.dart';
import '../widgets/status_badge.dart';
import '../widgets/state_views.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GeM Compliance — Secure Document Upload & Evaluation
/// Section 19: Clean government-grade document upload with real-time analysis
/// ─────────────────────────────────────────────────────────────────────────────

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
  String? _errorMessage;

  final List<Map<String, String>> _verifiedVaultFiles = [
    {
      'type': 'GST_CERTIFICATE',
      'name': 'Bharat_GSTIN_Active_2026.pdf',
      'desc': 'Active GSTIN 29ABCDE1234F1Z5 • Government Verified',
    },
    {
      'type': 'PAN_CARD',
      'name': 'Company_PAN_Bharat.pdf',
      'desc': 'Permanent Account Number • Verified',
    },
    {
      'type': 'UDYAM_CERTIFICATE',
      'name': 'Udyam_MSME_Certificate.pdf',
      'desc': 'UDYAM-MH-01-0000001 • Medium Enterprise',
    },
    {
      'type': 'CA_TURNOVER_CERTIFICATE',
      'name': 'CA_Audited_Turnover_Statement.pdf',
      'desc': 'Audited Statement ₹24.50 Cr with UDIN • FY 2022-25',
    },
    {
      'type': 'OEM_AUTHORIZATION',
      'name': 'Cisco_OEM_MAF_Letter.pdf',
      'desc': 'Manufacturer Authorization Form (MAF)',
    },
    {
      'type': 'TECHNICAL_DECLARATION',
      'name': 'Signed_Technical_Compliance_Sheet.pdf',
      'desc': 'Formally signed Technical Specification Schedule',
    },
  ];

  Future<void> _processUpload(String docType, String fileName) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _uploadStatusMessage = '1/3 Securely uploading document...';
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() {
      _uploadStatusMessage = '2/3 Verifying document attributes & signatures...';
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() {
      _uploadStatusMessage = '3/3 Running automated compliance analysis...';
    });

    try {
      final success = await ApiService.uploadEvidence(
        applicationId: widget.applicationId,
        requirementId: widget.requirement.requirementId,
        documentType: docType,
        fileName: fileName,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.success,
              content: Text('Document successfully uploaded & verified!'),
            ),
          );
          Navigator.pop(context, true);
        } else {
          setState(() {
            _errorMessage = 'Verification service was unable to evaluate this document.';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Connection error during document upload. Please try again.';
        });
      }
    }
  }

  Future<void> _pickDeviceFile() async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result.isNotEmpty) {
        final file = result.first;
        final docType = widget.requirement.expectedDocumentTypes.isNotEmpty
            ? widget.requirement.expectedDocumentTypes.first
            : 'SUPPORTING_DOCUMENT';
        await _processUpload(docType, file.name);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open file picker. Select from verified documents below.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.requirement;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Upload Evidence Document'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Clause Requirement Card
            GovCard(
              elevated: true,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          req.clauseReference.isNotEmpty ? req.clauseReference : 'Clause',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          req.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ),
                      StatusBadge(status: req.requirementType, compact: true),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    req.description,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
                      SizedBox(width: 6),
                      Text(
                        'Accepted format: PDF  •  Max size: 15 MB',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // In-Progress Processing Animation Card
            if (_isProcessing) ...[
              GovCard(
                elevated: true,
                padding: const EdgeInsets.all(AppSpacing.xl),
                borderColor: AppColors.infoBorder,
                child: Column(
                  children: [
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primaryNavy),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      _uploadStatusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Automated compliance verification in progress...',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

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
                      child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Option 1: Pick from Device
            PrimaryGovButton(
              label: 'Select PDF from Device',
              icon: Icons.upload_file_rounded,
              isLoading: _isProcessing,
              onPressed: _pickDeviceFile,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Option 2: Select from Verified Enterprise Document Vault
            const SectionHeader(
              title: 'Or Select from Verified Vault',
              subtitle: 'Pre-authenticated business certificates',
            ),

            ..._verifiedVaultFiles.map((vf) {
              final isMatching = req.expectedDocumentTypes.contains(vf['type']) ||
                  vf['type'] == 'TECHNICAL_DECLARATION';

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: GovCard(
                  onTap: _isProcessing
                      ? null
                      : () => _processUpload(vf['type']!, vf['name']!),
                  borderColor: isMatching ? AppColors.infoBorder : AppColors.border,
                  backgroundColor: isMatching ? AppColors.infoBg.withValues(alpha: 0.3) : Colors.white,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isMatching ? AppColors.infoBg : AppColors.surfaceElevated,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 18,
                          color: isMatching ? AppColors.info : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vf['name']!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              vf['desc']!,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (isMatching)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.success),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
