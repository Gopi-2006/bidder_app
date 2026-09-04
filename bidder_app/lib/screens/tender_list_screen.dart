import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../core/api_service.dart';
import '../models/tender_models.dart';
import '../widgets/gov_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/state_views.dart';
import 'tender_detail_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GeM Compliance — National Tender Catalog
/// Section 13: Government tender portal aesthetic, clean cards, search & filter
/// ─────────────────────────────────────────────────────────────────────────────

class TenderListScreen extends StatefulWidget {
  const TenderListScreen({super.key});

  @override
  State<TenderListScreen> createState() => _TenderListScreenState();
}

class _TenderListScreenState extends State<TenderListScreen> {
  List<TenderModel> _tenders = [];
  List<TenderModel> _filteredTenders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'ALL';
  String? _errorMessage;

  final List<String> _categories = [
    'ALL',
    'GOODS',
    'SERVICES',
    'WORKS',
    'INFORMATION TECHNOLOGY',
  ];

  @override
  void initState() {
    super.initState();
    _loadTenders();
  }

  Future<void> _loadTenders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.fetchTenders();
      if (mounted) {
        setState(() {
          _tenders = data;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to connect to verification service. Please check your internet connection.';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredTenders = _tenders.where((t) {
        final matchesQuery = _searchQuery.isEmpty ||
            t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.bidNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.organization.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.category.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesCategory = _selectedCategory == 'ALL' ||
            t.category.toUpperCase().contains(_selectedCategory);

        return matchesQuery && matchesCategory;
      }).toList();
    });
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

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'ALL';
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tenders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Tenders',
            onPressed: _loadTenders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              children: [
                // Search Input
                TextField(
                  onChanged: (val) {
                    _searchQuery = val.trim();
                    _applyFilter();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by title, bid number or category...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchQuery = '';
                              _applyFilter();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Category Chips
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final cat = _categories[idx];
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(
                          cat == 'ALL' ? 'All Tenders (${_tenders.length})' : cat,
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
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryNavy : AppColors.border,
                          ),
                        ),
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = cat;
                            _applyFilter();
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Main Body
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const GovLoadingSkeleton(count: 4);
    }

    if (_errorMessage != null) {
      return GovErrorState(
        message: _errorMessage!,
        onRetry: _loadTenders,
      );
    }

    if (_filteredTenders.isEmpty) {
      return GovEmptyState(
        title: 'No matching tenders found',
        description: 'Try changing your search keywords or category filters.',
        actionLabel: 'Clear Filters',
        onAction: _clearFilters,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTenders,
      color: AppColors.primaryNavy,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _filteredTenders.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, idx) {
          final tender = _filteredTenders[idx];
          return _buildTenderCard(tender);
        },
      ),
    );
  }

  Widget _buildTenderCard(TenderModel tender) {
    final emdText = tender.emdRequired && tender.emdAmount > 0
        ? '₹${tender.emdAmount.toStringAsFixed(0)}'
        : 'Not Required';

    final valueText = _formatValue(tender.estimatedValue);

    return GovCard(
      elevated: true,
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
          // Row 1: Bid Number & Category Badge + Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  tender.bidNumber,
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
                  tender.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              StatusBadge(status: tender.status, compact: true),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Row 2: Tender Title (Auto-wrapping, zero overflow)
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

          // Row 3: Organization
          Row(
            children: [
              const Icon(Icons.account_balance_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tender.organization,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          // Row 4: Key Metadata Attributes
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quantity', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    const SizedBox(height: 1),
                    Text(
                      '${tender.quantity.toInt()} ${tender.unit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Est. Value', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    const SizedBox(height: 1),
                    Text(
                      valueText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('EMD', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    const SizedBox(height: 1),
                    Text(
                      emdText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Row 5: Submission Deadline + View Button
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Submission: ${tender.submissionDeadline}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
              const Text(
                'View Tender →',
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
