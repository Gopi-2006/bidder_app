import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../core/api_service.dart';
import '../models/tender_models.dart';
import '../widgets/gov_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/state_views.dart';
import 'application_detail_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GeM Compliance — My Applications Screen
/// Section 22: Clean government bid tracking cards, filters, and compliance scores
/// ─────────────────────────────────────────────────────────────────────────────

class MyApplicationsScreen extends StatefulWidget {
  final VoidCallback? onExploreTenders;

  const MyApplicationsScreen({super.key, this.onExploreTenders});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  List<BidderApplicationModel> _applications = [];
  List<TenderModel> _tenders = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'ALL';
  String? _errorMessage;

  final List<String> _filterTabs = ['ALL', 'IN_PROGRESS', 'SUBMITTED', 'DECIDED'];

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apps = await ApiService.fetchApplications();
      final tenders = await ApiService.fetchTenders();

      if (mounted) {
        setState(() {
          _applications = apps;
          _tenders = tenders;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to connect to verification service. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  TenderModel _getTenderForApp(String tenderId) {
    return _tenders.firstWhere(
      (t) => t.tenderId == tenderId,
      orElse: () => TenderModel(
        tenderId: tenderId,
        bidNumber: 'GEM/BID/UNKNOWN',
        title: 'Tender Application $tenderId',
        organization: 'Government Procurement Authority',
        issueDate: '',
        submissionDeadline: '',
        status: 'PUBLISHED',
        ruleSetVersion: 'v1.0',
        requirements: [],
      ),
    );
  }

  List<BidderApplicationModel> get _filteredApplications {
    if (_selectedStatusFilter == 'ALL') return _applications;
    return _applications.where((a) => a.overallStatus.toUpperCase() == _selectedStatusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Applications',
            onPressed: _loadApplications,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs Container
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filterTabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final tab = _filterTabs[idx];
                  final isSelected = _selectedStatusFilter == tab;
                  final count = tab == 'ALL'
                      ? _applications.length
                      : _applications.where((a) => a.overallStatus.toUpperCase() == tab).length;

                  return ChoiceChip(
                    label: Text(
                      '${tab.replaceAll('_', ' ')} ($count)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primaryNavy,
                    backgroundColor: AppColors.surfaceElevated,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      side: BorderSide(color: isSelected ? AppColors.primaryNavy : AppColors.border),
                    ),
                    onSelected: (_) => setState(() => _selectedStatusFilter = tab),
                  );
                },
              ),
            ),
          ),

          const Divider(height: 1),

          // Content Body
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const GovLoadingSkeleton(count: 3);
    }

    if (_errorMessage != null) {
      return GovErrorState(
        message: _errorMessage!,
        onRetry: _loadApplications,
      );
    }

    final filtered = _filteredApplications;

    if (filtered.isEmpty) {
      return GovEmptyState(
        icon: Icons.assignment_outlined,
        title: 'You haven\'t started an application yet',
        description: 'Explore active GeM tenders matching your verified enterprise profile.',
        actionLabel: 'Explore Tenders',
        onAction: () {
          widget.onExploreTenders?.call();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      color: AppColors.primaryNavy,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, idx) {
          final app = filtered[idx];
          final tender = _getTenderForApp(app.tenderId);
          return _buildApplicationCard(app, tender);
        },
      ),
    );
  }

  Widget _buildApplicationCard(BidderApplicationModel app, TenderModel tender) {
    final results = app.results;
    final passCount = results.where((r) => r.status.toUpperCase() == 'PASS').length;
    final totalReqs = tender.requirements.isNotEmpty ? tender.requirements.length : results.length;
    final percent = totalReqs > 0 ? ((passCount / totalReqs) * 100).round() : 0;

    return GovCard(
      elevated: true,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ApplicationDetailScreen(
              applicationId: app.applicationId,
              tender: tender,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  app.applicationId,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tender.bidNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                ),
              ),
              StatusBadge(status: app.overallStatus, compact: true),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            tender.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            tender.organization,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.info),
                    const SizedBox(width: 5),
                    Text(
                      'Compliance: $percent%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($passCount/$totalReqs)',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const Text(
                'View Application →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
