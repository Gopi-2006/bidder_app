# AI-Powered GeM Tender Compliance Verification Platform
> **Government of India e-Marketplace (GeM) Procurement Compliance System**
> *Bidder Flutter Mobile Application + FastAPI Deterministic Rule Engine*

---

## 🇮🇳 System Overview

The **GeM Tender Compliance Verification Platform** is an explainable, deterministic procurement compliance verification system designed for the Government of India.

It enforces a strict **Deterministic Trust Boundary**:
- **AI Extraction Pipeline (PyMuPDF + OCR + NLP)**: Extracts and structures complex tender clauses, financial thresholds, and uploaded bidder PDF certificates into standardized machine schemas.
- **Deterministic Rule Engine**: Authoritative, mathematically reproducible verification of numerical turnover thresholds, certificate validity dates, cross-document entity matching, and required statutory certificates with standardized audit reason codes.
- **Human-in-the-Loop REVIEW Queue**: When scan confidence is low, dates are ambiguous, or values conflict, the system routes the requirement to an officer for audited exception resolution.
- **Immutable Audit Trail**: Preserves the complete evidence chain (Clause Reference → Extracted Data → Source Page → Machine Evaluation → Officer Resolution).

---

## 📁 Repository Structure

```
sih-tender-simulator/
├── backend/                      # Python FastAPI Backend Orchestrator
│   ├── app/
│   │   ├── api/                  # REST API endpoints & contracts (/me, /tenders, /applications, /notifications)
│   │   ├── models/schemas.py     # Pydantic schemas & Rule contracts
│   │   ├── services/
│   │   │   ├── rule_engine.py    # Deterministic Rule Engine (PASS/FAIL/REVIEW)
│   │   │   └── extraction.py     # PyMuPDF & OCR field extractors
│   │   ├── integrations/
│   │   │   ├── storage.py        # Google Drive API & folder hierarchy
│   │   │   ├── firebase.py       # Firebase Admin Auth & Firestore
│   │   │   └── verification.py   # GSTIN, PAN, Udyam registry adapters
│   │   └── main.py
│   └── tests/                    # Deterministic Rule Engine & Drive integration test suite
└── bidder_app/                   # Bidder Flutter Mobile Application (Dart)
    ├── lib/
    │   ├── core/                 # Theme, GeM styling, API service, Firebase Auth
    │   ├── models/               # Typed data models (Tender, Requirements, Evidence, Results, Notifications)
    │   └── screens/              # Splash, Login, Main Shell, Tenders, Application Detail, Evidence Upload, Vault, Alerts, Profile
    └── pubspec.yaml
```

---

## 🔑 1. Firebase Configuration & SHA Key

### Your Keystore SHA Fingerprints (Extracted)
To register the Android app in your Firebase project:
1. Open the [Firebase Console](https://console.firebase.google.com/) → **Project Settings** → **Your apps** → Select/Add Android app (`in.gov.gem.compliance.bidder_app`).
2. Add your SHA fingerprints under **SHA certificate fingerprints**:
   - **SHA-1**: `F5:70:99:E7:F8:0E:42:51:92:CF:90:ED:34:49:94:4F:A9:D3:70:DC`
   - **SHA-256**: `01:DE:AE:25:1A:18:EE:F3:88:C8:66:9E:3F:3C:25:1B:3A:4B:C7:F0:5B:47:22:06:DB:D8:39:C4:ED:5A:A7:8E`
3. Download `google-services.json` and place it in:
   ```
   bidder_app/android/app/google-services.json
   ```
4. For backend Firebase Admin SDK, download your Service Account JSON from Firebase Console → **Project Settings** → **Service accounts** and save it as:
   ```
   backend/firebase_service_account.json
   ```

---

## ☁️ 2. Google Drive Storage Setup

The backend stores all tender PDFs and bidder evidence files in Google Drive:

1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Select your project and enable the **Google Drive API**.
3. Go to **IAM & Admin** → **Service Accounts** → Click **Create Service Account**.
4. Create a JSON Key for this Service Account and save it as:
   ```
   backend/service_account.json
   ```
5. In your Google Drive, create a root folder named `GeM-Compliance` and share it with the Service Account email address with **Editor** access.
6. The backend automatically creates and manages the structured hierarchy:
   ```
   GeM-Compliance/
   ├── Tenders/
   │   └── <tender_id>/
   │       └── original/<file_name>.pdf
   └── Applications/
       └── <application_id>/
           └── bidder-evidence/<doc_type>/<file_name>.pdf
   ```

*(Note: If `service_account.json` is not present, the backend uses its built-in local drive storage hierarchy at `backend/storage_drive/`.)*

---

## 🚀 3. How to Run the Platform

### A. Run FastAPI Backend
```bash
start_backend.bat
# Or manually:
cd backend
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```
API Documentation: **`http://127.0.0.1:8000/docs`**

### B. Run Officer React Web Dashboard
```bash
start_frontend.bat
# Or manually:
cd officer_web
npm run dev
```
Dashboard: **`http://localhost:5173`**

### C. Run Bidder Flutter Mobile App
```bash
start_bidder_app.bat
# Or manually:
cd bidder_app
flutter run
```

### D. Run Automated Rule Engine Tests
```bash
run_tests.bat
# Or manually:
cd backend
python -m pytest tests/ -v
```
