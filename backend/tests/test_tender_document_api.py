import io
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_officer_upload_and_stream_tender_document():
    # 1. Create a test tender
    tender_payload = {
        "tender_id": "TENDER-DOC-TEST-001",
        "bid_number": "GEM/2026/B/9990001",
        "title": "Supply of Optical Fiber Networking Equipment",
        "organization": "Department of Telecommunications",
        "ministry": "Ministry of Communications",
        "category": "GOODS",
        "estimated_value": 5000000.0,
        "issue_date": "2026-03-01",
        "submission_deadline": "2026-03-31",
        "status": "DRAFT",
        "created_by": "officer_rajesh_nicsi",
        "created_at": "2026-03-01T00:00:00Z",
        "requirements": [],
    }

    create_res = client.post(
        "/api/v1/tenders",
        json=tender_payload,
        headers={"Authorization": "Bearer officer_demo_token"},
    )
    assert create_res.status_code == 200

    # 2. Upload tender PDF as officer
    pdf_content = b"%PDF-1.4\n1 0 obj\n<< /Title (Optical Fiber Tender Notice) >>\nendobj\ntrailer\n<< /Root 1 0 R >>\n%%EOF"
    upload_res = client.post(
        "/api/v1/tenders/TENDER-DOC-TEST-001/document",
        files={"file": ("optical_fiber_tender.pdf", io.BytesIO(pdf_content), "application/pdf")},
        headers={"Authorization": "Bearer officer_demo_token"},
    )
    assert upload_res.status_code == 200
    upload_data = upload_res.json()
    assert upload_data["status"] == "SUCCESS"
    assert upload_data["tender_id"] == "TENDER-DOC-TEST-001"
    assert upload_data["file_name"] == "optical_fiber_tender.pdf"
    assert "original_file_id" in upload_data

    # 3. Stream tender document as bidder
    stream_res = client.get(
        "/api/v1/tenders/TENDER-DOC-TEST-001/document",
        headers={"Authorization": "Bearer bidder_demo_token"},
    )
    assert stream_res.status_code == 200
    assert stream_res.headers["content-type"] == "application/pdf"
    assert stream_res.content == pdf_content


def test_unsupported_file_type_rejected():
    res = client.post(
        "/api/v1/tenders/TENDER-DOC-TEST-001/document",
        files={"file": ("invalid_file.exe", io.BytesIO(b"binary data"), "application/x-msdownload")},
        headers={"Authorization": "Bearer officer_demo_token"},
    )
    assert res.status_code == 415


def test_nonexistent_tender_document_404():
    res = client.get(
        "/api/v1/tenders/NONEXISTENT-TENDER-999/document",
        headers={"Authorization": "Bearer bidder_demo_token"},
    )
    assert res.status_code == 404
