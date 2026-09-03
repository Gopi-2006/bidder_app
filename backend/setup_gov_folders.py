import io
import sys
import openpyxl
from googleapiclient.http import MediaIoBaseUpload
from app.integrations.google_drive import get_drive_service

sys.stdout.reconfigure(encoding='utf-8')
service = get_drive_service()
root_parent = "1SwD7pNwes2O4YiRAfbeQxms_R0JClRcH"

# Check if GOVERNMENT-DETAILS folder exists under root
res = service.files().list(
    q=f"'{root_parent}' in parents and name = 'GOVERNMENT-DETAILS' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
    fields="files(id, name)"
).execute()
gov_folders = res.get("files", [])
if gov_folders:
    gov_root_id = gov_folders[0]["id"]
    print(f"Found existing GOVERNMENT-DETAILS folder: {gov_root_id}")
else:
    # Try to create it
    try:
        fmeta = {
            "name": "GOVERNMENT-DETAILS",
            "mimeType": "application/vnd.google-apps.folder",
            "parents": [root_parent]
        }
        gov_f = service.files().create(body=fmeta, fields="id, name").execute()
        gov_root_id = gov_f["id"]
        print(f"Created GOVERNMENT-DETAILS folder: {gov_root_id}")
    except Exception as e:
        print(f"Could not create GOVERNMENT-DETAILS: {e}")
        # fallback to existing 'GOVERNMENT DETAILS' (1HUiXTsz1pHPkZl27IZOzeMJEjKrLsss4)
        gov_root_id = "1HUiXTsz1pHPkZl27IZOzeMJEjKrLsss4"
        print(f"Using fallback GOVERNMENT DETAILS folder: {gov_root_id}")

print(f"GOVERNMENT_ROOT_ID = {gov_root_id}")
