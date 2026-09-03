import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.services.government_verifier import GovernmentVerifierService, normalize_company_name

client = TestClient(app)

def test_company_name_normalization():
    assert normalize_company_name("Nexora Technologies Pvt. Ltd.") == normalize_company_name("M/s Nexora Technologies Private Limited")
    assert normalize_company_name("Nexora Technologies Limited") == normalize_company_name("nexora technologies ltd.")
    assert normalize_company_name("Apex Infotech Solutions Pvt. Ltd.") != normalize_company_name("Nexora Technologies Pvt. Ltd.")

def test_government_verification_success_nexora():
    req_data = {
        "pan_number": "ABCDE1234F",
        "gst_number": "22AAAAA1234A1Z5",
        "udyam_number": "UDYAM-MH-01-0000001",
        "oem_authorization_number": "OEM-MH-2026-001",
        "pin": "784920"
    }
    response = client.post("/api/v1/auth/verify-government-details", json=req_data)
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["verified"] is True
    assert data["message"] == "Government details verified successfully"
    assert data["company"]["name"] == "Nexora Technologies Pvt. Ltd."
    assert data["company"]["pan"] == "ABCDE1234F"
    assert data["government_details"]["pan"]["pan_status"] == "Active"
    assert data["government_details"]["gst"]["registration_status"] == "Active"
    assert data["government_details"]["udyam"]["enterprise_type"] == "Manufacturing"
    assert data["government_details"]["oem"]["oem_name"] == "Dell International"

def test_government_verification_invalid_pan():
    req_data = {
        "pan_number": "INVALID999",
        "gst_number": "22AAAAA1234A1Z5",
        "udyam_number": "UDYAM-MH-01-0000001",
        "oem_authorization_number": "OEM-MH-2026-001",
        "pin": "784920"
    }
    response = client.post("/api/v1/auth/verify-government-details", json=req_data)
    assert response.status_code == 400
    assert response.json()["detail"] == "PAN details could not be verified."

def test_government_verification_invalid_gst():
    req_data = {
        "pan_number": "ABCDE1234F",
        "gst_number": "99INVALID999Z9Z",
        "udyam_number": "UDYAM-MH-01-0000001",
        "oem_authorization_number": "OEM-MH-2026-001",
        "pin": "784920"
    }
    response = client.post("/api/v1/auth/verify-government-details", json=req_data)
    assert response.status_code == 400
    assert response.json()["detail"] == "GST details could not be verified."

def test_government_verification_invalid_udyam():
    req_data = {
        "pan_number": "ABCDE1234F",
        "gst_number": "22AAAAA1234A1Z5",
        "udyam_number": "UDYAM-XX-99-9999999",
        "oem_authorization_number": "OEM-MH-2026-001",
        "pin": "784920"
    }
    response = client.post("/api/v1/auth/verify-government-details", json=req_data)
    assert response.status_code == 400
    assert response.json()["detail"] == "Udyam details could not be verified."

def test_government_verification_invalid_oem():
    req_data = {
        "pan_number": "ABCDE1234F",
        "gst_number": "22AAAAA1234A1Z5",
        "udyam_number": "UDYAM-MH-01-0000001",
        "oem_authorization_number": "OEM-INVALID-999",
        "pin": "784920"
    }
    response = client.post("/api/v1/auth/verify-government-details", json=req_data)
    assert response.status_code == 400
    assert response.json()["detail"] == "OEM authorization could not be verified."

def test_government_verification_wrong_pin():
    req_data = {
        "pan_number": "ABCDE1234F",
        "gst_number": "22AAAAA1234A1Z5",
        "udyam_number": "UDYAM-MH-01-0000001",
        "oem_authorization_number": "OEM-MH-2026-001",
        "pin": "000000"
    }
    response = client.post("/api/v1/auth/verify-government-details", json=req_data)
    assert response.status_code == 400
    assert response.json()["detail"] == "Verification PIN is incorrect."

def test_government_verification_company_mismatch():
    # Nexora PAN with Apex GST
    req_data = {
        "pan_number": "ABCDE1234F",
        "gst_number": "22BBBBB2345B1Z6",
        "udyam_number": "UDYAM-MH-01-0000001",
        "oem_authorization_number": "OEM-MH-2026-001",
        "pin": "784920"
    }
    response = client.post("/api/v1/auth/verify-government-details", json=req_data)
    assert response.status_code == 400
    assert response.json()["detail"] == "The government documents do not belong to the same company."

def test_government_verification_inactive_pan():
    req_data = {
        "pan_number": "FGHJK6789L",
        "gst_number": "27FFFFF6666F1Z0",
        "udyam_number": "UDYAM-MH-01-0000006",
        "oem_authorization_number": "OEM-MH-2022-999",
        "pin": "784920"
    }
    response = client.post("/api/v1/auth/verify-government-details", json=req_data)
    assert response.status_code == 400
    assert response.json()["detail"] == "PAN details could not be verified."

def test_government_verification_expired_oem():
    req_data = {
        "pan_number": "ABCDE1234F",
        "gst_number": "22AAAAA1234A1Z5",
        "udyam_number": "UDYAM-MH-01-0000001",
        "oem_authorization_number": "OEM-MH-2022-999",
        "pin": "784920"
    }
    response = client.post("/api/v1/auth/verify-government-details", json=req_data)
    assert response.status_code == 400
    assert response.json()["detail"] == "OEM authorization could not be verified."
