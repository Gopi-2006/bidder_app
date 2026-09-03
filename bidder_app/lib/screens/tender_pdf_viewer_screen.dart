import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../models/tender_models.dart';

class TenderPdfViewerScreen extends StatefulWidget {
  final TenderModel tender;

  const TenderPdfViewerScreen({
    super.key,
    required this.tender,
  });

  @override
  State<TenderPdfViewerScreen> createState() => _TenderPdfViewerScreenState();
}

class _TenderPdfViewerScreenState extends State<TenderPdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _pageCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchPdf();
  }

  Future<void> _fetchPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bytes = await ApiService.fetchTenderDocumentBytes(widget.tender.tenderId);

      if (bytes != null && bytes.isNotEmpty) {
        if (mounted) {
          setState(() {
            _pdfBytes = bytes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Unable to retrieve tender document from secure storage. Please verify that the backend is running.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection error while streaming document: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tender = widget.tender;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tender.bidNumber,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              tender.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF93C5FD)),
            ),
          ],
        ),
        actions: [
          if (_pageCount > 0)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$_currentPage / $_pageCount',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload PDF',
            onPressed: _isLoading ? null : _fetchPdf,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: GemTheme.saffron,
                  strokeWidth: 3.5,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Loading tender document...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Streaming official GeM PDF securely from Google Drive storage...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.tender.fileName ?? 'tender.pdf',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                const Text(
                  'Unable to Open Tender Document',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _fetchPdf,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GemTheme.saffron,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Security Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF1E293B),
          child: Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF4ADE80)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Official Notice: ${widget.tender.fileName ?? "tender.pdf"} • Authenticated via FastAPI Gateway',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),

        // PDF View
        Expanded(
          child: SfPdfViewer.memory(
            _pdfBytes!,
            controller: _pdfViewerController,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            enableDoubleTapZooming: true,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                _pageCount = details.document.pages.count;
              });
            },
            onPageChanged: (PdfPageChangedDetails details) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
            },
          ),
        ),
      ],
    );
  }
}
