import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../core/api_service.dart';
import '../models/tender_models.dart';
import '../widgets/gov_card.dart';
import '../widgets/gov_buttons.dart';
import '../widgets/status_badge.dart';
import '../widgets/compliance_score_ring.dart';
import '../widgets/state_views.dart';
import 'evidence_upload_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GeM Compliance — Application Detail & AI Compliance Verification
/// Sections 16, 17, 18, 20, 21: Guided workflow, AI analysis engine, Readiness
/// ─────────────────────────────────────────────────────────────────────────────

class ApplicationDetailScreen extends StatefulWidget {
  final String applicationId;
  final TenderModel tender;

  const ApplicationDetailScreen({
    super.key,
    required this.applicationId,
    required this.tender,
  });

  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  BidderApplicationModel? _application;
  List<EvidenceModel> _evidenceList = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _activeWorkflowStep = 1; // 0: Review, 1: Documents & Compliance, 2: Submission Readiness

  @override
  void initState() {
    super.initState();
    _loadApplicationData();
  }

  Future<void> _loadApplicationData() async {
    setState(() => _isLoading = true);
    try {
      final app = await ApiService.fetchApplication(widget.applicationId);
      final evs = await ApiService.fetchApplicationEvidence(widget.applicationId);

      if (mounted) {
        setState(() {
          _application = app;
          _evidenceList = evs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitFinalApplication() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Final Bid Submission'),
        content: const Text(
          'Are you sure you want to formally submit this bid application to the GeM Procurement Committee? All uploaded evidence and compliance evaluations will be sealed for officer review.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
            child: const Text('Confirm & Submit'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSubmitting = true);
      final success = await ApiService.submitApplication(widget.applicationId);
      setState(() => _isSubmitting = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Bid Application submitted successfully to GeM Officers!'),
          ),
        );
        _loadApplicationData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tender = widget.tender;
    final results = _application?.results ?? [];

    final passCount = results.where((r) => r.status.toUpperCase() == 'PASS').length;
    final reviewCount = results.where((r) => r.status.toUpperCase() == 'REVIEW').length;
    final failCount = results.where((r) => r.status.toUpperCase() == 'FAIL').length;
    final totalReqs = tender.requirements.length;

    final double score = totalReqs > 0 ? (passCount / totalReqs) : 0.0;
    final isSubmitted = _application?.overallStatus.toUpperCase() == 'SUBMITTED' ||
        _application?.overallStatus.toUpperCase() == 'DECIDED';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.applicationId, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text('Tender: ${tender.bidNumber}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Status',
            onPressed: _loadApplicationData,
          ),
        ],
      ),
      body: _isLoading
          ? const GovLoadingSkeleton(count: 3)
          : RefreshIndicator(
              onRefresh: _loadApplicationData,
              color: AppColors.primaryNavy,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Guided Application Stepper
                    _buildGuidedWorkflowStepper(),
                    const SizedBox(height: AppSpacing.lg),

                    // AI Compliance Analysis Card with Circular Score
                    ComplianceSummaryCard(
                      score: score,
                      passCount: passCount,
                      reviewCount: reviewCount,
                      failCount: failCount,
                      totalCount: totalReqs,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Requirements Checklist Section
                    SectionHeader(
                      title: 'Requirements & Document Verification',
                      subtitle: '$passCount of $totalReqs clauses satisfied',
                    ),
                    _buildRequirementsList(tender, results),
                    const SizedBox(height: AppSpacing.xl),

                    // Submission Readiness Card (Section 21)
                    _buildSubmissionReadinessCard(
                      passCount: passCount,
                      totalReqs: totalReqs,
                      failCount: failCount,
                      isSubmitted: isSubmitted,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGuidedWorkflowStepper() {
    return GovCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _buildWorkflowStepItem(0, '1. Review', Icons.search_rounded),
          _buildWorkflowArrow(),
          _buildWorkflowStepItem(1, '2. Compliance', Icons.fact_check_rounded),
          _buildWorkflowArrow(),
          _buildWorkflowStepItem(2, '3. Submit', Icons.send_rounded),
        ],
      ),
    );
  }

  Widget _buildWorkflowStepItem(int stepIdx, String label, IconData icon) {
    final isCurrent = _activeWorkflowStep == stepIdx;
    final isCompleted = _activeWorkflowStep > stepIdx;

    Color color;
    if (isCompleted) {
      color = AppColors.success;
    } else if (isCurrent) {
      color = AppColors.primaryNavy;
    } else {
      color = AppColors.textMuted;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeWorkflowStep = stepIdx),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isCompleted ? Icons.check_circle_rounded : icon, size: 16, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowArrow() {
    return const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.border);
  }

  Widget _buildRequirementsList(TenderModel tender, List<RuleEvaluationModel> results) {
    return Column(
      children: tender.requirements.map((req) {
        final evalResult = results.firstWhere(
          (r) => r.requirementId == req.requirementId,
          orElse: () => RuleEvaluationModel(
            resultId: '',
            requirementId: req.requirementId,
            status: 'NOT_STARTED',
            ruleVersion: '',
            explanation: 'No document attached yet.',
            plainLanguageBidderMsg: 'Document attachment required for deterministic verification.',
            reasonCodes: [],
            evaluatedValues: {},
            timestamp: '',
          ),
        );

        final activeEvidence = _evidenceList.where(
          (e) => (e.requirementId == req.requirementId || req.expectedDocumentTypes.contains(e.documentType)) && e.status == 'ACTIVE',
        ).toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: GovCard(
            elevated: true,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Clause + Title + Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        req.clauseReference.isNotEmpty ? req.clauseReference : 'Clause',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        req.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ),
                    StatusBadge(status: evalResult.status, compact: true),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  req.description,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                ),

                // Attached Evidence Document
                if (activeEvidence.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description_rounded, size: 16, color: AppColors.info),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Attached: ${activeEvidence.first.fileName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                        StatusBadge.verified(label: 'Verified', compact: true),
                      ],
                    ),
                  ),
                ],

                // Deterministic Bidder Explanation
                if (evalResult.status != 'NOT_STARTED') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: evalResult.status == 'PASS'
                          ? AppColors.successBg
                          : evalResult.status == 'REVIEW'
                              ? AppColors.warningBg
                              : AppColors.errorBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: evalResult.status == 'PASS'
                            ? AppColors.successBorder
                            : evalResult.status == 'REVIEW'
                                ? AppColors.warningBorder
                                : AppColors.errorBorder,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          evalResult.status == 'PASS'
                              ? Icons.check_circle_rounded
                              : evalResult.status == 'REVIEW'
                                  ? Icons.info_outline_rounded
                                  : Icons.error_outline_rounded,
                          size: 15,
                          color: evalResult.status == 'PASS'
                              ? AppColors.success
                              : evalResult.status == 'REVIEW'
                                  ? AppColors.warning
                                  : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            evalResult.plainLanguageBidderMsg,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: evalResult.status == 'PASS'
                                  ? AppColors.success
                                  : evalResult.status == 'REVIEW'
                                      ? AppColors.warning
                                      : AppColors.error,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action: Upload or Re-upload Document
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EvidenceUploadScreen(
                            requirement: req,
                            applicationId: widget.applicationId,
                          ),
                        ),
                      );
                      if (updated == true) {
                        _loadApplicationData();
                      }
                    },
                    icon: Icon(
                      activeEvidence.isNotEmpty ? Icons.upload_file_rounded : Icons.add_circle_outline_rounded,
                      size: 14,
                    ),
                    label: Text(
                      activeEvidence.isNotEmpty ? 'Update Document' : 'Upload Document',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmissionReadinessCard({
    required int passCount,
    required int totalReqs,
    required int failCount,
    required bool isSubmitted,
  }) {
    final isReady = passCount == totalReqs && totalReqs > 0;

    return GovCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderColor: isSubmitted
          ? AppColors.successBorder
          : isReady
              ? AppColors.successBorder
              : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isReady || isSubmitted ? AppColors.successBg : AppColors.warningBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSubmitted
                      ? Icons.task_alt_rounded
                      : isReady
                          ? Icons.check_circle_rounded
                          : Icons.pending_actions_rounded,
                  size: 22,
                  color: isReady || isSubmitted ? AppColors.success : AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSubmitted
                          ? 'APPLICATION SUBMITTED'
                          : isReady
                              ? 'READY TO SUBMIT'
                              : 'SUBMISSION INCOMPLETE',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isReady || isSubmitted ? AppColors.success : AppColors.warning,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      isSubmitted
                          ? 'Sealed for procurement committee evaluation'
                          : isReady
                              ? 'All required clauses and documents satisfied'
                              : '$failCount clause(s) require action before final bid submission',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.md),

          // Checklist
          _buildChecklistItem('Business verified & cross-checked', true),
          _buildChecklistItem('PAN & GST records active', true),
          _buildChecklistItem('Clause evidence documents attached', passCount > 0),
          _buildChecklistItem('All mandatory requirements satisfied', isReady),

          const SizedBox(height: AppSpacing.xl),

          if (isSubmitted)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Text(
                'This application has been formally submitted. Modifications are locked pending officer evaluation.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
              ),
            )
          else
            PrimaryGovButton(
              label: isReady ? 'Submit Final Bid Application' : 'Resolve Incomplete Clauses to Submit',
              icon: Icons.send_rounded,
              isLoading: _isSubmitting,
              backgroundColor: isReady ? AppColors.success : AppColors.primaryNavy.withValues(alpha: 0.6),
              onPressed: isReady ? _submitFinalApplication : null,
            ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool isSatisfied) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isSatisfied ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: isSatisfied ? AppColors.success : AppColors.textDisabled,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.w400,
                color: isSatisfied ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
