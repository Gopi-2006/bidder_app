import sys
from app.integrations.google_drive import get_drive_service

sys.stdout.reconfigure(encoding='utf-8')
service = get_drive_service()

res = service.files().list(
    q="name contains 'GST' or name contains 'gst'",
    fields="files(id, name, mimeType, parents)"
).execute()

for f in res.get("files", []):
    print(f"[{f.get('mimeType')}] {f.get('name')} | ID: {f.get('id')} | Parents: {f.get('parents')}")
