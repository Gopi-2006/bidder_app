import os
from typing import Optional, Dict, Any, List
from app.integrations.google_drive.client import GoogleDriveClient, extract_drive_folder_id
from app.integrations.google_drive.exceptions import FolderNotFoundException, DriveAPIException

LOCAL_STORAGE_ROOT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..", "storage_drive")
)


def find_or_create_folder(folder_name: str, parent_folder_id: Optional[str] = None) -> str:
    """
    Finds existing folder by name (under parent if provided) or creates it in Google Drive / local storage.
    """
    client = GoogleDriveClient.get_instance()
    service = client.get_service()

    if service:
        try:
            query = f"name = '{folder_name}' and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
            if parent_folder_id and not parent_folder_id.startswith("LOCAL-"):
                query += f" and '{parent_folder_id}' in parents"

            results = service.files().list(
                q=query,
                fields="files(id, name)",
                supportsAllDrives=True,
                includeItemsFromAllDrives=True,
            ).execute()
            files = results.get('files', [])
            if files:
                return files[0]['id']

            file_metadata: Dict[str, Any] = {
                'name': folder_name,
                'mimeType': 'application/vnd.google-apps.folder',
            }
            if parent_folder_id and not parent_folder_id.startswith("LOCAL-"):
                file_metadata['parents'] = [parent_folder_id]

            folder = service.files().create(
                body=file_metadata,
                fields='id',
                supportsAllDrives=True,
            ).execute()
            return folder.get('id')
        except Exception as e:
            print(f"[GoogleDrive] Folder lookup/create '{folder_name}': {e}. Using local folder.")

    # Local fallback
    folder_id = f"LOCAL-FOLDER-{folder_name.replace(' ', '_').upper()}"
    return folder_id


def create_folder(folder_name: str, parent_folder_id: Optional[str] = None) -> str:
    return find_or_create_folder(folder_name, parent_folder_id)


def ensure_tender_folder_hierarchy(tender_id: str) -> Dict[str, str]:
    """
    Ensures:
    GEM-COMPLIANCE/
        TENDERS/
            <tender_id>/
                ORIGINAL/
                EXTRACTED/
                REPORTS/
    Returns a dict mapping folder keys to their Google Drive IDs.
    """
    client = GoogleDriveClient.get_instance()
    root_id = client.root_folder_id

    # Check env var for tenders root
    tenders_root_env = extract_drive_folder_id(os.getenv("GOOGLE_DRIVE_TENDERS_FOLDER_ID"))

    # Create root hierarchy if needed
    gem_root = root_id or find_or_create_folder("GEM-COMPLIANCE")
    tenders_root = tenders_root_env or find_or_create_folder("TENDERS", gem_root)
    tender_folder = find_or_create_folder(tender_id, tenders_root)

    original_folder = find_or_create_folder("ORIGINAL", tender_folder)
    extracted_folder = find_or_create_folder("EXTRACTED", tender_folder)
    reports_folder = find_or_create_folder("REPORTS", tender_folder)

    # Also mirror locally
    local_path = os.path.join(LOCAL_STORAGE_ROOT, "GEM-COMPLIANCE", "TENDERS", tender_id)
    for sub in ["ORIGINAL", "EXTRACTED", "REPORTS", "GENERATED"]:
        os.makedirs(os.path.join(local_path, sub), exist_ok=True)

    return {
        "root_folder_id": gem_root,
        "tenders_root_folder_id": tenders_root,
        "tender_folder_id": tender_folder,
        "original_folder_id": original_folder,
        "extracted_folder_id": extracted_folder,
        "reports_folder_id": reports_folder,
        "generated_folder_id": reports_folder,
    }


def ensure_application_folder_hierarchy(application_id: str) -> Dict[str, str]:
    """
    Ensures:
    GEM-COMPLIANCE/
        APPLICATIONS/
            <application_id>/
                GST/
                PAN/
                UDYAM/
                TURNOVER/
                OEM_AUTH/
                TECHNICAL/
                REPORTS/
    Returns a dict mapping doc type to folder ID.
    """
    client = GoogleDriveClient.get_instance()
    root_id = client.root_folder_id

    gem_root = root_id or create_folder("GEM-COMPLIANCE")
    apps_root = create_folder("APPLICATIONS", gem_root)
    app_folder = create_folder(application_id, apps_root)

    subfolders = ["GST", "PAN", "UDYAM", "TURNOVER", "OEM_AUTH", "TECHNICAL", "REPORTS"]
    folder_map: Dict[str, str] = {"app_folder_id": app_folder}

    # Local mirror
    local_path = os.path.join(LOCAL_STORAGE_ROOT, "GEM-COMPLIANCE", "APPLICATIONS", application_id)

    for sub in subfolders:
        f_id = create_folder(sub, app_folder)
        folder_map[f"{sub.lower()}_folder_id"] = f_id
        os.makedirs(os.path.join(local_path, sub), exist_ok=True)

    return folder_map
