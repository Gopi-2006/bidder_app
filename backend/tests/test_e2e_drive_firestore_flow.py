import io
import os
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.integrations.firebase.firestore import FirestoreRepository
from app.integrations.google_drive.files import download_file

client = TestClient(app)

def test_full_automated_tender_flow():
    # 1. Create a dummy valid PDF
    pdf_content = b"%PDF-1.4\n1 0 obj\n<< /Title (Test GeM Tender Notice) >>\nendobj\ntrailer\n<< /Root 1 0 R >>\n%%EOF"
    
    tender_payload = {
        "tender_id": "TENDER-AUTO-TEST-2026",
        "bid_number": "GEM/2026/B/998877",
        "title": "Automated Server & Network Deployment 2026",
        "organization": "National Informatics Centre Services Inc.",
        "ministry": "Ministry of Electronics and Information Technology",
        "category": "GOODS",
        "estimated_value": "7500000",
        "issue_date": "2026-09-01",
        "submission_deadline": "2026-10-15",
        "status": "PUBLISHED",
    }
    
    files = {
        "file": ("Sample_GeM_Bidder_Submission.pdf", pdf_content, "application/pdf")
    }
    
    headers = {
        "Authorization": "Bearer officer_demo_token"
    }
    
    print("\n--- Step 1 & 2: Officer uploads PDF via multipart/form-data to /tenders ---")
    response = client.post("/api/v1/tenders", data=tender_payload, files=files, headers=headers)
    print("Response status:", response.status_code)
    print("Response body:", response.json())
    
    assert response.status_code == 200
    created_tender = response.json()
    assert created_tender["tender_id"] == "TENDER-AUTO-TEST-2026"
    assert created_tender["original_file_id"] is not None
    assert created_tender["drive_folder_id"] is not None
    assert created_tender["file_name"] == "Sample_GeM_Bidder_Submission.pdf"
    assert created_tender["status"] == "PUBLISHED"
    
    orig_file_id = created_tender["original_file_id"]
    folder_id = created_tender["drive_folder_id"]
    
    print(f"\n--- Step 4 & 5: Google Drive file ID: {orig_file_id}, Folder ID: {folder_id} ---")
    assert not orig_file_id.startswith("google-drive-file-id")
    assert not folder_id.startswith("google-drive-folder-id")
    
    print("\n--- Step 6: Verify Firestore record ---")
    firestore_data = FirestoreRepository.get_tender("TENDER-AUTO-TEST-2026")
    if firestore_data:
        print("Firestore data:", firestore_data)
        assert firestore_data.get("original_file_id") == orig_file_id or firestore_data.get("originalFileId") == orig_file_id
        assert firestore_data.get("drive_folder_id") == folder_id or firestore_data.get("driveFolderId") == folder_id
        assert firestore_data.get("file_name") == "Sample_GeM_Bidder_Submission.pdf" or firestore_data.get("fileName") == "Sample_GeM_Bidder_Submission.pdf"
    
    print("\n--- Step 7: GET /api/v1/tenders list ---")
    list_res = client.get("/api/v1/tenders")
    assert list_res.status_code == 200
    all_tenders = list_res.json()
    assert any(t["tender_id"] == "TENDER-AUTO-TEST-2026" for t in all_tenders)
    
    print("\n--- Step 8: GET /api/v1/tenders/TENDER-AUTO-TEST-2026 ---")
    get_res = client.get("/api/v1/tenders/TENDER-AUTO-TEST-2026")
    assert get_res.status_code == 200
    assert get_res.json()["tender_id"] == "TENDER-AUTO-TEST-2026"
    
    print("\n--- Step 9 & 10: GET /api/v1/tenders/TENDER-AUTO-TEST-2026/document (Stream PDF) ---")
    doc_res = client.get(
        "/api/v1/tenders/TENDER-AUTO-TEST-2026/document",
        headers={"Authorization": "Bearer bidder_demo_token"}
    )
    assert doc_res.status_code == 200
    assert doc_res.headers["content-type"] == "application/pdf"
    assert doc_res.content == pdf_content
    print("Streamed PDF byte size:", len(doc_res.content))
    print("Streamed PDF matches uploaded PDF perfectly!")

if __name__ == "__main__":
    test_full_automated_tender_flow()
