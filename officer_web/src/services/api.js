import axios from 'axios';

const API_BASE_URL = 'http://127.0.0.1:8000/api/v1';

// Default officer token for demo/evaluation
let currentToken = localStorage.getItem('gem_officer_token') || 'officer_demo_token';

export const setAuthToken = (token) => {
  currentToken = token;
  localStorage.setItem('gem_officer_token', token);
};

export const getAuthToken = () => currentToken;

const apiClient = axios.create({
  baseURL: API_BASE_URL,
});

apiClient.interceptors.request.use((config) => {
  if (currentToken) {
    config.headers.Authorization = `Bearer ${currentToken}`;
  }
  return config;
});

export const apiService = {
  // Fetch Current Profile
  getProfile: async () => {
    const res = await apiClient.get('/me');
    return res.data;
  },

  // Fetch all Tenders
  getTenders: async () => {
    const res = await apiClient.get('/tenders');
    return res.data;
  },

  // Create new Tender
  createTender: async (tenderData) => {
    const res = await apiClient.post('/tenders', tenderData);
    return res.data;
  },

  // Create new Tender with attached PDF document (Single-request multipart/form-data)
  createTenderWithDocument: async (formDataObj, file, onUploadProgress) => {
    const formData = new FormData();
    Object.keys(formDataObj).forEach((key) => {
      if (formDataObj[key] !== undefined && formDataObj[key] !== null) {
        formData.append(key, formDataObj[key]);
      }
    });
    if (file) {
      formData.append('file', file);
    }
    const res = await apiClient.post('/tenders', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
      onUploadProgress,
    });
    return res.data;
  },

  // Upload Tender PDF Document to Google Drive
  uploadTenderDocument: async (tenderId, file, onUploadProgress) => {
    const formData = new FormData();
    formData.append('file', file);

    const res = await apiClient.post(`/tenders/${tenderId}/document`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
      onUploadProgress,
    });
    return res.data;
  },

  // Get stream URL for Tender Document
  getTenderDocumentUrl: (tenderId) => {
    return `${API_BASE_URL}/tenders/${tenderId}/document`;
  },
};
