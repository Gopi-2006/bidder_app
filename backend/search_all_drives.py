import sys
from app.integrations.google_drive import get_drive_service

sys.stdout.reconfigure(encoding='utf-8')
service = get_drive_service()

# Include shared drives and all corpora
results = service.files().list(
    pageSize=1000,
    supportsAllDrives=True,
    includeItemsFromAllDrives=True,
    corpora="allDrives",
    fields="files(id, name, mimeType, parents, size, trashed)",
    q="trashed = false"
).execute()

items = results.get("files", [])
print(f"Total items found across all drives: {len(items)}")
for item in items:
    if not item.get("name", "").endswith(".pdf") and item.get("mimeType") != "application/vnd.google-apps.folder":
        print(f"[{item.get('mimeType')}] {item.get('name')} | ID: {item.get('id')} | Size: {item.get('size')} | Parents: {item.get('parents')}")
