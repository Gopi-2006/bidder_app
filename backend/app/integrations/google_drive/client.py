import os
import re
from typing import Optional
from dotenv import load_dotenv

load_dotenv()

try:
    from googleapiclient.discovery import build, Resource
    from google.oauth2 import service_account
    from google.auth import default as google_auth_default
    GOOGLE_DRIVE_AVAILABLE = True
except ImportError:
    GOOGLE_DRIVE_AVAILABLE = False
    Resource = object

from app.integrations.google_drive.exceptions import DriveAPIException
from app.integrations.firebase.admin import _resolve_credentials


def extract_drive_folder_id(raw_val: Optional[str]) -> Optional[str]:
    """Extracts clean alphanumeric Google Drive folder ID from string or URL."""
    if not raw_val:
        return None
    val = raw_val.strip()
    # Match /folders/<id> URL pattern
    match = re.search(r'/folders/([a-zA-Z0-9_-]+)', val)
    if match:
        return match.group(1)
    # Match id query parameter ?id=<id>
    id_match = re.search(r'[?&]id=([a-zA-Z0-9_-]+)', val)
    if id_match:
        return id_match.group(1)
    return val


class GoogleDriveClient:
    SCOPES = ['https://www.googleapis.com/auth/drive']
    _instance: Optional['GoogleDriveClient'] = None

    def __init__(self):
        self.service: Optional[Resource] = None
        self.credentials_path = _resolve_credentials()
        self.root_folder_id = extract_drive_folder_id(os.getenv("GOOGLE_DRIVE_ROOT_FOLDER_ID"))
        self._init_service()

    @classmethod
    def get_instance(cls) -> 'GoogleDriveClient':
        if cls._instance is None:
            cls._instance = GoogleDriveClient()
        return cls._instance

    def _init_service(self):
        if not GOOGLE_DRIVE_AVAILABLE:
            print("[GoogleDrive] google-api-python-client not installed. Operating in Local Emulator mode.")
            return

        if self.credentials_path and os.path.exists(self.credentials_path):
            try:
                creds = service_account.Credentials.from_service_account_file(
                    self.credentials_path, scopes=self.SCOPES
                )
                self.service = build('drive', 'v3', credentials=creds)
                print(f"[GoogleDrive] Initialized Drive API v3 (root folder: {self.root_folder_id}) with service account file.")
            except Exception as e:
                print(f"[GoogleDrive] Error initializing service account: {e}. Trying ADC.")
                self._init_with_adc()
        else:
            # No explicit service account — try Application Default Credentials (Cloud Run)
            self._init_with_adc()

    def _init_with_adc(self):
        """Initializes Google Drive using Application Default Credentials (ADC)."""
        if not GOOGLE_DRIVE_AVAILABLE:
            return
        try:
            creds, project = google_auth_default(scopes=self.SCOPES)
            self.service = build('drive', 'v3', credentials=creds)
            print(f"[GoogleDrive] Initialized Drive API v3 with Application Default Credentials (project: {project}).")
        except Exception as e:
            print(f"[GoogleDrive] ADC initialization failed: {e}. Operating in Local Storage Emulator mode.")
            self.service = None

    def get_service(self) -> Optional[Resource]:
        return self.service

    def is_connected(self) -> bool:
        return self.service is not None


def get_drive_service() -> Optional[Resource]:
    return GoogleDriveClient.get_instance().get_service()
