import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../models/tender_models.dart';
import 'application_detail_screen.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  List<BidderApplicationModel> _applications = [];
  List<TenderModel> _tenders = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'ALL';

  final List<String> _filterTabs = ['ALL', 'IN_PROGRESS', 'SUBMITTED', 'DECIDED'];

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    final apps = await ApiService.fetchApplications();
    final tenders = await ApiService.fetchTenders();

    setState(() {
      _applications = apps;
      _tenders = tenders;
      _isLoading = false;
    });
  }

  TenderModel? _getTenderForApp(String tenderId) {
    return _tenders.firstWhere(
      (t) => t.tenderId == tenderId,
      orElse: () => TenderModel(
        tenderId: tenderId,
        bidNumber: 'GEM/2026/B/9012344',
        title: 'High-Density Campus Switching Infrastructure & Firewall Deployment',
        organization: 'National Informatics Centre Services Inc. (NICSI)',
        ministry: 'Ministry of Electronics & IT',
        category: 'Information Technology (IT)',
        estimatedValue: 125000000.0,
        issueDate: '2026-02-15',
        submissionDeadline: '2026-03-25',
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

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    Color border;

    switch (status.toUpperCase()) {
      case 'DECIDED':
        bg = const Color(0xFFFAF5FF);
        text = const Color(0xFF7E22CE);
        border = const Color(0xFFE9D5FF);
        break;
      case 'SUBMITTED':
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF166534);
        border = const Color(0xFF86EFAC);
        break;
      case 'READY_FOR_REVIEW':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFF92400E);
        border = const Color(0xFFFCD34D);
        break;
      default:
        bg = const Color(0xFFEFF6FF);
        text = const Color(0xFF1D4ED8);
        border = const Color(0xFFBFDBFE);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tender Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterTabs.map((tab) {
                  final isSelected = _selectedStatusFilter == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(
                        tab.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedStatusFilter = tab;
                        });
                      },
                      selectedColor: GemTheme.primaryNavy,
                      backgroundColor: const Color(0xFFF8FAFC),
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? GemTheme.primaryNavy : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Applications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: GemTheme.saffron))
                : _filteredApplications.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 56, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'No applications in this view',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                            SizedBox(height: 6),
                            Text('Browse published tenders to start a new application.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadApplications,
                        color: GemTheme.saffron,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredApplications.length,
                          itemBuilder: (context, index) {
                            final app = _filteredApplications[index];
                            final tender = _getTenderForApp(app.tenderId);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              elevation: 1,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  if (tender != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ApplicationDetailScreen(
                                          applicationId: app.applicationId,
                                          tender: tender,
                                        ),
                                      ),
                                    ).then((_) => _loadApplications());
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: GemTheme.primaryNavy.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              app.applicationId,
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy),
                                            ),
                                          ),
                                          _buildStatusBadge(app.overallStatus),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        tender?.title ?? 'Tender Application: ${app.tenderId}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        tender?.organization ?? 'National Informatics Centre',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      ),
                                      if (app.finalDecision != null) ...[
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: app.finalDecision == 'QUALIFIED' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: app.finalDecision == 'QUALIFIED' ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                app.finalDecision == 'QUALIFIED' ? Icons.verified : Icons.cancel,
                                                size: 16,
                                                color: app.finalDecision == 'QUALIFIED' ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Officer Decision: ${app.finalDecision}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: app.finalDecision == 'QUALIFIED' ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const Divider(height: 22, color: Color(0xFFF1F5F9)),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Submitted: ${app.submittedAt.split("T").first}',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                          ),
                                          const Row(
                                            children: [
                                              Text(
                                                'Open Workspace',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GemTheme.primaryNavy),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(Icons.arrow_forward, size: 14, color: GemTheme.primaryNavy),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
