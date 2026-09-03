from datetime import datetime
from typing import List, Dict, Any
from app.models.schemas import Requirement, RuleDefinition, RuleTypeEnum, EvidenceField


class TenderRuleExtractorService:
    """
    Simulates NLP/LLM candidate requirement extraction from Tender PDF clauses,
    segmenting text into structured candidate rules with confidence scores.
    """

    @classmethod
    def extract_rules_from_tender_text(cls, tender_id: str, text: str) -> List[Requirement]:
        # Predefined high-quality extracted candidates tailored for GeM IT/Hardware/Works tenders
        return [
            Requirement(
                requirement_id=f"REQ-{tender_id}-001",
                tender_id=tender_id,
                clause_reference="Clause 2.1 (Mandatory Statutory Filings)",
                title="GST Registration Certificate",
                description="Bidder must submit a valid Goods and Services Tax (GSTIN) registration certificate with active filing status.",
                requirement_type="STATUTORY",
                mandatory=True,
                rule=RuleDefinition(
                    type=RuleTypeEnum.REQUIRED_DOCUMENT,
                    mandatory=True,
                ),
                expected_document_types=["GST_CERTIFICATE"],
                ai_confidence=0.98,
                officer_verified=True,
                version=1,
            ),
            Requirement(
                requirement_id=f"REQ-{tender_id}-002",
                tender_id=tender_id,
                clause_reference="Clause 2.2 (Identity & PAN)",
                title="Permanent Account Number (PAN)",
                description="Bidder must furnish a valid company PAN card matching the registered enterprise name.",
                requirement_type="STATUTORY",
                mandatory=True,
                rule=RuleDefinition(
                    type=RuleTypeEnum.CROSS_DOCUMENT_MATCH,
                    left={"evidence_type": "PAN_CARD", "field": "legal_name"},
                    right={"source": "COMPANY_PROFILE", "field": "legal_name"},
                    allowed_similarity=0.88,
                    mandatory=True,
                ),
                expected_document_types=["PAN_CARD"],
                ai_confidence=0.96,
                officer_verified=True,
                version=1,
            ),
            Requirement(
                requirement_id=f"REQ-{tender_id}-003",
                tender_id=tender_id,
                clause_reference="Clause 3.1 (MSME / Make in India)",
                title="Udyam / MSME Registration Certificate",
                description="Valid Udyam registration certificate for availing GeM public procurement policy exemptions / preferences.",
                requirement_type="ELIGIBILITY",
                mandatory=False,
                rule=RuleDefinition(
                    type=RuleTypeEnum.REQUIRED_DOCUMENT,
                    mandatory=False,
                ),
                expected_document_types=["UDYAM_CERTIFICATE"],
                ai_confidence=0.92,
                officer_verified=True,
                version=1,
            ),
            Requirement(
                requirement_id=f"REQ-{tender_id}-004",
                tender_id=tender_id,
                clause_reference="Clause 3.2(b) (Financial Turnover)",
                title="Minimum Average Annual Turnover (₹50 Lakh)",
                description="The minimum average annual financial turnover of the bidder during the last three financial years (2022-23, 2023-24, 2024-25) must be at least ₹50,00,000 (Fifty Lakh INR) duly certified by a Chartered Accountant.",
                requirement_type="FINANCIAL",
                mandatory=True,
                rule=RuleDefinition(
                    type=RuleTypeEnum.NUMERIC_THRESHOLD,
                    field="average_annual_turnover",
                    operator=">=",
                    value=5000000,
                    currency="INR",
                    mandatory=True,
                ),
                expected_document_types=["CA_TURNOVER_CERTIFICATE"],
                ai_confidence=0.94,
                officer_verified=True,
                version=1,
            ),
            Requirement(
                requirement_id=f"REQ-{tender_id}-005",
                tender_id=tender_id,
                clause_reference="Clause 4.1 (OEM Authorization - MAF)",
                title="Manufacturer Authorization Form (MAF)",
                description="Bidder must submit a Manufacturer Authorization Form (MAF) from the OEM specifically authorizing participation in this GeM Bid.",
                requirement_type="TECHNICAL",
                mandatory=True,
                rule=RuleDefinition(
                    type=RuleTypeEnum.TEXT_MATCH,
                    field="authorization_scope",
                    operator="matches",
                    mandatory=True,
                ),
                expected_document_types=["OEM_AUTHORIZATION"],
                ai_confidence=0.89,
                officer_verified=True,
                version=1,
            ),
            Requirement(
                requirement_id=f"REQ-{tender_id}-006",
                tender_id=tender_id,
                clause_reference="Clause 5.3 (Technical Compliance & Security)",
                title="Technical Compliance & ISO 27001 Undertaking",
                description="Signed technical compliance sheet undertaking all technical specifications and holding valid ISO/IEC 27001 information security certification.",
                requirement_type="COMPLIANCE",
                mandatory=True,
                rule=RuleDefinition(
                    type=RuleTypeEnum.BOOLEAN_DECLARATION,
                    field="compliance_confirmed",
                    mandatory=True,
                ),
                expected_document_types=["TECHNICAL_DECLARATION"],
                ai_confidence=0.91,
                officer_verified=True,
                version=1,
            ),
        ]


class EvidenceOCRParserService:
    """
    Simulates OCR text recognition and structured field extraction from bidder uploads.
    """

    @classmethod
    def parse_document(cls, document_type: str, file_name: str) -> Dict[str, EvidenceField]:
        now = datetime.utcnow().strftime("%Y-%m-%d")
        if document_type == "GST_CERTIFICATE":
            return {
                "gstin": EvidenceField(field_name="gstin", extracted_value="29ABCDE1234F1Z5", confidence=0.99, source_page=1, raw_snippet="GSTIN: 29ABCDE1234F1Z5"),
                "legal_name": EvidenceField(field_name="legal_name", extracted_value="Bharat Infotech & Networks Pvt Ltd", confidence=0.97, source_page=1, raw_snippet="Legal Name: Bharat Infotech & Networks Private Limited"),
                "status": EvidenceField(field_name="status", extracted_value="ACTIVE", confidence=0.98, source_page=1, raw_snippet="Registration Status: Active"),
            }
        elif document_type == "PAN_CARD":
            return {
                "pan": EvidenceField(field_name="pan", extracted_value="ABCDE1234F", confidence=0.98, source_page=1, raw_snippet="Permanent Account Number: ABCDE1234F"),
                "legal_name": EvidenceField(field_name="legal_name", extracted_value="Bharat Infotech & Networks Pvt Ltd", confidence=0.95, source_page=1, raw_snippet="Name: BHARAT INFOTECH & NETWORKS PVT LTD"),
            }
        elif document_type == "UDYAM_CERTIFICATE":
            return {
                "udyam_number": EvidenceField(field_name="udyam_number", extracted_value="UDYAM-KR-03-0019284", confidence=0.96, source_page=1, raw_snippet="Udyam Reg: UDYAM-KR-03-0019284"),
                "enterprise_type": EvidenceField(field_name="enterprise_type", extracted_value="Medium", confidence=0.94, source_page=1, raw_snippet="Type: Medium Enterprise"),
            }
        elif document_type == "CA_TURNOVER_CERTIFICATE":
            # Real-world scenario: Turnover certified at ₹62 Lakhs
            return {
                "average_annual_turnover": EvidenceField(field_name="average_annual_turnover", extracted_value=6200000, confidence=0.96, source_page=2, raw_snippet="Average Annual Turnover for the last 3 FYs: Rs. 62,00,000/- (Rupees Sixty Two Lakhs Only)"),
                "ca_udinn": EvidenceField(field_name="ca_udinn", extracted_value="24098765AAAAAA1234", confidence=0.97, source_page=2, raw_snippet="UDIN: 24098765AAAAAA1234"),
                "period": EvidenceField(field_name="period", extracted_value="FY 2022-23 to 2024-25", confidence=0.95, source_page=2, raw_snippet="Financial Period: FY 2022-23, FY 2023-24, FY 2024-25"),
            }
        elif document_type == "OEM_AUTHORIZATION":
            return {
                "oem_name": EvidenceField(field_name="oem_name", extracted_value="Cisco Systems India Pvt Ltd", confidence=0.94, source_page=1, raw_snippet="Manufacturer: Cisco Systems"),
                "authorization_scope": EvidenceField(field_name="authorization_scope", extracted_value="General Partner Authorization (GeM Bid GEM/2026/B/894210)", confidence=0.91, source_page=1, raw_snippet="Authorized to quote for GeM Bid GEM/2026/B/894210"),
            }
        elif document_type == "TECHNICAL_DECLARATION":
            return {
                "compliance_confirmed": EvidenceField(field_name="compliance_confirmed", extracted_value=True, confidence=0.96, source_page=3, raw_snippet="We hereby confirm complete adherence to all technical parameters and specs."),
                "signed": EvidenceField(field_name="signed", extracted_value=True, confidence=0.98, source_page=3, raw_snippet="Authorized Signatory: Rajesh Sharma [Digital Signature Valid]"),
            }
        return {}
