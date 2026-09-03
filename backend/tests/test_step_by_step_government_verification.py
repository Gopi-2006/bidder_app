import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

# 1. PAN Step Tests
def test_pan_step_success():
    res = client.post("/api/v1/government/verify/pan", json={"pan_number": "ABCDE1234F", "pin": "123456"})
    assert res.status_code == 200, res.text
    data = res.json()
    assert data["verified"] is True
    assert data["document_type"] == "PAN"
    assert data["details"]["pan_number"] == "ABCDE1234F"
    assert data["details"]["company_name"] == "Nexora Technologies Pvt. Ltd."
    assert "_pin" not in data["details"]

def test_pan_step_wrong_pin():
    res = client.post("/api/v1/government/verify/pan", json={"pan_number": "ABCDE1234F", "pin": "999999"})
    assert res.status_code == 400
    assert res.json()["detail"] == "Incorrect PAN verification PIN."

def test_pan_step_not_found():
    res = client.post("/api/v1/government/verify/pan", json={"pan_number": "UNKNOWN999", "pin": "123456"})
    assert res.status_code == 400
    assert res.json()["detail"] == "PAN details could not be verified."

# 2. Udyam Step Tests
def test_udyam_step_success():
    res = client.post("/api/v1/government/verify/udyam", json={"udyam_number": "UDYAM-MH-01-0000001", "pin": "123456"})
    assert res.status_code == 200, res.text
    data = res.json()
    assert data["verified"] is True
    assert data["document_type"] == "UDYAM"
    assert data["details"]["udyam_number"] == "UDYAM-MH-01-0000001"
    assert data["details"]["company_name"] == "Nexora Technologies Pvt. Ltd."
    assert "_pin" not in data["details"]

def test_udyam_step_wrong_pin():
    res = client.post("/api/v1/government/verify/udyam", json={"udyam_number": "UDYAM-MH-01-0000001", "pin": "999999"})
    assert res.status_code == 400
    assert res.json()["detail"] == "Incorrect Udyam verification PIN."

# 3. GST Step Tests
def test_gst_step_success():
    res = client.post("/api/v1/government/verify/gst", json={"gst_number": "22AAAAA1234A1Z5", "pin": "123456"})
    assert res.status_code == 200, res.text
    data = res.json()
    assert data["verified"] is True
    assert data["document_type"] == "GST"
    assert data["details"]["gstin"] == "22AAAAA1234A1Z5"
    assert data["details"]["company_name"] == "Nexora Technologies Pvt. Ltd."
    assert "_pin" not in data["details"]

def test_gst_step_wrong_pin():
    res = client.post("/api/v1/government/verify/gst", json={"gst_number": "22AAAAA1234A1Z5", "pin": "999999"})
    assert res.status_code == 400
    assert res.json()["detail"] == "Incorrect GST verification PIN."

# 4. OEM Step Tests
def test_oem_step_success():
    res = client.post("/api/v1/government/verify/oem", json={"oem_authorization_number": "OEM-MH-2026-001", "pin": "123456"})
    assert res.status_code == 200, res.text
    data = res.json()
    assert data["verified"] is True
    assert data["document_type"] == "OEM"
    assert data["details"]["authorization_number"] == "OEM-MH-2026-001"
    assert data["details"]["company_name"] == "Nexora Technologies Pvt. Ltd."
    assert "_pin" not in data["details"]

def test_oem_step_wrong_pin():
    res = client.post("/api/v1/government/verify/oem", json={"oem_authorization_number": "OEM-MH-2026-001", "pin": "999999"})
    assert res.status_code == 400
    assert res.json()["detail"] == "Incorrect OEM verification PIN."

def test_oem_step_inactive():
    res = client.post("/api/v1/government/verify/oem", json={"oem_authorization_number": "OEM-RJ-2026-006", "pin": "123456"})
    assert res.status_code == 400
    assert res.json()["detail"] == "OEM authorization could not be verified."

# 5. Finalize Verification Tests
def test_finalize_verification_success():
    pan_res = client.post("/api/v1/government/verify/pan", json={"pan_number": "ABCDE1234F", "pin": "123456"}).json()["details"]
    udyam_res = client.post("/api/v1/government/verify/udyam", json={"udyam_number": "UDYAM-MH-01-0000001", "pin": "123456"}).json()["details"]
    gst_res = client.post("/api/v1/government/verify/gst", json={"gst_number": "22AAAAA1234A1Z5", "pin": "123456"}).json()["details"]
    oem_res = client.post("/api/v1/government/verify/oem", json={"oem_authorization_number": "OEM-MH-2026-001", "pin": "123456"}).json()["details"]

    final_res = client.post("/api/v1/government/verify/finalize", json={
        "pan": pan_res,
        "udyam": udyam_res,
        "gst": gst_res,
        "oem": oem_res
    })
    assert final_res.status_code == 200, final_res.text
    data = final_res.json()
    assert data["verified"] is True
    assert data["company"]["company_name"] == "Nexora Technologies Pvt. Ltd."
    assert data["company"]["pan"]["pan_number"] == "ABCDE1234F"
    assert data["company"]["verification_source"] == "DEMO_GOOGLE_SHEETS"
    assert "_pin" not in str(data["company"])

def test_finalize_verification_company_mismatch():
    pan_res = client.post("/api/v1/government/verify/pan", json={"pan_number": "ABCDE1234F", "pin": "123456"}).json()["details"]
    udyam_res = client.post("/api/v1/government/verify/udyam", json={"udyam_number": "UDYAM-MH-01-0000001", "pin": "123456"}).json()["details"]
    gst_res = client.post("/api/v1/government/verify/gst", json={"gst_number": "22BBBBB2345B1Z6", "pin": "123456"}).json()["details"] # BluePeak Solutions
    oem_res = client.post("/api/v1/government/verify/oem", json={"oem_authorization_number": "OEM-MH-2026-001", "pin": "123456"}).json()["details"]

    final_res = client.post("/api/v1/government/verify/finalize", json={
        "pan": pan_res,
        "udyam": udyam_res,
        "gst": gst_res,
        "oem": oem_res
    })
    assert final_res.status_code == 400
    assert final_res.json()["detail"] == "The submitted government details do not belong to the same company."
