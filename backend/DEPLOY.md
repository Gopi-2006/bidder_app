# 🚀 Google Cloud Run Deployment Guide

This guide deploys the FastAPI backend to Google Cloud Run so the Flutter app
works from any device, anywhere, without the laptop being on.

---

## Prerequisites

1. [Google Cloud SDK (gcloud)](https://cloud.google.com/sdk/docs/install) — install and login
2. Docker Desktop (for local image build + push)
3. Your GCP project must have billing enabled

```powershell
# Verify gcloud is installed and logged in
gcloud --version
gcloud auth login
gcloud config set project bidder-fdede   # replace if your project ID differs
```

---

## Step 1 — Enable Required APIs

```powershell
gcloud services enable `
  run.googleapis.com `
  artifactregistry.googleapis.com `
  secretmanager.googleapis.com `
  iam.googleapis.com
```

---

## Step 2 — Create Artifact Registry Repository

```powershell
gcloud artifacts repositories create gem-backend `
  --repository-format=docker `
  --location=asia-south1 `
  --description="GeM Bidder Backend"
```

---

## Step 3 — Build and Push Docker Image

Run from the backend/ directory:

```powershell
# Set variables
$PROJECT_ID = "bidder-fdede"
$REGION     = "asia-south1"
$IMAGE      = "$REGION-docker.pkg.dev/$PROJECT_ID/gem-backend/api:latest"

# Configure Docker to use gcloud credentials
gcloud auth configure-docker "$REGION-docker.pkg.dev"

# Build
docker build -t $IMAGE .

# Push
docker push $IMAGE
```

---

## Step 4 — Prepare Service Account Credentials for Cloud Run

### Option A: Grant IAM roles to Cloud Run service account (Recommended)

```powershell
$SA = "gem-backend-sa@$PROJECT_ID.iam.gserviceaccount.com"

# Create dedicated service account for Cloud Run
gcloud iam service-accounts create gem-backend-sa `
  --display-name="GeM Backend Service Account"

# Firebase Admin SDK
gcloud projects add-iam-policy-binding $PROJECT_ID `
  --member="serviceAccount:$SA" `
  --role="roles/firebase.admin"

# Firestore
gcloud projects add-iam-policy-binding $PROJECT_ID `
  --member="serviceAccount:$SA" `
  --role="roles/datastore.user"

# Secret Manager (if using Option B)
gcloud projects add-iam-policy-binding $PROJECT_ID `
  --member="serviceAccount:$SA" `
  --role="roles/secretmanager.secretAccessor"
```

### Option B: Inject service account JSON as a Secret Manager secret

```powershell
# Base64-encode your service account JSON
$b64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes("credentials\bidder-fdede-b13f4f369c8a.json"))

# Create the secret
echo $b64 | gcloud secrets create gem-sa-credentials --data-file=-

# Grant Cloud Run access to the secret
gcloud secrets add-iam-policy-binding gem-sa-credentials `
  --member="serviceAccount:$SA" `
  --role="roles/secretmanager.secretAccessor"
```

---

## Step 5 — Deploy to Cloud Run

Replace ALL_CAPS values with your real IDs from .env:

```powershell
gcloud run deploy gem-backend `
  --image=$IMAGE `
  --platform=managed `
  --region=$REGION `
  --service-account=$SA `
  --allow-unauthenticated `
  --port=8000 `
  --memory=512Mi `
  --cpu=1 `
  --min-instances=0 `
  --max-instances=3 `
  --set-env-vars="FIREBASE_PROJECT_ID=bidder-fdede" `
  --set-env-vars="FIRESTORE_DATABASE_ID=(default)" `
  --set-env-vars="GOOGLE_DRIVE_ROOT_FOLDER_ID=YOUR_DRIVE_FOLDER_ID" `
  --set-env-vars="GEM_PAN_SHEET_ID=YOUR_PAN_SHEET_ID" `
  --set-env-vars="GEM_UDYAM_SHEET_ID=YOUR_UDYAM_SHEET_ID" `
  --set-env-vars="GEM_GST_SHEET_ID=YOUR_GST_SHEET_ID" `
  --set-env-vars="GEM_OEM_SHEET_ID=YOUR_OEM_SHEET_ID"
```

If using Option B (base64 JSON secret), add:
```
  --set-secrets="GOOGLE_APPLICATION_CREDENTIALS_JSON=gem-sa-credentials:latest"
```

---

## Step 6 — Get Your Cloud Run URL

```powershell
gcloud run services describe gem-backend `
  --platform=managed `
  --region=$REGION `
  --format="value(status.url)"
```

It looks like: https://gem-backend-xxxxxxxxxxxx-el.a.run.app
Copy this URL for the next step.

---

## Step 7 — Verify the Deployment

```powershell
$CR_URL = "https://gem-backend-xxxxxxxxxxxx-el.a.run.app"  # paste your URL

Invoke-RestMethod "$CR_URL/health"
# Expected: {"status":"ok","firebase":"connected",...}

Invoke-RestMethod "$CR_URL/api/v1/tenders"
# Expected: JSON array of tenders
```

---

## Step 8 — Update Flutter and Build Release APK

Edit bidder_app/lib/core/api_service.dart and replace:
  static const String _defaultProductionHost = 'https://REPLACE_WITH_CLOUD_RUN_URL';
with your real URL.

OR build with --dart-define (no source changes needed):

```powershell
cd bidder_app

flutter build apk --release `
  "--dart-define=API_HOST_URL=https://gem-backend-xxxxxxxxxxxx-el.a.run.app" `
  "--dart-define=API_BASE_URL=https://gem-backend-xxxxxxxxxxxx-el.a.run.app/api/v1"
```

APK location: bidder_app\build\app\outputs\flutter-apk\app-release.apk

---

## Verification Checklist

- [ ] GET /health returns {"status":"ok"}
- [ ] GET /api/v1/tenders returns tender list
- [ ] POST /api/v1/government/verify/pan works
- [ ] Install APK on physical phone
- [ ] Turn laptop OFF, verify app still works

---

## Cost Estimate

Cloud Run free tier: 2M requests/month, 180K vCPU-seconds, 360K GB-seconds.
Expected demo usage: well within free tier = Rs 0/month.
Cloud Run scales to zero when idle — no idle charges.
