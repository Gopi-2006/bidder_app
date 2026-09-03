import io
import os
import hashlib
from typing import Optional, Dict, Any, List
from datetime import datetime

from app.integrations.google_drive.client import GoogleDriveClient
from app.integrations.google_drive.exceptions import (
    FileUploadException,
    FileDownloadException,
    DriveAPIException,
)

try:
    from googleapiclient.http import MediaIoBaseUpload, MediaIoBaseDownload
    GOOGLE_MEDIA_AVAILABLE = True
except ImportError:
    GOOGLE_MEDIA_AVAILABLE = False

LOCAL_STORAGE_ROOT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..", "storage_drive")
)


def upload_file(
    file_name: str,
    file_bytes: bytes,
    parent_folder_id: Optional[str] = None,
    mime_type: str = "application/pdf",
    relative_local_path: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Uploads a binary document to Google Drive (or local storage).
    Returns file metadata including drive_file_id and SHA-256 hash.
    """
    client = GoogleDriveClient.get_instance()
    service = client.get_service()
    sha256_hash = hashlib.sha256(file_bytes).hexdigest()
    timestamp = datetime.utcnow().isoformat() + "Z"

    # Always persist locally for offline resilience & fast PyMuPDF extraction
    if relative_local_path:
        dest_dir = os.path.join(LOCAL_STORAGE_ROOT, relative_local_path)
    else:
        dest_dir = os.path.join(LOCAL_STORAGE_ROOT, "uploads")
    os.makedirs(dest_dir, exist_ok=True)
    local_filepath = os.path.join(dest_dir, file_name)
    with open(local_filepath, "wb") as f:
        f.write(file_bytes)

    drive_file_id = f"LOCAL-{hashlib.md5(file_bytes).hexdigest()[:12]}"

    if service and GOOGLE_MEDIA_AVAILABLE:
        try:
            file_metadata: Dict[str, Any] = {'name': file_name}
            if parent_folder_id and not parent_folder_id.startswith("LOCAL-"):
                file_metadata['parents'] = [parent_folder_id]

            media = MediaIoBaseUpload(io.BytesIO(file_bytes), mimetype=mime_type, resumable=True)
            created_file = service.files().create(
                body=file_metadata,
                media_body=media,
                fields='id, name, mimeType, size, createdTime, md5Checksum'
            ).execute()

            drive_file_id = created_file.get('id', drive_file_id)
        except Exception as e:
            print(f"[GoogleDrive] Cloud upload failed: {e}. Preserved in local storage.")

    return {
        "drive_file_id": drive_file_id,
        "file_name": file_name,
        "sha256": sha256_hash,
        "size_bytes": len(file_bytes),
        "local_path": local_filepath,
        "uploaded_at": timestamp,
        "parent_folder_id": parent_folder_id,
    }


def download_file(file_id: str) -> bytes:
    """
    Downloads binary content of a file from Google Drive (or local storage).
    """
    client = GoogleDriveClient.get_instance()
    service = client.get_service()

    if service and not file_id.startswith("LOCAL-") and GOOGLE_MEDIA_AVAILABLE:
        try:
            request = service.files().get_media(fileId=file_id)
            fh = io.BytesIO()
            downloader = MediaIoBaseDownload(fh, request)
            done = False
            while not done:
                _, done = downloader.next_chunk()
            return fh.getvalue()
        except Exception as e:
            print(f"[GoogleDrive] Error downloading {file_id} from Drive: {e}")

    # Fallback search local storage
    for root, _, files in os.walk(LOCAL_STORAGE_ROOT):
        for f in files:
            p = os.path.join(root, f)
            with open(p, "rb") as rf:
                data = rf.read()
                if file_id in p or hashlib.md5(data).hexdigest()[:12] in file_id:
                    return data
    
    return b""


def get_file_metadata(file_id: str) -> Dict[str, Any]:
    client = GoogleDriveClient.get_instance()
    service = client.get_service()

    if service and not file_id.startswith("LOCAL-"):
        try:
            return service.files().get(fileId=file_id, fields='id, name, mimeType, size, createdTime, parents').execute()
        except Exception as e:
            print(f"[GoogleDrive] Error getting file metadata: {e}")

    return {"id": file_id, "name": "document.pdf", "is_local": True}


def list_files(parent_folder_id: Optional[str] = None) -> List[Dict[str, Any]]:
    client = GoogleDriveClient.get_instance()
    service = client.get_service()

    if service and parent_folder_id and not parent_folder_id.startswith("LOCAL-"):
        try:
            query = f"'{parent_folder_id}' in parents and trashed = false"
            results = service.files().list(
                q=query,
                fields="files(id, name, mimeType, size, createdTime)",
                supportsAllDrives=True,
                includeItemsFromAllDrives=True,
            ).execute()
            return results.get('files', [])
        except Exception as e:
            print(f"[GoogleDrive] Error listing files: {e}")

    return []


def list_drive_folder_pdf_files(folder_id: str) -> List[Dict[str, Any]]:
    """
    Lists all PDF files in the specified Google Drive folder (with pagination support).
    Ignores folders, non-PDF files, and temporary/hidden files.
    Returns list of dicts with: id, name, mimeType, size, createdTime, modifiedTime.
    """
    client = GoogleDriveClient.get_instance()
    service = client.get_service()

    if not service or folder_id.startswith("LOCAL-"):
        local_files = []
        for root, _, files in os.walk(LOCAL_STORAGE_ROOT):
            for f in files:
                if f.lower().endswith('.pdf') and not f.startswith(('~', '.', '~$')):
                    fp = os.path.join(root, f)
                    local_files.append({
                        "id": f"LOCAL-{hashlib.md5(f.encode()).hexdigest()[:12]}",
                        "name": f,
                        "mimeType": "application/pdf",
                        "size": os.path.getsize(fp) if os.path.exists(fp) else 0,
                        "createdTime": datetime.utcnow().isoformat() + "Z",
                        "modifiedTime": datetime.utcnow().isoformat() + "Z",
                    })
        return local_files

    pdf_files: List[Dict[str, Any]] = []
    page_token: Optional[str] = None
    query = f"'{folder_id}' in parents and trashed = false"

    while True:
        try:
            results = service.files().list(
                q=query,
                fields="nextPageToken, files(id, name, mimeType, size, createdTime, modifiedTime)",
                pageSize=100,
                pageToken=page_token,
                supportsAllDrives=True,
                includeItemsFromAllDrives=True,
            ).execute()

            items = results.get('files', [])
            for item in items:
                mime = item.get('mimeType', '')
                name = item.get('name', '')

                # Ignore folders
                if mime == 'application/vnd.google-apps.folder':
                    continue
                # Ignore temporary/hidden files
                if name.startswith(('~', '.', '~$')):
                    continue
                # Only process PDF files
                if mime == 'application/pdf' or name.lower().endswith('.pdf'):
                    pdf_files.append(item)

            page_token = results.get('nextPageToken')
            if not page_token:
                break
        except Exception as e:
            print(f"[GoogleDrive] Error listing folder files ({folder_id}): {e}")
            break

    return pdf_files


def delete_file(file_id: str) -> bool:
    client = GoogleDriveClient.get_instance()
    service = client.get_service()

    if service and not file_id.startswith("LOCAL-"):
        try:
            service.files().delete(fileId=file_id).execute()
            return True
        except Exception as e:
            print(f"[GoogleDrive] Error deleting file {file_id}: {e}")
            return False
    return True


def move_file(file_id: str, new_parent_folder_id: str) -> bool:
    client = GoogleDriveClient.get_instance()
    service = client.get_service()

    if service and not file_id.startswith("LOCAL-") and not new_parent_folder_id.startswith("LOCAL-"):
        try:
            file = service.files().get(fileId=file_id, fields='parents').execute()
            previous_parents = ",".join(file.get('parents', []))
            service.files().update(
                fileId=file_id,
                addParents=new_parent_folder_id,
                removeParents=previous_parents,
                fields='id, parents'
            ).execute()
            return True
        except Exception as e:
            print(f"[GoogleDrive] Error moving file {file_id}: {e}")
            return False
    return True
