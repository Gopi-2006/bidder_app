import pytest
from app.services.gemini_extractor import GeminiTenderExtractorService
from app.models.schemas import Tender
from app.api.endpoints import _normalize_firestore_tender


def test_gemini_extractor_deterministic_parsing():
    sample_text = """
    बड  ववरण/Bid Details
    Bid Number: GEM/2026/B/894210
    Dated: 15-08-2026
    Bid End Date/Time
    25-08-2026 15:00:00
    Bid Opening Date/Time
    25-08-2026 15:30:00
    Bid Offer Validity (From End Date)
    180 (Days)
    Ministry/State Name
    Ministry Of Defence
    Department Name
    Department Of Defence Production
    Organisation Name
    Bharat Electronics Limited
    Item Category
    Digital VHF Repeater Set
    Total Quantity
    50
    EMD Detail
    Required
    Yes
    EMD Amount
    50000
    ePBG Detail
    Required
    Yes
    MSE Purchase Preference
    Yes
    MII Purchase Preference
    Yes
    Document required from seller
    Experience Criteria, OEM Authorization Certificate, Technical Compliance
    Past Performance
    40 %
    Contact details of Grievance redressal
    HOD Email id :buyer.bel@gembuyer.in
    """

    data = GeminiTenderExtractorService.parse_gem_deterministic(
        text=sample_text,
        filename="GeM-Bidding-894210.pdf",
        tender_id="TENDER-2026-001",
    )

    assert data["bid_number"] == "GEM/2026/B/894210"
    assert data["issue_date"] == "15-08-2026"
    assert data["bid_end_date"] == "25-08-2026"
    assert data["bid_end_time"] == "15:00:00"
    assert data["submission_deadline"] == "25-08-2026 15:00:00"
    assert data["bid_opening_date"] == "25-08-2026 15:30:00"
    assert data["ministry"] == "Ministry Of Defence"
    assert data["department"] == "Department Of Defence Production"
    assert data["organization"] == "Bharat Electronics Limited"
    assert data["category"] == "Digital VHF Repeater Set"
    assert data["quantity"] == 50.0
    assert data["emd_required"] is True
    assert data["emd_amount"] == 50000.0
    assert data["performance_security"] == "Required"
    assert data["mse_preference"] == "Yes"
    assert data["make_in_india_preference"] == "Yes"
    assert data["oem_authorization_requirement"] is True
    assert "40 %" in data["experience_requirement"]


def test_gemini_extractor_empty_fallback():
    result = GeminiTenderExtractorService.extract_structured_tender(
        pdf_bytes=b"",
        tender_id="TENDER-2026-999",
        filename="corrupted.pdf",
        folder_id="folder_123",
        drive_file_id="file_123",
    )

    assert result["tender_id"] == "TENDER-2026-999"
    assert result["extraction_status"] == "FAILED"
    assert result["original_file_id"] == "file_123"


def test_tender_normalization_with_extracted_fields():
    raw_doc = {
        "tender_id": "TENDER-2026-042",
        "bid_number": "GEM/2026/B/7891234",
        "title": "Procurement of Medical Equipment",
        "organization": "AIIMS New Delhi",
        "ministry": "Ministry of Health and Family Welfare",
        "department": "Department of Medical Supplies",
        "category": "Medical Equipment",
        "quantity": 12.0,
        "unit": "Units",
        "submission_deadline": "30-09-2026 16:00:00",
        "emd_required": True,
        "emd_amount": 75000.0,
        "mse_preference": "Yes",
        "make_in_india_preference": "Yes",
        "extraction_status": "COMPLETED",
        "extraction_source": "PYMUPDF_GEM_PARSER",
        "original_file_id": "drive_file_abc",
        "requirements": [],
    }

    tender = _normalize_firestore_tender(raw_doc, "TENDER-2026-042")
    assert tender is not None
    assert tender.tender_id == "TENDER-2026-042"
    assert tender.bid_number == "GEM/2026/B/7891234"
    assert tender.quantity == 12.0
    assert tender.emd_required is True
    assert tender.emd_amount == 75000.0
    assert tender.estimated_value is None
    assert tender.extraction_status == "COMPLETED"


def test_estimated_value_extraction_states():
    # 1. Actual value found in lakhs
    text_lakh = "अनुमािनत  बड मूYय / Estimated Bid Value\n61.62 Lakhs\nOther Info"
    data_lakh = GeminiTenderExtractorService.parse_gem_deterministic(text_lakh, "test.pdf", "T-1")
    assert data_lakh["estimated_value"] == 6162000.0

    # 2. Actual value found in plain INR
    text_inr = "Estimated Bid Value in INR (Inclusive of all taxes)\n960000\nPayment Timelines"
    data_inr = GeminiTenderExtractorService.parse_gem_deterministic(text_inr, "test.pdf", "T-2")
    assert data_inr["estimated_value"] == 960000.0

    # 3. Explicit zero stated
    text_zero = "Estimated Bid Value: ₹0\nDetails"
    data_zero = GeminiTenderExtractorService.parse_gem_deterministic(text_zero, "test.pdf", "T-3")
    assert data_zero["estimated_value"] == 0.0

    # 4. Missing estimated value
    text_missing = "Item Category: Medical Consumables\nTotal Quantity: 10\nEMD Required: No"
    data_missing = GeminiTenderExtractorService.parse_gem_deterministic(text_missing, "test.pdf", "T-4")
    assert data_missing["estimated_value"] is None

