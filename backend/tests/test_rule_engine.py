import pytest
from app.models.schemas import (
    Requirement,
    RuleDefinition,
    RuleTypeEnum,
    Evidence,
    EvidenceField,
    StatusEnum,
    ReasonCodeEnum,
)
from app.services.rule_engine import DeterministicRuleEngine


def test_required_document_pass():
    req = Requirement(
        requirement_id="REQ-001",
        tender_id="T-1",
        clause_reference="2.1",
        title="GST Certificate",
        description="Mandatory GST",
        requirement_type="STATUTORY",
        mandatory=True,
        rule=RuleDefinition(type=RuleTypeEnum.REQUIRED_DOCUMENT, mandatory=True),
        expected_document_types=["GST_CERTIFICATE"],
    )
    ev = Evidence(
        evidence_id="EV-1",
        application_id="APP-1",
        document_type="GST_CERTIFICATE",
        file_name="gst.pdf",
        drive_file_id="D-1",
        sha256="abc",
        uploaded_by="u1",
        uploaded_at="2026-08-20T10:00:00Z",
        fields={"status": EvidenceField(field_name="status", extracted_value="ACTIVE")},
    )
    res = DeterministicRuleEngine.evaluate(req, [ev])
    assert res.status == StatusEnum.PASS
    assert len(res.reason_codes) == 0


def test_missing_mandatory_evidence_fail():
    req = Requirement(
        requirement_id="REQ-001",
        tender_id="T-1",
        clause_reference="2.1",
        title="GST Certificate",
        description="Mandatory GST",
        requirement_type="STATUTORY",
        mandatory=True,
        rule=RuleDefinition(type=RuleTypeEnum.REQUIRED_DOCUMENT, mandatory=True),
        expected_document_types=["GST_CERTIFICATE"],
    )
    res = DeterministicRuleEngine.evaluate(req, [])
    assert res.status == StatusEnum.FAIL
    assert ReasonCodeEnum.MISSING_EVIDENCE in res.reason_codes


def test_numeric_threshold_pass_and_fail():
    req = Requirement(
        requirement_id="REQ-004",
        tender_id="T-1",
        clause_reference="3.2",
        title="Turnover",
        description=">= 50 Lakhs",
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
    # Test passing evidence (62 Lakhs)
    ev_pass = Evidence(
        evidence_id="EV-2",
        application_id="APP-1",
        document_type="CA_TURNOVER_CERTIFICATE",
        file_name="ca.pdf",
        drive_file_id="D-2",
        sha256="abc",
        uploaded_by="u1",
        uploaded_at="2026-08-20T10:00:00Z",
        fields={"average_annual_turnover": EvidenceField(field_name="average_annual_turnover", extracted_value=6200000)},
    )
    res_pass = DeterministicRuleEngine.evaluate(req, [ev_pass])
    assert res_pass.status == StatusEnum.PASS

    # Test failing evidence (38.5 Lakhs)
    ev_fail = Evidence(
        evidence_id="EV-3",
        application_id="APP-2",
        document_type="CA_TURNOVER_CERTIFICATE",
        file_name="ca2.pdf",
        drive_file_id="D-3",
        sha256="def",
        uploaded_by="u2",
        uploaded_at="2026-08-20T10:00:00Z",
        fields={"average_annual_turnover": EvidenceField(field_name="average_annual_turnover", extracted_value=3850000)},
    )
    res_fail = DeterministicRuleEngine.evaluate(req, [ev_fail])
    assert res_fail.status == StatusEnum.FAIL
    assert ReasonCodeEnum.BELOW_THRESHOLD in res_fail.reason_codes


def test_cross_document_matching():
    req = Requirement(
        requirement_id="REQ-002",
        tender_id="T-1",
        clause_reference="2.2",
        title="PAN Match",
        description="Match company",
        requirement_type="STATUTORY",
        mandatory=True,
        rule=RuleDefinition(
            type=RuleTypeEnum.CROSS_DOCUMENT_MATCH,
            left={"field": "legal_name"},
            right={"field": "legal_name"},
            allowed_similarity=0.85,
        ),
        expected_document_types=["PAN_CARD"],
    )
    ev = Evidence(
        evidence_id="EV-4",
        application_id="APP-1",
        document_type="PAN_CARD",
        file_name="pan.pdf",
        drive_file_id="D-4",
        sha256="xyz",
        uploaded_by="u1",
        uploaded_at="2026-08-20T10:00:00Z",
        fields={"legal_name": EvidenceField(field_name="legal_name", extracted_value="Bharat Infotech & Networks Private Limited")},
    )
    # Match against profile
    res = DeterministicRuleEngine.evaluate(req, [ev], context={"legal_name": "Bharat Infotech & Networks Pvt Ltd"})
    assert res.status == StatusEnum.PASS
