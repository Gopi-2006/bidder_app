import os
import io
import json
import hashlib
from typing import Optional, Dict, Any, Tuple
from datetime import datetime

# Try loading google drive api dependencies if available
try:
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaIoBaseUpload, MediaIoBaseDownload
    from google.oauth2 import service_account
    GOOGLE_DRIVE_AVAILABLE = True
except ImportError:
    GOOGLE_DRIVE_AVAILABLE = False


class GoogleDriveStorageAdapter:
    """
    Manages binary tender PDFs and bidder evidence files in Google Drive.
    Supports real Service Account authentication with local filesystem fallback.
    """
    SERVICE_ACCOUNT_FILE = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "service_account.json")
    SCOPES = ['https://www.googleapis.com/auth/drive']
    LOCAL_STORAGE_ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "storage_drive")

    def __init__(self):
        self.service = None
        self._init_drive_service()
        # Ensure local drive folder hierarchy exists
        os.makedirs(self.LOCAL_STORAGE_ROOT, exist_ok=True)

    def _init_drive_service(self):
        if GOOGLE_DRIVE_AVAILABLE and os.path.exists(self.SERVICE_ACCOUNT_FILE):
            try:
                creds = service_account.Credentials.from_service_account_file(
                    self.SERVICE_ACCOUNT_FILE, scopes=self.SCOPES
                )
                self.service = build('drive', 'v3', credentials=creds)
                print(f"[GoogleDrive] Successfully connected to Google Drive API using {self.SERVICE_ACCOUNT_FILE}")
            except Exception as e:
                print(f"[GoogleDrive] Warning: Could not authenticate with Google Drive API: {e}. Using local storage hierarchy.")
                self.service = None
        else:
            print(f"[GoogleDrive] Service account '{self.SERVICE_ACCOUNT_FILE}' not found. Using local drive storage emulator at {self.LOCAL_STORAGE_ROOT}.")

    def upload_tender_pdf(self, tender_id: str, file_name: str, file_bytes: bytes) -> Dict[str, Any]:
        """
        Stores tender PDF in GeM-Compliance/Tenders/<tender_id>/original/<file_name>
        """
        sha256_hash = hashlib.sha256(file_bytes).hexdigest()
        path = os.path.join(self.LOCAL_STORAGE_ROOT, "GeM-Compliance", "Tenders", tender_id, "original")
        os.makedirs(path, exist_ok=True)
        local_file_path = os.path.join(path, file_name)
        
        with open(local_file_path, "wb") as f:
            f.write(file_bytes)

        drive_file_id = f"DRIVE-TENDER-{tender_id}-{int(datetime.utcnow().timestamp())}"

        # If Google Drive API service is active, upload to cloud
        if self.service:
            try:
                file_metadata = {'name': file_name}
                media = MediaIoBaseUpload(io.BytesIO(file_bytes), mimetype='application/pdf')
                file = self.service.files().create(body=file_metadata, media_body=media, fields='id').execute()
                drive_file_id = file.get('id')
            except Exception as e:
                print(f"[GoogleDrive] Cloud upload error: {e}")

        return {
            "drive_file_id": drive_file_id,
            "folder_path": f"GeM-Compliance/Tenders/{tender_id}/original/",
            "file_name": file_name,
            "sha256": sha256_hash,
            "size_bytes": len(file_bytes),
            "uploaded_at": datetime.utcnow().isoformat() + "Z",
        }

    def upload_bidder_evidence(
        self, application_id: str, document_type: str, file_name: str, file_bytes: bytes
    ) -> Dict[str, Any]:
        """
        Stores bidder evidence in GeM-Compliance/Applications/<application_id>/bidder-evidence/<doc_type>/<file_name>
        """
        sha256_hash = hashlib.sha256(file_bytes).hexdigest()
        path = os.path.join(
            self.LOCAL_STORAGE_ROOT, "GeM-Compliance", "Applications", application_id, "bidder-evidence", document_type
        )
        os.makedirs(path, exist_ok=True)
        local_file_path = os.path.join(path, file_name)

        with open(local_file_path, "wb") as f:
            f.write(file_bytes)

        drive_file_id = f"DRIVE-APP-{application_id}-{document_type}-{int(datetime.utcnow().timestamp())}"

        if self.service:
            try:
                file_metadata = {'name': file_name}
                media = MediaIoBaseUpload(io.BytesIO(file_bytes), mimetype='application/pdf')
                file = self.service.files().create(body=file_metadata, media_body=media, fields='id').execute()
                drive_file_id = file.get('id')
            except Exception as e:
                print(f"[GoogleDrive] Cloud upload error: {e}")

        return {
            "drive_file_id": drive_file_id,
            "folder_path": f"GeM-Compliance/Applications/{application_id}/bidder-evidence/{document_type}/",
            "file_name": file_name,
            "sha256": sha256_hash,
            "size_bytes": len(file_bytes),
            "uploaded_at": datetime.utcnow().isoformat() + "Z",
        }


drive_storage = GoogleDriveStorageAdapter()
