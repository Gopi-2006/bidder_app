import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../models/tender_models.dart';
import 'application_detail_screen.dart';
import 'tender_pdf_viewer_screen.dart';

class TenderDetailScreen extends StatefulWidget {
  final TenderModel tender;
  const TenderDetailScreen({super.key, required this.tender});

  @override
  State<TenderDetailScreen> createState() => _TenderDetailScreenState();
}

class _TenderDetailScreenState extends State<TenderDetailScreen> {
  bool _isCreatingApplication = false;

  Future<void> _handleApply() async {
    setState(() => _isCreatingApplication = true);

    // Check if bidder already has an application for this tender
    final existingApps = await ApiService.fetchApplications(tenderId: widget.tender.tenderId);
    BidderApplicationModel? app;

    if (existingApps.isNotEmpty) {
      app = existingApps.first;
    } else {
      // Create new application draft
      app = await ApiService.createApplication(widget.tender.tenderId);
    }

    setState(() => _isCreatingApplication = false);

    if (app != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ApplicationDetailScreen(
            applicationId: app!.applicationId,
            tender: widget.tender,
          ),
        ),
      );
    } else if (mounted) {
      // Fallback with default seed ID if creation returned null in dev mode
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ApplicationDetailScreen(
            applicationId: 'APP-2026-000123',
            tender: widget.tender,
          ),
        ),
      );
    }
  }

  String _formatValue(double? val) {
    if (val == null) return 'Not specified';
    if (val == 0) return '₹0';
    if (val >= 10000000) {
      return '₹${(val / 10000000).toStringAsFixed(2)} Cr';
    } else if (val >= 100000) {
      return '₹${(val / 100000).toStringAsFixed(2)} Lakh';
    }
    return '₹${val.toStringAsFixed(0)}';
  }

  Widget _buildParamRow(String label, String value, {IconData? icon, Color? valueColor}) {
    final displayVal = value.trim().isEmpty ? 'Not specified in tender' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 15, color: const Color(0xFF64748B)),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              displayVal,
              textAlign: TextAlign.end,
              softWrap: true,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tender = widget.tender;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tender.bidNumber.isNotEmpty ? tender.bidNumber : tender.tenderId,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              tender.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFFE2E8F0)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'View Official Tender PDF',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TenderPdfViewerScreen(tender: widget.tender),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic Extraction Status Banner
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: tender.extractionStatus == 'COMPLETED'
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: tender.extractionStatus == 'COMPLETED'
                      ? const Color(0xFFBBF7D0)
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    tender.extractionStatus == 'COMPLETED'
                        ? Icons.verified
                        : Icons.sync,
                    size: 18,
                    color: tender.extractionStatus == 'COMPLETED'
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tender.extractionStatus == 'COMPLETED'
                          ? 'Details dynamically extracted from official GeM Tender PDF'
                          : 'Document extraction in progress...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tender.extractionStatus == 'COMPLETED'
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Tender Overview Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: GemTheme.saffron.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: GemTheme.saffron.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              tender.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC2410C),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tender.status,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      tender.title,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: GemTheme.primaryNavy,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tender.organization,
                      softWrap: true,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    if (tender.department.isNotEmpty && tender.department != tender.organization) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Department: ${tender.department}',
                        softWrap: true,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ],
                    if (tender.ministry.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Ministry: ${tender.ministry}',
                        softWrap: true,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ],
                    const Divider(height: 28),

                    // Key Specifications
                    _buildParamRow('Quantity', '${tender.quantity.toStringAsFixed(0)} ${tender.unit}', icon: Icons.inventory_2_outlined),
                    _buildParamRow('Delivery Period', tender.deliveryPeriod, icon: Icons.local_shipping_outlined),
                    _buildParamRow('Estimated Value', _formatValue(tender.estimatedValue), icon: Icons.currency_rupee, valueColor: GemTheme.primaryNavy),

                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Color(0xFFEA580C), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Bid End / Deadline: ${tender.submissionDeadline.isEmpty ? "As per GeM Schedule" : tender.submissionDeadline}',
                              softWrap: true,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF9A3412)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TenderPdfViewerScreen(tender: widget.tender),
                            ),
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFDC2626), size: 18),
                        label: const Text(
                          'View Official Tender Notice (PDF)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GemTheme.primaryNavy),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tender Schedules & Terms Card
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tender Parameters & Schedules',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy),
                    ),
                    const SizedBox(height: 12),
                    _buildParamRow('Bid Validity', tender.bidValidity, icon: Icons.event_available),
                    if (tender.bidOpeningDate.isNotEmpty)
                      _buildParamRow('Bid Opening Date', tender.bidOpeningDate, icon: Icons.calendar_today_outlined),
                    _buildParamRow(
                      'EMD Requirement',
                      tender.emdRequired ? '₹${tender.emdAmount.toStringAsFixed(0)} Required' : 'Exempted / Not Required',
                      icon: Icons.account_balance_wallet_outlined,
                      valueColor: tender.emdRequired ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                    ),
                    _buildParamRow('Performance Security', tender.performanceSecurity, icon: Icons.security_outlined),
                    _buildParamRow('Turnover Rule', tender.turnoverRequirement, icon: Icons.trending_up),
                    _buildParamRow('Past Performance', tender.experienceRequirement, icon: Icons.history_edu),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Policy Preferences Card
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Procurement Policy Preferences',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy),
                    ),
                    const SizedBox(height: 12),
                    _buildParamRow('MSE Preference', tender.msePreference, icon: Icons.storefront_outlined, valueColor: const Color(0xFF0284C7)),
                    _buildParamRow('Make in India (MII)', tender.makeInIndiaPreference, icon: Icons.flag_outlined, valueColor: const Color(0xFF0284C7)),
                    _buildParamRow('OEM Authorization', tender.oemAuthorizationRequirement ? 'Mandatory (MAF)' : 'Not Required', icon: Icons.verified_user_outlined),
                    if (tender.contactInformation.isNotEmpty)
                      _buildParamRow('Grievance / Contact', tender.contactInformation, icon: Icons.mail_outline),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Requirements Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Eligibility & Compliance Clauses',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: GemTheme.primaryNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tender.requirements.length} Clauses',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Clause Requirements List
            if (tender.requirements.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'Standard GeM General Terms and Conditions (GTC) apply to this tender.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              )
            else
              ...tender.requirements.map((req) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                req.clauseReference,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                              ),
                            ),
                            if (req.mandatory)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'MANDATORY',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                req.requirementType,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          req.title,
                          softWrap: true,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.35),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          req.description,
                          softWrap: true,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.45),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.auto_awesome, size: 13, color: Color(0xFF7C3AED)),
                            const SizedBox(width: 4),
                            Text(
                              'NLP AI Confidence: ${(req.aiConfidence * 100).toInt()}%',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6D28D9), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: Container(
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
            height: 48,
            child: ElevatedButton(
              onPressed: _isCreatingApplication ? null : _handleApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: GemTheme.saffron,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isCreatingApplication
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'START / CONTINUE APPLICATION',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
