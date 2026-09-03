import React, { useState, useEffect } from 'react';
import {
  Shield,
  FilePlus,
  RefreshCw,
  FolderTree,
  Database,
  Smartphone,
  ExternalLink,
  Layers,
  Sparkles,
} from 'lucide-react';
import { apiService } from './services/api';
import TenderList from './components/TenderList';
import TenderUploadModal from './components/TenderUploadModal';

export default function App() {
  const [tenders, setTenders] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [officerProfile, setOfficerProfile] = useState(null);

  const fetchTenders = async () => {
    setIsLoading(true);
    try {
      const data = await apiService.getTenders();
      setTenders(data);
    } catch (err) {
      console.error('Error fetching tenders:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const fetchProfile = async () => {
    try {
      const profile = await apiService.getProfile();
      setOfficerProfile(profile);
    } catch (err) {
      console.error('Error fetching officer profile:', err);
    }
  };

  useEffect(() => {
    fetchTenders();
    fetchProfile();
  }, []);

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      {/* Top Government of India / GeM Header */}
      <header style={{
        backgroundColor: '#0F172A',
        color: '#FFFFFF',
        borderBottom: '4px solid #EA580C',
        boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
      }}>
        {/* Tricolor line */}
        <div style={{
          height: 4,
          background: 'linear-gradient(90deg, #FF9933 0%, #FFFFFF 50%, #138808 100%)'
        }} />

        <div style={{
          maxWidth: 1200,
          margin: '0 auto',
          padding: '16px 24px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: 16
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{
              width: 44, height: 44,
              borderRadius: 10,
              backgroundColor: '#EA580C',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontWeight: 900, fontSize: 18, letterSpacing: 1
            }}>
              GeM
            </div>
            <div>
              <h1 style={{ fontSize: 18, fontWeight: 800, letterSpacing: -0.3 }}>
                Government e-Marketplace
              </h1>
              <p style={{ fontSize: 12, color: '#94A3B8' }}>
                Procurement Officer Compliance Portal • National Tender Publishing Desk
              </p>
            </div>
          </div>

          {/* Officer Info & Role */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 13, fontWeight: 700, color: '#F8FAFC' }}>
                {officerProfile?.name || 'Rajesh Sharma (Officer)'}
              </div>
              <div style={{ fontSize: 11, color: '#94A3B8' }}>
                Role: <span style={{ color: '#F97316', fontWeight: 600 }}>OFFICER / ADMIN</span>
              </div>
            </div>
            <div style={{
              width: 38, height: 38, borderRadius: '50%',
              backgroundColor: '#1E3A8A',
              border: '2px solid #3B82F6',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 14, fontWeight: 700
            }}>
              RS
            </div>
          </div>
        </div>
      </header>

      {/* Main Container */}
      <main style={{ maxWidth: 1200, width: '100%', margin: '0 auto', padding: '24px', flex: 1 }}>
        {/* Architecture Pipeline Banner */}
        <div style={{
          backgroundColor: '#FFFFFF',
          borderRadius: 12,
          padding: '18px 24px',
          border: '1px solid #E2E8F0',
          marginBottom: 24,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: 16,
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.04)'
        }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
              <Sparkles size={16} color="#EA580C" />
              <h2 style={{ fontSize: 15, fontWeight: 700, color: '#0F172A' }}>
                Connected End-to-End Pipeline
              </h2>
            </div>
            <p style={{ fontSize: 13, color: '#64748B' }}>
              Upload tender notices here → Stored in <strong>Google Drive</strong> (<code>GEM-COMPLIANCE/TENDERS/</code>) → Indexed in <strong>Firestore</strong> → Streamed live to <strong>Bidder Flutter App</strong>.
            </p>
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <button
              onClick={() => setIsModalOpen(true)}
              style={{
                backgroundColor: '#1E3A8A',
                color: '#FFFFFF',
                border: 'none',
                padding: '10px 20px',
                borderRadius: 8,
                fontWeight: 700,
                fontSize: 13,
                display: 'flex',
                alignItems: 'center',
                gap: 8,
                boxShadow: '0 4px 6px -1px rgba(30, 58, 138, 0.25)'
              }}
            >
              <FilePlus size={16} />
              <span>Publish New Tender PDF</span>
            </button>
            <button
              onClick={fetchTenders}
              title="Refresh tender list"
              style={{
                backgroundColor: '#F8FAFC',
                color: '#334155',
                border: '1px solid #CBD5E1',
                padding: '10px 14px',
                borderRadius: 8,
                display: 'flex',
                alignItems: 'center',
                gap: 6,
                fontSize: 13,
                fontWeight: 600
              }}
            >
              <RefreshCw size={15} />
              <span>Refresh</span>
            </button>
          </div>
        </div>

        {/* Integration Status Badges */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))',
          gap: 16,
          marginBottom: 24
        }}>
          <div style={{
            backgroundColor: '#FFFFFF',
            padding: 16,
            borderRadius: 10,
            border: '1px solid #E2E8F0',
            display: 'flex',
            alignItems: 'center',
            gap: 12
          }}>
            <div style={{
              width: 38, height: 38, borderRadius: 8,
              backgroundColor: '#EFF6FF', color: '#1E40AF',
              display: 'flex', alignItems: 'center', justifyContent: 'center'
            }}>
              <FolderTree size={20} />
            </div>
            <div>
              <div style={{ fontSize: 11, color: '#64748B', fontWeight: 600 }}>STORAGE INTEGRATION</div>
              <div style={{ fontSize: 13, fontWeight: 700, color: '#0F172A' }}>Google Drive v3</div>
            </div>
          </div>

          <div style={{
            backgroundColor: '#FFFFFF',
            padding: 16,
            borderRadius: 10,
            border: '1px solid #E2E8F0',
            display: 'flex',
            alignItems: 'center',
            gap: 12
          }}>
            <div style={{
              width: 38, height: 38, borderRadius: 8,
              backgroundColor: '#FFF7ED', color: '#EA580C',
              display: 'flex', alignItems: 'center', justifyContent: 'center'
            }}>
              <Database size={20} />
            </div>
            <div>
              <div style={{ fontSize: 11, color: '#64748B', fontWeight: 600 }}>METADATA STORE</div>
              <div style={{ fontSize: 13, fontWeight: 700, color: '#0F172A' }}>Cloud Firestore</div>
            </div>
          </div>

          <div style={{
            backgroundColor: '#FFFFFF',
            padding: 16,
            borderRadius: 10,
            border: '1px solid #E2E8F0',
            display: 'flex',
            alignItems: 'center',
            gap: 12
          }}>
            <div style={{
              width: 38, height: 38, borderRadius: 8,
              backgroundColor: '#F0FDF4', color: '#166534',
              display: 'flex', alignItems: 'center', justifyContent: 'center'
            }}>
              <Smartphone size={20} />
            </div>
            <div>
              <div style={{ fontSize: 11, color: '#64748B', fontWeight: 600 }}>CONSUMING CLIENT</div>
              <div style={{ fontSize: 13, fontWeight: 700, color: '#0F172A' }}>Flutter Bidder App</div>
            </div>
          </div>
        </div>

        {/* Section Title */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <h2 style={{ fontSize: 18, fontWeight: 700, color: '#0F172A' }}>
            Published Tender Notices ({tenders.length})
          </h2>
        </div>

        {/* Tender List */}
        <TenderList
          tenders={tenders}
          isLoading={isLoading}
          onRefresh={fetchTenders}
        />
      </main>

      {/* Tender Upload Modal */}
      <TenderUploadModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onTenderCreated={fetchTenders}
      />

      {/* Footer */}
      <footer style={{
        backgroundColor: '#0F172A',
        color: '#94A3B8',
        padding: '16px 24px',
        textAlign: 'center',
        fontSize: 12,
        borderTop: '1px solid #1E293B',
        marginTop: 40
      }}>
        <p>भारत सरकार • Government of India • Government e-Marketplace (GeM) Procurement Compliance Engine</p>
      </footer>
    </div>
  );
}
