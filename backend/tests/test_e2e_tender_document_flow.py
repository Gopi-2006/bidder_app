import os
import io
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.integrations.google_drive.files import download_file

client = TestClient(app)


def test_e2e_tender_document_pipeline():
    """
    End-to-End Test:
    1. Officer creates TENDER-TEST-001
    2. Officer uploads sample_tender.pdf
    3. Storage receives file in GEM-COMPLIANCE/TENDERS/TENDER-TEST-001/ORIGINAL/
    4. Firestore/DB contains originalFileId, driveFolderId, status='PUBLISHED'
    5. Bidder queries published tenders and sees TENDER-TEST-001
    6. Bidder streams tender PDF document successfully
    """
    tender_id = "TENDER-TEST-001"
    
    # 1. Create tender
    tender_data = {
        "tender_id": tender_id,
        "bid_number": "GEM/2026/B/9012344",
        "title": "SIH Test Tender - Supply of Networking Equipment",
        "organization": "National Informatics Centre Services Inc. (NICSI)",
        "ministry": "Ministry of Electronics and Information Technology",
        "category": "GOODS",
        "estimated_value": 5000000.0,
        "issue_date": "2026-03-01",
        "submission_deadline": "2026-03-31",
        "status": "DRAFT",
        "created_by": "officer_rajesh_nicsi",
        "created_at": "2026-03-01T10:00:00Z",
        "requirements": [],
    }

    res_create = client.post(
        "/api/v1/tenders",
        json=tender_data,
        headers={"Authorization": "Bearer officer_demo_token"},
    )
    assert res_create.status_code == 200

    # 2. Officer uploads sample_tender.pdf
    pdf_bytes = b"%PDF-1.4\n% GeM Official Sample Tender Document for SIH 2026\n1 0 obj\n<< /Title (SIH Test Tender) >>\nendobj\ntrailer\n<< /Root 1 0 R >>\n%%EOF"
    
    res_upload = client.post(
        f"/api/v1/tenders/{tender_id}/document",
        files={"file": ("sample_tender.pdf", io.BytesIO(pdf_bytes), "application/pdf")},
        headers={"Authorization": "Bearer officer_demo_token"},
    )
    assert res_upload.status_code == 200
    upload_json = res_upload.json()
    assert upload_json["status"] == "SUCCESS"
    assert upload_json["tender_id"] == tender_id
    assert upload_json["file_name"] == "sample_tender.pdf"
    assert "original_file_id" in upload_json
    assert "drive_folder_id" in upload_json
    
    drive_file_id = upload_json["original_file_id"]

    # 3. Verify storage content
    downloaded_content = download_file(drive_file_id)
    assert downloaded_content == pdf_bytes

    # 4. Bidder queries published tenders
    res_list = client.get(
        "/api/v1/tenders",
        headers={"Authorization": "Bearer bidder_demo_token"},
    )
    assert res_list.status_code == 200
    tenders = res_list.json()
    matching = [t for t in tenders if t["tender_id"] == tender_id]
    assert len(matching) == 1
    assert matching[0]["status"] == "PUBLISHED"
    assert matching[0]["file_name"] == "sample_tender.pdf"

    # 5. Bidder views/streams the document
    res_stream = client.get(
        f"/api/v1/tenders/{tender_id}/document",
        headers={"Authorization": "Bearer bidder_demo_token"},
    )
    assert res_stream.status_code == 200
    assert res_stream.headers["content-type"] == "application/pdf"
    assert res_stream.content == pdf_bytes
