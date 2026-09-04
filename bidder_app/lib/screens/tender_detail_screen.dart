import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../core/api_service.dart';
import '../models/tender_models.dart';
import '../widgets/gov_card.dart';
import '../widgets/gov_buttons.dart';
import '../widgets/status_badge.dart';
import '../widgets/state_views.dart';
import 'application_detail_screen.dart';
import 'tender_pdf_viewer_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GeM Compliance — Tender Details Screen
/// Sections 14 & 15: Government-grade structured procurement breakdown
/// ─────────────────────────────────────────────────────────────────────────────

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

    try {
      final existingApps = await ApiService.fetchApplications(tenderId: widget.tender.tenderId);
      BidderApplicationModel? app;

      if (existingApps.isNotEmpty) {
        app = existingApps.first;
      } else {
        app = await ApiService.createApplication(widget.tender.tenderId);
      }

      if (!mounted) return;
      setState(() => _isCreatingApplication = false);

      final appId = app?.applicationId ?? 'APP-${widget.tender.tenderId.replaceAll("TENDER-", "")}-001';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ApplicationDetailScreen(
            applicationId: appId,
            tender: widget.tender,
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _isCreatingApplication = false);
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

  @override
  Widget build(BuildContext context) {
    final tender = widget.tender;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tender Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'View Official Document',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TenderPdfViewerScreen(
                    tender: tender,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Header Card
            _buildHeroCard(tender),
            const SizedBox(height: AppSpacing.lg),

            // SECTION 1: Tender Overview
            _buildOverviewSection(tender),
            const SizedBox(height: AppSpacing.lg),

            // SECTION 2: Important Dates (Timeline)
            _buildDatesSection(tender),
            const SizedBox(height: AppSpacing.lg),

            // SECTION 3: Financial Requirements
            _buildFinancialSection(tender),
            const SizedBox(height: AppSpacing.lg),

            // SECTION 4: Eligibility Criteria
            if (tender.eligibilityCriteria.isNotEmpty) ...[
              _buildTextSection('Eligibility Criteria', tender.eligibilityCriteria, Icons.verified_user_outlined),
              const SizedBox(height: AppSpacing.lg),
            ],

            // SECTION 5: Technical Requirements
            if (tender.technicalRequirements.isNotEmpty) ...[
              _buildTextSection('Technical Requirements', tender.technicalRequirements, Icons.memory_rounded),
              const SizedBox(height: AppSpacing.lg),
            ],

            // SECTION 6: Compliance Requirements Cards
            _buildRequirementsSection(tender),
            const SizedBox(height: AppSpacing.xxl),

            // Bottom CTA Button
            PrimaryGovButton(
              label: 'Apply for Tender',
              icon: Icons.assignment_turned_in_rounded,
              isLoading: _isCreatingApplication,
              onPressed: _handleApply,
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryGovButton(
              label: 'View Official GeM PDF Document',
              icon: Icons.description_outlined,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TenderPdfViewerScreen(
                      tender: tender,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(TenderModel tender) {
    return GovCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  tender.bidNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              StatusBadge(status: tender.status, compact: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            tender.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.account_balance_rounded, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tender.organization,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(TenderModel tender) {
    return GovCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Tender Overview',
            subtitle: 'Administrative and classification details',
          ),
          InfoRow(label: 'Ministry', value: tender.ministry.isNotEmpty ? tender.ministry : 'Not specified'),
          InfoRow(label: 'Department', value: tender.department.isNotEmpty ? tender.department : 'Not specified'),
          InfoRow(label: 'Category', value: tender.category),
          InfoRow(label: 'Item Description', value: tender.itemDescription.isNotEmpty ? tender.itemDescription : tender.title),
          InfoRow(label: 'Total Quantity', value: '${tender.quantity.toInt()} ${tender.unit}'),
          InfoRow(label: 'Delivery Period', value: tender.deliveryPeriod.isNotEmpty ? tender.deliveryPeriod : 'As per Bid specifications'),
          if (tender.placeOfDelivery.isNotEmpty)
            InfoRow(label: 'Place of Delivery', value: tender.placeOfDelivery),
        ],
      ),
    );
  }

  Widget _buildDatesSection(TenderModel tender) {
    return GovCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Important Dates',
            subtitle: 'Procurement schedule and submission timeline',
          ),
          _buildTimelineTile(
            title: 'Issue Date',
            date: tender.issueDate.isNotEmpty ? tender.issueDate : 'Published',
            icon: Icons.calendar_today_rounded,
            isFirst: true,
          ),
          _buildTimelineTile(
            title: 'Submission Deadline',
            date: tender.submissionDeadline,
            icon: Icons.alarm_rounded,
            isHighlighted: true,
          ),
          _buildTimelineTile(
            title: 'Bid Opening Date',
            date: tender.bidOpeningDate.isNotEmpty ? tender.bidOpeningDate : 'Following deadline',
            icon: Icons.meeting_room_rounded,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile({
    required String title,
    required String date,
    required IconData icon,
    bool isHighlighted = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlighted ? AppColors.warningBg : AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: isHighlighted ? AppColors.warning : AppColors.primaryNavy,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
                    color: isHighlighted ? AppColors.warning : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSection(TenderModel tender) {
    return GovCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Financial Information',
            subtitle: 'Security deposit, valuation, and validity terms',
          ),
          InfoRow(
            label: 'Estimated Value',
            value: _formatValue(tender.estimatedValue),
            isBold: true,
          ),
          InfoRow(
            label: 'EMD Requirement',
            value: tender.emdRequired && tender.emdAmount > 0
                ? '₹${tender.emdAmount.toStringAsFixed(0)}'
                : 'Not Required',
          ),
          InfoRow(
            label: 'Performance Security',
            value: tender.performanceSecurity.isNotEmpty ? tender.performanceSecurity : 'Not Required',
          ),
          InfoRow(
            label: 'Bid Validity',
            value: tender.bidValidity.isNotEmpty ? tender.bidValidity : '180 Days',
          ),
        ],
      ),
    );
  }

  Widget _buildTextSection(String title, String content, IconData icon) {
    return GovCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryNavy),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsSection(TenderModel tender) {
    final reqs = tender.requirements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Clause Compliance Requirements',
          subtitle: '${reqs.length} mandatory and evaluated criteria',
        ),
        if (reqs.isEmpty)
          const GovCard(
            child: Text(
              'No explicit parsed clause requirements found. General GeM standard clauses apply.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          )
        else
          ...reqs.map((req) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: GovCard(
                elevated: true,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        StatusBadge(status: req.requirementType, compact: true),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      req.description,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                    ),
                    if (req.expectedDocumentTypes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: req.expectedDocumentTypes.map((doc) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.infoBg,
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                              border: Border.all(color: AppColors.infoBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.attach_file_rounded, size: 10, color: AppColors.info),
                                const SizedBox(width: 3),
                                Text(
                                  doc.replaceAll('_', ' '),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.info),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
