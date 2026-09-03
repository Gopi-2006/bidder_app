import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../models/tender_models.dart';
import 'evidence_upload_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadApplicationData();
  }

  Future<void> _loadApplicationData() async {
    setState(() => _isLoading = true);
    final app = await ApiService.fetchApplication(widget.applicationId);
    final evs = await ApiService.fetchApplicationEvidence(widget.applicationId);

    setState(() {
      _application = app;
      _evidenceList = evs;
      _isLoading = false;
    });
  }

  Future<void> _submitFinalApplication() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Final Bid Submission'),
        content: const Text(
          'Are you sure you want to formally submit this bid application to the GeM Procurement Committee? All active uploaded evidence and deterministic rule evaluations will be sealed for officer review.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: GemTheme.primaryNavy),
            child: const Text('Confirm & Submit'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSubmitting = true);
      final success = await ApiService.submitApplication(widget.applicationId);
      setState(() => _isSubmitting = false);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF166534),
              content: Text('Bid Application submitted successfully to GeM Officers!'),
            ),
          );
          _loadApplicationData();
        }
      }
    }
  }

  Widget _buildStatusChip(String? status) {
    switch (status?.toUpperCase()) {
      case 'PASS':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            border: Border.all(color: const Color(0xFF86EFAC)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('PASS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
        );
      case 'REVIEW':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            border: Border.all(color: const Color(0xFFFCD34D)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('REVIEW NEEDED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
        );
      case 'FAIL':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            border: Border.all(color: const Color(0xFFFCA5A5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('ACTION REQUIRED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('NOT STARTED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        );
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

    final progressPercent = totalReqs > 0 ? (passCount / totalReqs) : 0.0;
    final isSubmitted = _application?.overallStatus.toUpperCase() == 'SUBMITTED' ||
        _application?.overallStatus.toUpperCase() == 'DECIDED';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.applicationId, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('Tender: ${tender.bidNumber}', style: const TextStyle(fontSize: 11, color: Color(0xFF93C5FD))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplicationData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: GemTheme.saffron))
          : RefreshIndicator(
              onRefresh: _loadApplicationData,
              color: GemTheme.saffron,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Header Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Application Verification State',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSubmitted ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSubmitted ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Text(
                                    _application?.overallStatus ?? 'IN_PROGRESS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSubmitted ? const Color(0xFF166534) : const Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progressPercent,
                                minHeight: 8,
                                backgroundColor: const Color(0xFFE2E8F0),
                                color: progressPercent == 1.0 ? const Color(0xFF16A34A) : GemTheme.saffron,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMetricBox('PASS', passCount, const Color(0xFF166534), const Color(0xFFDCFCE7)),
                                _buildMetricBox('REVIEW', reviewCount, const Color(0xFF92400E), const Color(0xFFFEF3C7)),
                                _buildMetricBox('FAIL', failCount, const Color(0xFF991B1B), const Color(0xFFFEE2E2)),
                                _buildMetricBox('TOTAL', totalReqs, GemTheme.primaryNavy, const Color(0xFFF1F5F9)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section Heading
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Clause Requirements Checklist',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy),
                        ),
                        Text(
                          '$passCount/$totalReqs Verified',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Requirements Cards List
                    ...tender.requirements.map((req) {
                      final evalResult = results.firstWhere(
                        (r) => r.requirementId == req.requirementId,
                        orElse: () => RuleEvaluationModel(
                          resultId: '',
                          requirementId: req.requirementId,
                          status: 'NOT_STARTED',
                          ruleVersion: '',
                          explanation: 'No evidence uploaded yet.',
                          plainLanguageBidderMsg: 'Document attachment required for deterministic verification.',
                          reasonCodes: [],
                          evaluatedValues: {},
                          timestamp: '',
                        ),
                      );

                      final activeEvidence = _evidenceList.where(
                        (e) => (e.requirementId == req.requirementId || req.expectedDocumentTypes.contains(e.documentType)) && e.status == 'ACTIVE',
                      ).toList();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: evalResult.status == 'PASS'
                                ? const Color(0xFF86EFAC)
                                : evalResult.status == 'REVIEW'
                                    ? const Color(0xFFFCD34D)
                                    : evalResult.status == 'FAIL'
                                        ? const Color(0xFFFCA5A5)
                                        : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  _buildStatusChip(evalResult.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                req.description,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                              ),
                              if (activeEvidence.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.description, size: 16, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Attached: ${activeEvidence.first.fileName} (v${activeEvidence.first.version})',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('DRIVE SYNCED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (evalResult.status != 'NOT_STARTED') ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: evalResult.status == 'PASS'
                                        ? const Color(0xFFF0FDF4)
                                        : evalResult.status == 'REVIEW'
                                            ? const Color(0xFFFFFBEB)
                                            : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            evalResult.status == 'PASS'
                                                ? Icons.check_circle_outline
                                                : evalResult.status == 'REVIEW'
                                                    ? Icons.help_outline
                                                    : Icons.error_outline,
                                            size: 16,
                                            color: evalResult.status == 'PASS'
                                                ? const Color(0xFF16A34A)
                                                : evalResult.status == 'REVIEW'
                                                    ? const Color(0xFFD97706)
                                                    : const Color(0xFFDC2626),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Rule Engine Verification:',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: evalResult.status == 'PASS'
                                                ? const Color(0xFF166534)
                                                : evalResult.status == 'REVIEW'
                                                    ? const Color(0xFF92400E)
                                                    : const Color(0xFF991B1B),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        evalResult.plainLanguageBidderMsg.isNotEmpty
                                            ? evalResult.plainLanguageBidderMsg
                                            : evalResult.explanation,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF334155), height: 1.3),
                                      ),
                                      if (evalResult.reasonCodes.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Reason Trigger: ${evalResult.reasonCodes.join(", ")}',
                                          style: const TextStyle(fontSize: 10, color: Color(0xFFB45309), fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              if (!isSubmitted)
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EvidenceUploadScreen(
                                            requirement: req,
                                            applicationId: widget.applicationId,
                                          ),
                                        ),
                                      );
                                      _loadApplicationData();
                                    },
                                    icon: Icon(
                                      evalResult.status == 'NOT_STARTED' ? Icons.upload_file : Icons.sync,
                                      size: 16,
                                    ),
                                    label: Text(
                                      evalResult.status == 'NOT_STARTED'
                                          ? 'Upload Evidence Document'
                                          : evalResult.status == 'REVIEW'
                                              ? 'Resolve Review / Upload Replacement'
                                              : 'Replace / Upload New Version',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
      bottomSheet: !isSubmitted
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitFinalApplication,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isSubmitting ? 'Submitting Application...' : 'Submit Application to Officer',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GemTheme.primaryNavy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMetricBox(String label, int count, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
    );
  }
}
