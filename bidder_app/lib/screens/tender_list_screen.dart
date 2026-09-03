import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../models/tender_models.dart';
import 'tender_detail_screen.dart';
import 'tender_pdf_viewer_screen.dart';

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

  final List<String> _categories = ['ALL', 'GOODS', 'SERVICES', 'WORKS', 'INFORMATION TECHNOLOGY'];

  @override
  void initState() {
    super.initState();
    _loadTenders();
  }

  Future<void> _loadTenders() async {
    setState(() => _isLoading = true);
    final data = await ApiService.fetchTenders();
    setState(() {
      _tenders = data;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    setState(() {
      _filteredTenders = _tenders.where((t) {
        // Show only published tenders
        final isPublished = t.status.isEmpty || t.status.toUpperCase() == 'PUBLISHED';
        final matchesQuery = _searchQuery.isEmpty ||
            t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.bidNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.organization.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategory = _selectedCategory == 'ALL' ||
            t.category.toUpperCase().contains(_selectedCategory);
        return isPublished && matchesQuery && matchesCategory;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: GemTheme.saffron,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'GeM',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Live National Tenders',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Tenders',
            onPressed: _loadTenders,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTenders,
        color: GemTheme.saffron,
        child: Column(
          children: [
            // Search and Category Filter Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilter();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by Bid Number, Title, Ministry...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, size: 20, color: GemTheme.primaryNavy),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = cat;
                                _applyFilter();
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
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: GemTheme.saffron),
                          SizedBox(height: 16),
                          Text(
                            'Connecting to GeM Verification Cloud...',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: GemTheme.primaryNavy),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Cloud services may take a moment to wake up on first load.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  : _filteredTenders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off, size: 56, color: Colors.grey),
                              const SizedBox(height: 12),
                              const Text(
                                'No matching tenders found',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              const Text('Try adjusting your search criteria or category filter.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedCategory = 'ALL';
                                    _applyFilter();
                                  });
                                },
                                icon: const Icon(Icons.filter_alt_off, size: 16),
                                label: const Text('Reset Filters'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTenders.length,
                          itemBuilder: (context, index) {
                            final tender = _filteredTenders[index];
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TenderDetailScreen(tender: tender),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
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
                                                color: GemTheme.primaryNavy.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: GemTheme.primaryNavy.withValues(alpha: 0.2)),
                                              ),
                                              child: Text(
                                                tender.bidNumber,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: GemTheme.primaryNavy,
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
                                      const SizedBox(height: 10),
                                      Text(
                                        tender.title,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.account_balance, size: 14, color: Color(0xFF64748B)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              tender.organization,
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.category_outlined, size: 14, color: Color(0xFF64748B)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              tender.category,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${tender.requirements.length} Clauses',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: GemTheme.primaryNavy),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 22, color: Color(0xFFF1F5F9)),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Estimated Value', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _formatValue(tender.estimatedValue),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: GemTheme.primaryNavy,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 6,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                const Text('Submission Deadline', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                const SizedBox(height: 2),
                                                Text(
                                                  tender.submissionDeadline.isEmpty ? 'As per GeM Notice' : tender.submissionDeadline,
                                                  maxLines: 2,
                                                  textAlign: TextAlign.end,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFFC2410C),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      // Direct Action Buttons: [ VIEW TENDER ] & [ APPLY ]
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => TenderPdfViewerScreen(tender: tender),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFFDC2626)),
                                              label: const Text(
                                                'VIEW TENDER',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: GemTheme.primaryNavy,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => TenderDetailScreen(tender: tender),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                                              label: const Text(
                                                'APPLY',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: GemTheme.primaryNavy,
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
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
          ],
        ),
      ),
    );
  }
}
