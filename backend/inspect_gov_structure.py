import sys
from app.integrations.google_drive import get_drive_service

sys.stdout.reconfigure(encoding='utf-8')
service = get_drive_service()

results = service.files().list(
    pageSize=100,
    fields="files(id, name, mimeType, parents)",
    q="trashed = false"
).execute()

for item in results.get("files", []):
    print(f"[{item.get('mimeType')}] {item.get('name')} | ID: {item.get('id')} | Parents: {item.get('parents')}")
