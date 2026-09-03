import sys
from app.integrations.google_drive import get_drive_service

sys.stdout.reconfigure(encoding='utf-8')
service = get_drive_service()
gov_root_id = "1kxpp9g0xQ5165C0MHsBTomBAUu5n3Z3F"

res = service.files().list(
    q=f"'{gov_root_id}' in parents and trashed = false",
    fields="files(id, name, mimeType, parents)"
).execute()

print(f"Children of GOVERNMENT-DETAILS ({gov_root_id}):")
for f in res.get("files", []):
    print(f"[{f.get('mimeType')}] {f.get('name')} | ID: {f.get('id')}")
    if f.get('mimeType') == 'application/vnd.google-apps.folder':
        sub_res = service.files().list(
            q=f"'{f.get('id')}' in parents and trashed = false",
            fields="files(id, name, mimeType)"
        ).execute()
        for sub_f in sub_res.get("files", []):
            print(f"   └── [{sub_f.get('mimeType')}] {sub_f.get('name')} | ID: {sub_f.get('id')}")
