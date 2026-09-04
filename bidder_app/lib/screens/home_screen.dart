import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../core/api_service.dart';
import '../core/firebase/auth_service.dart';
import '../models/tender_models.dart';
import '../widgets/app_logo.dart';
import '../widgets/gov_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/state_views.dart';
import 'tender_detail_screen.dart';
import 'application_detail_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GeM Compliance — Bidder Home Dashboard
/// Section 11, 12, 36: Clean, Official, Structured, Mobile-First
/// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<TenderModel> _tenders = [];
  List<BidderApplicationModel> _applications = [];
  String _companyName = 'Bharat Infotech & Networks Pvt Ltd';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final tenders = await ApiService.fetchTenders();
      final applications = await ApiService.fetchApplications();
      final profile = await ApiService.fetchMeProfile();

      if (mounted) {
        setState(() {
          _tenders = tenders;
          _applications = applications;
          if (profile?.companyName.isNotEmpty ?? false) {
            _companyName = profile!.companyName;
          } else if (FirebaseAuthService.currentCompanyName.isNotEmpty) {
            _companyName = FirebaseAuthService.currentCompanyName;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const GovLoadingSkeleton(count: 3),
      );
    }

    final totalTenders = _tenders.length;
    final totalApps = _applications.length;
    final underReview = _applications.where((a) => a.overallStatus == 'IN_PROGRESS' || a.overallStatus == 'ANALYZING').length;
    final compliant = _applications.where((a) => a.overallStatus == 'COMPLIANT' || a.overallStatus == 'SUBMITTED').length;
    final actionRequired = _applications.where((a) => a.overallStatus == 'ACTION_REQUIRED' || a.overallStatus == 'REJECTED').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppColors.primaryNavy,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Bidder Identity & Greeting Header
              _buildGreetingHeader(),
              const SizedBox(height: AppSpacing.lg),

              // 2. Primary Action Card ("Find Your Next Tender")
              _buildPrimaryActionCard(totalTenders),
              const SizedBox(height: AppSpacing.xl),

              // 3. Compliance Overview Metric Grid
              const SectionHeader(
                title: 'Your Compliance Overview',
                subtitle: 'Cross-checked with official government registries',
              ),
              _buildMetricsGrid(
                totalTenders: totalTenders,
                totalApps: totalApps,
                underReview: underReview,
                compliant: compliant,
                actionRequired: actionRequired,
              ),
              const SizedBox(height: AppSpacing.xl),

              // 4. Recommended Tenders Preview
              SectionHeader(
                title: 'Eligible Live Tenders',
                subtitle: 'Verified matching public procurements',
                trailing: TextButton(
                  onPressed: () => widget.onNavigateTab?.call(1),
                  child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryNavy)),
                ),
              ),
              _buildTendersPreview(),
              const SizedBox(height: AppSpacing.xl),

              // 5. Recent Applications Preview (if any)
              if (_applications.isNotEmpty) ...[
                SectionHeader(
                  title: 'Recent Bid Applications',
                  trailing: TextButton(
                    onPressed: () => widget.onNavigateTab?.call(2),
                    child: const Text('All Applications', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryNavy)),
                  ),
                ),
                _buildApplicationsPreview(),
                const SizedBox(height: AppSpacing.lg),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const AppLogo(
        size: 32,
        showText: true,
        isLightOnDark: true,
        subtitle: 'National Bidder Portal',
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
          onPressed: _loadDashboardData,
        ),
      ],
    );
  }

  Widget _buildGreetingHeader() {
    return GovCard(
      backgroundColor: Colors.white,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business_rounded,
              color: AppColors.primaryNavy,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()},',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusBadge.verified(label: 'Verified Business', compact: true),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionCard(int totalTenders) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.saffron,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: const Text(
                  'OPPORTUNITY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$totalTenders Tenders Active',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Find Your Next Tender',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Discover GeM procurements matching your verified business profile with automated AI compliance pre-check.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => widget.onNavigateTab?.call(1),
              icon: const Icon(Icons.explore_rounded, size: 18, color: AppColors.primaryNavy),
              label: const Text('Explore Tenders'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryNavy,
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid({
    required int totalTenders,
    required int totalApps,
    required int underReview,
    required int compliant,
    required int actionRequired,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                value: '$totalTenders',
                label: 'Eligible Tenders',
                color: AppColors.primaryNavy,
                icon: Icons.travel_explore_rounded,
                onTap: () => widget.onNavigateTab?.call(1),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildMetricTile(
                value: '$totalApps',
                label: 'Applications',
                color: AppColors.info,
                icon: Icons.assignment_rounded,
                onTap: () => widget.onNavigateTab?.call(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                value: '$underReview',
                label: 'Under Review',
                color: AppColors.warning,
                icon: Icons.hourglass_top_rounded,
                onTap: () => widget.onNavigateTab?.call(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildMetricTile(
                value: '$compliant',
                label: 'Compliant',
                color: AppColors.success,
                icon: Icons.verified_rounded,
                onTap: () => widget.onNavigateTab?.call(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildMetricTile(
                value: '$actionRequired',
                label: 'Action Req.',
                color: AppColors.error,
                icon: Icons.priority_high_rounded,
                onTap: () => widget.onNavigateTab?.call(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GovCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
              Icon(icon, size: 18, color: color.withValues(alpha: 0.6)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTendersPreview() {
    final previewList = _tenders.take(3).toList();
    if (previewList.isEmpty) {
      return const GovEmptyState(
        title: 'No tenders found',
        description: 'Tender listings will appear here once retrieved.',
      );
    }

    return Column(
      children: previewList.map((tender) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: GovCard(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TenderDetailScreen(tender: tender),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        tender.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatusBadge(status: tender.status, compact: true),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tender.organization,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        tender.bidNumber,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Deadline: ${tender.submissionDeadline}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildApplicationsPreview() {
    final previewList = _applications.take(2).toList();
    return Column(
      children: previewList.map((app) {
        final tender = _tenders.firstWhere(
          (t) => t.tenderId == app.tenderId,
          orElse: () => TenderModel(
            tenderId: app.tenderId,
            bidNumber: 'GEM/BID/UNKNOWN',
            title: 'Tender Application ${app.applicationId}',
            organization: 'Government Agency',
            issueDate: '',
            submissionDeadline: '',
            status: 'PUBLISHED',
            ruleSetVersion: 'v1.0',
            requirements: [],
          ),
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: GovCard(
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.infoBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment_turned_in_rounded, size: 18, color: AppColors.info),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.applicationId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        tender.bidNumber,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: app.overallStatus, compact: true),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
