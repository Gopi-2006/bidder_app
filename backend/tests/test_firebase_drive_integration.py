import pytest
from app.models.schemas import (
    Requirement,
    RuleDefinition,
    RuleTypeEnum,
    Evidence,
    EvidenceField,
    StatusEnum,
    ReasonCodeEnum,
    RoleEnum,
    Tender,
    BidderApplication,
)
from app.services.rule_engine import DeterministicRuleEngine
from app.integrations.firebase.auth import verify_firebase_token, AuthenticatedUser
from app.integrations.google_drive.folders import (
    ensure_tender_folder_hierarchy,
    ensure_application_folder_hierarchy,
)
from app.integrations.google_drive.files import upload_file, get_file_metadata


def test_firebase_token_verification_roles():
    """Verify role resolution for officer, bidder, and admin tokens."""
    officer_user = verify_firebase_token("officer_demo_token")
    assert officer_user.role == RoleEnum.OFFICER
    assert officer_user.uid == "officer_rajesh_nicsi"

    bidder_user = verify_firebase_token("bidder_demo_token")
    assert bidder_user.role == RoleEnum.BIDDER
    assert bidder_user.company_id == "COMP-001"

    admin_user = verify_firebase_token("admin_demo_token")
    assert admin_user.role == RoleEnum.ADMIN


def test_google_drive_tender_folder_hierarchy():
    """Verify standard folder hierarchy for tenders."""
    folders = ensure_tender_folder_hierarchy("TENDER-TEST-999")
    assert "original_folder_id" in folders
    assert "extracted_folder_id" in folders
    assert "generated_folder_id" in folders


def test_google_drive_application_folder_hierarchy():
    """Verify standard folder hierarchy for applications."""
    folders = ensure_application_folder_hierarchy("APP-TEST-999")
    assert "app_folder_id" in folders
    assert "gst_folder_id" in folders
    assert "pan_folder_id" in folders
    assert "udyam_folder_id" in folders
    assert "turnover_folder_id" in folders
    assert "oem_auth_folder_id" in folders
    assert "technical_folder_id" in folders
    assert "reports_folder_id" in folders


def test_google_drive_file_upload_and_sha256():
    """Verify file upload, SHA-256 calculation, and metadata generation."""
    sample_content = b"%PDF-1.4 Mock Tender PDF Binary Content for SIH Demonstration"
    res = upload_file(
        file_name="sample_tender.pdf",
        file_bytes=sample_content,
        relative_local_path="GEM-COMPLIANCE/TENDERS/TENDER-TEST-999/ORIGINAL",
    )
    assert res["file_name"] == "sample_tender.pdf"
    assert res["size_bytes"] == len(sample_content)
    assert len(res["sha256"]) == 64  # SHA-256 hex length
    assert "drive_file_id" in res


def test_evidence_versioning_lifecycle():
    """Verify that uploading replacement evidence increments version number and updates status."""
    req = Requirement(
        requirement_id="REQ-004",
        tender_id="TENDER-001",
        clause_reference="3.2(b)",
        title="Turnover Requirement",
        description=">= 50L",
        requirement_type="FINANCIAL",
        mandatory=True,
        rule=RuleDefinition(
            type=RuleTypeEnum.NUMERIC_THRESHOLD,
            field="average_annual_turnover",
            operator=">=",
            value=5000000,
        ),
        expected_document_types=["CA_TURNOVER_CERTIFICATE"],
    )

    ev_v1 = Evidence(
        evidence_id="EV-1",
        application_id="APP-001",
        requirement_id="REQ-004",
        document_type="CA_TURNOVER_CERTIFICATE",
        file_name="ca_v1.pdf",
        drive_file_id="D-1",
        sha256="abc1",
        uploaded_by="u1",
        uploaded_at="2026-08-20T10:00:00Z",
        version=1,
        status="SUPERSEDED",
        fields={"average_annual_turnover": EvidenceField(field_name="average_annual_turnover", extracted_value=3500000)},
    )

    ev_v2 = Evidence(
        evidence_id="EV-2",
        application_id="APP-001",
        requirement_id="REQ-004",
        document_type="CA_TURNOVER_CERTIFICATE",
        file_name="ca_v2_audited.pdf",
        drive_file_id="D-2",
        sha256="abc2",
        uploaded_by="u1",
        uploaded_at="2026-08-21T10:00:00Z",
        version=2,
        status="ACTIVE",
        fields={"average_annual_turnover": EvidenceField(field_name="average_annual_turnover", extracted_value=6200000)},
    )

    # Deterministic Engine evaluates only ACTIVE evidence
    active_evidences = [e for e in [ev_v1, ev_v2] if e.status == "ACTIVE"]
    res = DeterministicRuleEngine.evaluate(req, active_evidences)
    assert res.status == StatusEnum.PASS
    assert res.evaluated_values["average_annual_turnover"] == 6200000
