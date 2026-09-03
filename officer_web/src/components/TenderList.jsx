import React from 'react';
import { FileText, ExternalLink, Calendar, Building, Tag, DollarSign, CheckCircle2, Download } from 'lucide-react';
import { apiService } from '../services/api';

export default function TenderList({ tenders, isLoading, onRefresh }) {
  const formatCurrency = (val) => {
    if (!val) return '₹0';
    if (val >= 10000000) return `₹${(val / 10000000).toFixed(2)} Cr`;
    if (val >= 100000) return `₹${(val / 100000).toFixed(2)} Lakh`;
    return `₹${val.toLocaleString('en-IN')}`;
  };

  if (isLoading) {
    return (
      <div style={{ padding: 48, textAlign: 'center', color: '#64748B' }}>
        <div style={{
          width: 40, height: 40,
          border: '3px solid #E2E8F0',
          borderTopColor: '#1E3A8A',
          borderRadius: '50%',
          animation: 'spin 1s linear infinite',
          margin: '0 auto 16px auto'
        }} />
        <p style={{ fontSize: 14 }}>Loading published tenders from platform...</p>
        <style>{`@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }`}</style>
      </div>
    );
  }

  if (!tenders || tenders.length === 0) {
    return (
      <div style={{
        padding: 48,
        textAlign: 'center',
        backgroundColor: '#FFFFFF',
        borderRadius: 12,
        border: '1px solid #E2E8F0'
      }}>
        <FileText size={48} color="#94A3B8" style={{ margin: '0 auto 12px auto' }} />
        <h3 style={{ fontSize: 16, fontWeight: 600, color: '#1E293B' }}>No Tenders Published Yet</h3>
        <p style={{ fontSize: 13, color: '#64748B', marginTop: 4 }}>
          Click "Publish New Tender" to upload your first tender RFP notice PDF to Google Drive.
        </p>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      {tenders.map((tender) => {
        const docUrl = apiService.getTenderDocumentUrl(tender.tender_id || tender.tenderId);
        const fileId = tender.original_file_id || tender.originalFileId || tender.source_drive_file_id;

        return (
          <div
            key={tender.tender_id || tender.tenderId}
            style={{
              backgroundColor: '#FFFFFF',
              borderRadius: 12,
              border: '1px solid #E2E8F0',
              padding: 20,
              boxShadow: '0 1px 3px rgba(0, 0, 0, 0.05)',
              transition: 'all 0.2s ease',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 16, marginBottom: 12 }}>
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
                  <span style={{
                    backgroundColor: '#EFF6FF',
                    color: '#1E3A8A',
                    fontSize: 11,
                    fontWeight: 700,
                    padding: '2px 8px',
                    borderRadius: 6,
                    border: '1px solid #BFDBFE'
                  }}>
                    {tender.bid_number || tender.bidNumber}
                  </span>
                  <span style={{
                    backgroundColor: '#DCFCE7',
                    color: '#166534',
                    fontSize: 10,
                    fontWeight: 700,
                    padding: '2px 8px',
                    borderRadius: 10,
                  }}>
                    {tender.status}
                  </span>
                </div>
                <h3 style={{ fontSize: 16, fontWeight: 700, color: '#0F172A', lineHeight: 1.4 }}>
                  {tender.title}
                </h3>
              </div>

              <a
                href={docUrl}
                target="_blank"
                rel="noreferrer"
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: 6,
                  backgroundColor: '#0F172A',
                  color: '#FFFFFF',
                  padding: '8px 16px',
                  borderRadius: 8,
                  fontSize: 13,
                  fontWeight: 600,
                  textDecoration: 'none',
                  whiteSpace: 'nowrap'
                }}
              >
                <Download size={15} />
                <span>View Stored PDF</span>
              </a>
            </div>

            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
              gap: 12,
              padding: '12px 16px',
              backgroundColor: '#F8FAFC',
              borderRadius: 8,
              fontSize: 12,
              color: '#475569',
              marginTop: 12
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <Building size={14} color="#64748B" />
                <span style={{ textOverflow: 'ellipsis', overflow: 'hidden', whiteSpace: 'nowrap' }}>
                  {tender.organization}
                </span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <Tag size={14} color="#64748B" />
                <span>{tender.category}</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <DollarSign size={14} color="#166534" />
                <strong style={{ color: '#0F172A' }}>
                  {formatCurrency(tender.estimated_value || tender.estimatedValue)}
                </strong>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <Calendar size={14} color="#EA580C" />
                <span>Deadline: {tender.submission_deadline || tender.submissionDeadline}</span>
              </div>
            </div>

            {fileId && (
              <div style={{
                marginTop: 10,
                display: 'flex',
                alignItems: 'center',
                gap: 8,
                fontSize: 11,
                color: '#64748B'
              }}>
                <span>Google Drive Storage ID:</span>
                <code style={{ background: '#F1F5F9', padding: '2px 6px', borderRadius: 4, color: '#334155' }}>
                  {fileId}
                </code>
                {tender.file_name && (
                  <span style={{ marginLeft: 8, color: '#94A3B8' }}>• File: {tender.file_name}</span>
                )}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
