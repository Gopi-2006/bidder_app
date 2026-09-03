import React, { useState } from 'react';
import { FileUp, CheckCircle, AlertCircle, Loader2, X, FileText, CloudUpload, Lock } from 'lucide-react';
import { apiService } from '../services/api';

export default function TenderUploadModal({ isOpen, onClose, onTenderCreated }) {
  const [formData, setFormData] = useState({
    tenderId: `TENDER-${new Date().getFullYear()}-${Math.floor(100 + Math.random() * 900)}`,
    bidNumber: `GEM/${new Date().getFullYear()}/B/${Math.floor(1000000 + Math.random() * 9000000)}`,
    title: '',
    organization: 'National Informatics Centre Services Inc. (NICSI)',
    ministry: 'Ministry of Electronics and Information Technology',
    category: 'GOODS',
    estimatedValue: '5000000',
    submissionDeadline: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
  });

  const [selectedFile, setSelectedFile] = useState(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [uploadStep, setUploadStep] = useState(''); // 'creating', 'uploading_drive', 'complete'
  const [errorMsg, setErrorMsg] = useState(null);
  const [successData, setSuccessData] = useState(null);

  if (!isOpen) return null;

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      if (!file.name.toLowerCase().endsWith('.pdf') && file.type !== 'application/pdf') {
        setErrorMsg('Invalid file type. Only PDF documents are allowed.');
        setSelectedFile(null);
        return;
      }
      if (file.size > 25 * 1024 * 1024) {
        setErrorMsg('File exceeds 25MB limit.');
        setSelectedFile(null);
        return;
      }
      setErrorMsg(null);
      setSelectedFile(file);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.title.trim()) {
      setErrorMsg('Please enter a tender title.');
      return;
    }
    if (!selectedFile) {
      setErrorMsg('Please select a tender PDF document to upload.');
      return;
    }

    setIsSubmitting(true);
    setErrorMsg(null);

    try {
      setUploadStep('Creating Google Drive folder, uploading PDF, & indexing in Firestore...');
      const createdTender = await apiService.createTenderWithDocument({
        tender_id: formData.tenderId,
        bid_number: formData.bidNumber,
        title: formData.title,
        organization: formData.organization,
        ministry: formData.ministry,
        category: formData.category,
        estimated_value: parseFloat(formData.estimatedValue) || 0,
        issue_date: new Date().toISOString().split('T')[0],
        submission_deadline: formData.submissionDeadline,
        status: 'PUBLISHED',
      }, selectedFile);

      setUploadStep('complete');
      setSuccessData({
        tenderId: createdTender.tender_id || formData.tenderId,
        bidNumber: createdTender.bid_number || formData.bidNumber,
        fileName: createdTender.file_name || selectedFile.name,
        driveFileId: createdTender.original_file_id,
        driveFolderId: createdTender.drive_folder_id,
        status: createdTender.status || 'PUBLISHED',
      });

      if (onTenderCreated) {
        onTenderCreated();
      }
    } catch (err) {
      console.error(err);
      setErrorMsg(err.response?.data?.detail || 'Failed to upload tender document. Please check connection.');
      setUploadStep('');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div style={{
      position: 'fixed',
      top: 0, left: 0, right: 0, bottom: 0,
      backgroundColor: 'rgba(15, 23, 42, 0.65)',
      backdropFilter: 'blur(4px)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 1000,
      padding: 20
    }}>
      <div style={{
        backgroundColor: '#FFFFFF',
        borderRadius: 16,
        maxWidth: 640,
        width: '100%',
        maxHeight: '90vh',
        overflowY: 'auto',
        boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
        border: '1px solid #E2E8F0'
      }}>
        {/* Modal Header */}
        <div style={{
          padding: '20px 24px',
          borderBottom: '1px solid #E2E8F0',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          backgroundColor: '#0F172A',
          color: '#FFFFFF',
          borderTopLeftRadius: 16,
          borderTopRightRadius: 16
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{
              width: 36, height: 36, borderRadius: 8,
              backgroundColor: '#EA580C',
              display: 'flex', alignItems: 'center', justifyContent: 'center'
            }}>
              <CloudUpload size={20} color="#FFFFFF" />
            </div>
            <div>
              <h2 style={{ fontSize: 18, fontWeight: 700 }}>Publish Official Tender Notice</h2>
              <p style={{ fontSize: 12, color: '#94A3B8' }}>Automated Google Drive & Firestore Sync</p>
            </div>
          </div>
          <button
            onClick={onClose}
            style={{
              background: 'transparent',
              border: 'none',
              color: '#94A3B8',
              padding: 6,
              borderRadius: 6,
              display: 'flex'
            }}
          >
            <X size={20} />
          </button>
        </div>

        {/* Modal Body */}
        <div style={{ padding: 24 }}>
          {successData ? (
            <div style={{ textAlign: 'center', padding: '16px 0' }}>
              <div style={{
                width: 64, height: 64, borderRadius: '50%',
                backgroundColor: '#DCFCE7',
                color: '#16A34A',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                margin: '0 auto 16px auto'
              }}>
                <CheckCircle size={36} />
              </div>
              <h3 style={{ fontSize: 20, fontWeight: 700, color: '#0F172A', marginBottom: 8 }}>
                Tender Published Successfully!
              </h3>
              <p style={{ fontSize: 14, color: '#475569', marginBottom: 20 }}>
                The tender document has been securely stored in Google Drive and indexed in Cloud Firestore. It is now live in the Bidder Mobile App.
              </p>

              <div style={{
                backgroundColor: '#F8FAFC',
                border: '1px solid #E2E8F0',
                borderRadius: 12,
                padding: 16,
                textAlign: 'left',
                marginBottom: 24,
                fontSize: 13
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: '1px solid #EDF2F7' }}>
                  <span style={{ color: '#64748B' }}>Tender ID:</span>
                  <strong style={{ color: '#1E3A8A' }}>{successData.tenderId}</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: '1px solid #EDF2F7' }}>
                  <span style={{ color: '#64748B' }}>Bid Number:</span>
                  <strong>{successData.bidNumber}</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: '1px solid #EDF2F7' }}>
                  <span style={{ color: '#64748B' }}>Uploaded File:</span>
                  <span style={{ color: '#0F172A' }}>{successData.fileName}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: '1px solid #EDF2F7' }}>
                  <span style={{ color: '#64748B' }}>Google Drive File ID:</span>
                  <code style={{ fontSize: 11, background: '#E2E8F0', padding: '2px 6px', borderRadius: 4 }}>
                    {successData.driveFileId}
                  </code>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0' }}>
                  <span style={{ color: '#64748B' }}>Status:</span>
                  <span style={{
                    color: '#166534',
                    background: '#DCFCE7',
                    fontWeight: 700,
                    fontSize: 11,
                    padding: '2px 8px',
                    borderRadius: 12
                  }}>
                    {successData.status}
                  </span>
                </div>
              </div>

              <button
                onClick={onClose}
                style={{
                  backgroundColor: '#1E3A8A',
                  color: '#FFFFFF',
                  border: 'none',
                  padding: '12px 28px',
                  borderRadius: 8,
                  fontWeight: 600,
                  fontSize: 14
                }}
              >
                Close & Return to Dashboard
              </button>
            </div>
          ) : (
            <form onSubmit={handleSubmit}>
              {errorMsg && (
                <div style={{
                  backgroundColor: '#FEF2F2',
                  border: '1px solid #FECACA',
                  borderRadius: 8,
                  padding: '12px 16px',
                  color: '#B91C1C',
                  fontSize: 13,
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  marginBottom: 16
                }}>
                  <AlertCircle size={18} />
                  <span>{errorMsg}</span>
                </div>
              )}

              {/* Form Grid */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 16 }}>
                <div>
                  <label style={{ display: 'block', fontSize: 12, fontWeight: 600, color: '#475569', marginBottom: 6 }}>
                    Tender Identifier *
                  </label>
                  <input
                    type="text"
                    value={formData.tenderId}
                    onChange={(e) => setFormData({ ...formData, tenderId: e.target.value })}
                    required
                    style={{
                      width: '100%',
                      padding: '10px 12px',
                      border: '1px solid #CBD5E1',
                      borderRadius: 8,
                      fontSize: 13,
                      backgroundColor: '#F8FAFC'
                    }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: 12, fontWeight: 600, color: '#475569', marginBottom: 6 }}>
                    GeM Bid Number *
                  </label>
                  <input
                    type="text"
                    value={formData.bidNumber}
                    onChange={(e) => setFormData({ ...formData, bidNumber: e.target.value })}
                    required
                    style={{
                      width: '100%',
                      padding: '10px 12px',
                      border: '1px solid #CBD5E1',
                      borderRadius: 8,
                      fontSize: 13
                    }}
                  />
                </div>
              </div>

              <div style={{ marginBottom: 16 }}>
                <label style={{ display: 'block', fontSize: 12, fontWeight: 600, color: '#475569', marginBottom: 6 }}>
                  Tender Title / Scope of Work *
                </label>
                <input
                  type="text"
                  placeholder="e.g. Supply and Commissioning of Enterprise Network Infrastructure"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  required
                  style={{
                    width: '100%',
                    padding: '10px 12px',
                    border: '1px solid #CBD5E1',
                    borderRadius: 8,
                    fontSize: 13
                  }}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 16 }}>
                <div>
                  <label style={{ display: 'block', fontSize: 12, fontWeight: 600, color: '#475569', marginBottom: 6 }}>
                    Procuring Organization
                  </label>
                  <input
                    type="text"
                    value={formData.organization}
                    onChange={(e) => setFormData({ ...formData, organization: e.target.value })}
                    style={{
                      width: '100%',
                      padding: '10px 12px',
                      border: '1px solid #CBD5E1',
                      borderRadius: 8,
                      fontSize: 13
                    }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: 12, fontWeight: 600, color: '#475569', marginBottom: 6 }}>
                    Procurement Category
                  </label>
                  <select
                    value={formData.category}
                    onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                    style={{
                      width: '100%',
                      padding: '10px 12px',
                      border: '1px solid #CBD5E1',
                      borderRadius: 8,
                      fontSize: 13
                    }}
                  >
                    <option value="GOODS">GOODS (Hardware/Equipment)</option>
                    <option value="SERVICES">SERVICES (Managed IT/Cloud)</option>
                    <option value="WORKS">WORKS (Civil/Turnkey)</option>
                    <option value="INFORMATION TECHNOLOGY">INFORMATION TECHNOLOGY</option>
                  </select>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 20 }}>
                <div>
                  <label style={{ display: 'block', fontSize: 12, fontWeight: 600, color: '#475569', marginBottom: 6 }}>
                    Estimated Project Value (INR ₹)
                  </label>
                  <input
                    type="number"
                    value={formData.estimatedValue}
                    onChange={(e) => setFormData({ ...formData, estimatedValue: e.target.value })}
                    style={{
                      width: '100%',
                      padding: '10px 12px',
                      border: '1px solid #CBD5E1',
                      borderRadius: 8,
                      fontSize: 13
                    }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: 12, fontWeight: 600, color: '#475569', marginBottom: 6 }}>
                    Bid Submission Deadline
                  </label>
                  <input
                    type="date"
                    value={formData.submissionDeadline}
                    onChange={(e) => setFormData({ ...formData, submissionDeadline: e.target.value })}
                    style={{
                      width: '100%',
                      padding: '10px 12px',
                      border: '1px solid #CBD5E1',
                      borderRadius: 8,
                      fontSize: 13
                    }}
                  />
                </div>
              </div>

              {/* PDF Document Upload Box */}
              <div style={{ marginBottom: 24 }}>
                <label style={{ display: 'block', fontSize: 12, fontWeight: 600, color: '#475569', marginBottom: 6 }}>
                  Upload Official Tender Document (PDF) *
                </label>
                <div style={{
                  border: selectedFile ? '2px solid #16A34A' : '2px dashed #CBD5E1',
                  borderRadius: 12,
                  padding: 20,
                  textAlign: 'center',
                  backgroundColor: selectedFile ? '#F0FDF4' : '#F8FAFC',
                  cursor: 'pointer',
                  position: 'relative'
                }}>
                  <input
                    type="file"
                    accept=".pdf,application/pdf"
                    onChange={handleFileChange}
                    style={{
                      position: 'absolute',
                      top: 0, left: 0, right: 0, bottom: 0,
                      opacity: 0,
                      cursor: 'pointer'
                    }}
                  />
                  {selectedFile ? (
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12 }}>
                      <FileText size={32} color="#16A34A" />
                      <div style={{ textAlign: 'left' }}>
                        <p style={{ fontSize: 14, fontWeight: 600, color: '#166534' }}>{selectedFile.name}</p>
                        <p style={{ fontSize: 12, color: '#65A30D' }}>
                          {(selectedFile.size / (1024 * 1024)).toFixed(2)} MB • Ready for Google Drive upload
                        </p>
                      </div>
                    </div>
                  ) : (
                    <div>
                      <FileUp size={36} color="#64748B" style={{ margin: '0 auto 8px auto' }} />
                      <p style={{ fontSize: 14, fontWeight: 600, color: '#334155' }}>
                        Drag and drop official Tender PDF here, or click to browse
                      </p>
                      <p style={{ fontSize: 12, color: '#94A3B8', marginTop: 4 }}>
                        Accepts standard RFP/NIT notices up to 25MB (.pdf)
                      </p>
                    </div>
                  )}
                </div>
              </div>

              {/* Progress feedback */}
              {isSubmitting && (
                <div style={{
                  backgroundColor: '#EFF6FF',
                  border: '1px solid #BFDBFE',
                  borderRadius: 8,
                  padding: '12px 16px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 12,
                  marginBottom: 16,
                  color: '#1E40AF',
                  fontSize: 13
                }}>
                  <Loader2 size={18} className="animate-spin" />
                  <span>{uploadStep}</span>
                </div>
              )}

              {/* Actions */}
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 12 }}>
                <button
                  type="button"
                  onClick={onClose}
                  disabled={isSubmitting}
                  style={{
                    backgroundColor: '#F1F5F9',
                    color: '#475569',
                    border: '1px solid #E2E8F0',
                    padding: '10px 20px',
                    borderRadius: 8,
                    fontWeight: 600,
                    fontSize: 13
                  }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting || !selectedFile}
                  style={{
                    backgroundColor: '#1E3A8A',
                    color: '#FFFFFF',
                    border: 'none',
                    padding: '10px 24px',
                    borderRadius: 8,
                    fontWeight: 600,
                    fontSize: 13,
                    display: 'flex',
                    alignItems: 'center',
                    gap: 8,
                    opacity: (isSubmitting || !selectedFile) ? 0.7 : 1
                  }}
                >
                  {isSubmitting ? (
                    <>
                      <Loader2 size={16} />
                      <span>Uploading to Google Drive...</span>
                    </>
                  ) : (
                    <>
                      <CloudUpload size={16} />
                      <span>Upload & Publish Tender</span>
                    </>
                  )}
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}
