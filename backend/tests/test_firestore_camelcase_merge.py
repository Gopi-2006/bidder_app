import io
import pytest
from unittest.mock import patch
from fastapi.testclient import TestClient
from app.main import app
from app.api.endpoints import _normalize_firestore_tender
from app.integrations.firebase.firestore import FirestoreRepository

client = TestClient(app)

def test_firestore_camelcase_normalization():
    # Test document with random doc_id and camelCase fields
    raw_doc = {
        "_doc_id": "T8E7P0ftrx9v9GE8jsESO",
        "tender_id": "TENDER-TEST-001",
        "title": "Supply, Installation and Maintenance of Network Equipment",
        "organization": "Government Department",
        "ministry": "Ministry of Electronics and IT",
        "category": "IT Equipment",
        "estimatedValue": "5000000",
        "submissionDeadline": "2026-10-30",
        "status": "PUBLISHED",
        "ruleSetVersion": "v1.0",
        "originalFileId": "1DrWeoNI-O04-VupzH_neS6Qm8CkOEhbM",
        "driveFolderId": "1E4r8fwyculbnRYurtLip5-tGMbSUAWfq",
        "fileName": "Sample_GeM_Bidder_Tender_Submission_Test.pdf",
        "createdBy": "officer_rajesh_nicsi",
        "createdAt": "2026-09-02T00:00:00Z",
    }
    
    tender = _normalize_firestore_tender(raw_doc, "T8E7P0ftrx9v9GE8jsESO")
    assert tender is not None
    assert tender.tender_id == "TENDER-TEST-001"
    assert tender.original_file_id == "1DrWeoNI-O04-VupzH_neS6Qm8CkOEhbM"
    assert tender.source_drive_file_id == "1DrWeoNI-O04-VupzH_neS6Qm8CkOEhbM"
    assert tender.drive_folder_id == "1E4r8fwyculbnRYurtLip5-tGMbSUAWfq"
    assert tender.file_name == "Sample_GeM_Bidder_Tender_Submission_Test.pdf"
    assert tender.estimated_value == 5000000.0
    assert tender.status == "PUBLISHED"

def test_firestore_random_doc_id_fallback():
    # Test when tender_id field is not explicitly present, falls back to doc_id
    raw_doc = {
        "_doc_id": "TENDER-FALLBACK-002",
        "title": "Fallback Tender Notice",
        "originalFileId": "1AbCdEfGhIjKlMnOP",
        "status": "PUBLISHED",
    }
    tender = _normalize_firestore_tender(raw_doc, "TENDER-FALLBACK-002")
    assert tender is not None
    assert tender.tender_id == "TENDER-FALLBACK-002"
    assert tender.original_file_id == "1AbCdEfGhIjKlMnOP"
    assert tender.status == "PUBLISHED"
    assert tender.category in ["Government Tender", "GOODS"]

def test_api_tenders_merge_firestore_and_seeds():
    mock_firestore_doc = {
        "_doc_id": "T8E7P0ftrx9v9GE8jsESO",
        "tender_id": "TENDER-TEST-001",
        "title": "Supply, Installation and Maintenance of Network Equipment",
        "organization": "Government Department",
        "ministry": "Ministry of Electronics and IT",
        "category": "IT Equipment",
        "estimatedValue": 5000000,
        "submissionDeadline": "2026-10-30",
        "status": "PUBLISHED",
        "originalFileId": "1DrWeoNI-O04-VupzH_neS6Qm8CkOEhbM",
        "fileName": "Sample_GeM_Bidder_Tender_Submission_Test.pdf",
    }
    
    with patch.object(FirestoreRepository, "list_published_tenders", return_value=[mock_firestore_doc]), \
         patch.object(FirestoreRepository, "get_tender", return_value=mock_firestore_doc):
        
        # 1. GET /api/v1/tenders
        res = client.get("/api/v1/tenders")
        assert res.status_code == 200
        tenders = res.json()
        
        # Must contain both seed and Firestore tender
        tender_ids = [t["tender_id"] for t in tenders]
        assert "TENDER-2026-001" in tender_ids
        assert "TENDER-TEST-001" in tender_ids
        
        test_t = next(t for t in tenders if t["tender_id"] == "TENDER-TEST-001")
        assert test_t["original_file_id"] == "1DrWeoNI-O04-VupzH_neS6Qm8CkOEhbM"
        assert test_t["status"] == "PUBLISHED"
        assert test_t["file_name"] == "Sample_GeM_Bidder_Tender_Submission_Test.pdf"
        
        # 2. GET /api/v1/tenders/TENDER-TEST-001
        res_single = client.get("/api/v1/tenders/TENDER-TEST-001")
        assert res_single.status_code == 200
        assert res_single.json()["tender_id"] == "TENDER-TEST-001"
        assert res_single.json()["original_file_id"] == "1DrWeoNI-O04-VupzH_neS6Qm8CkOEhbM"

if __name__ == "__main__":
    pytest.main(["-v", __file__])
