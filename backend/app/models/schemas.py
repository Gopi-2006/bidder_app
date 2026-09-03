from enum import Enum
from typing import Any, Dict, List, Optional, Union
from pydantic import BaseModel, Field


class RoleEnum(str, Enum):
    BIDDER = "BIDDER"
    OFFICER = "OFFICER"
    ADMIN = "ADMIN"


class StatusEnum(str, Enum):
    PASS = "PASS"
    FAIL = "FAIL"
    REVIEW = "REVIEW"
    PENDING = "PENDING"
    PROCESSING = "PROCESSING"


class ApplicationStatusEnum(str, Enum):
    DRAFT = "DRAFT"
    IN_PROGRESS = "IN_PROGRESS"
    PROCESSING = "PROCESSING"
    READY_FOR_REVIEW = "READY_FOR_REVIEW"
    SUBMITTED = "SUBMITTED"
    UNDER_OFFICER_REVIEW = "UNDER_OFFICER_REVIEW"
    DECIDED = "DECIDED"


class ReasonCodeEnum(str, Enum):
    MISSING_EVIDENCE = "MISSING_EVIDENCE"
    BELOW_THRESHOLD = "BELOW_THRESHOLD"
    EXPIRED = "EXPIRED"
    IDENTITY_MISMATCH = "IDENTITY_MISMATCH"
    CONFLICTING_EVIDENCE = "CONFLICTING_EVIDENCE"
    LOW_CONFIDENCE = "LOW_CONFIDENCE"
    UNSUPPORTED_RULE = "UNSUPPORTED_RULE"
    EXTERNAL_VERIFICATION_UNAVAILABLE = "EXTERNAL_VERIFICATION_UNAVAILABLE"
    UNSPECIFIED_BID_NUMBER = "UNSPECIFIED_BID_NUMBER"
    CERTIFICATE_MISSING = "CERTIFICATE_MISSING"


class RuleTypeEnum(str, Enum):
    REQUIRED_DOCUMENT = "required_document"
    NUMERIC_THRESHOLD = "numeric_threshold"
    DATE_VALIDITY = "date_validity"
    TEXT_MATCH = "text_match"
    BOOLEAN_DECLARATION = "boolean_declaration"
    SET_MEMBERSHIP = "set_membership"
    CROSS_DOCUMENT_MATCH = "cross_document_match"


class RuleDefinition(BaseModel):
    type: RuleTypeEnum
    field: Optional[str] = None
    operator: Optional[str] = None  # ">=", "<=", "==", "in", "matches"
    value: Optional[Union[float, int, str, List[str]]] = None
    currency: Optional[str] = "INR"
    reference: Optional[str] = None  # e.g., "application_submission_date"
    left: Optional[Dict[str, Any]] = None
    right: Optional[Dict[str, Any]] = None
    normalization: Optional[List[str]] = None
    allowed_similarity: Optional[float] = 0.90
    mandatory: bool = True


class Requirement(BaseModel):
    requirement_id: str
    tender_id: str
    clause_reference: str
    title: str
    description: str
    requirement_type: str
    mandatory: bool = True
    rule: RuleDefinition
    expected_document_types: List[str] = []
    validation_source: Optional[str] = "OCR_AND_EXTERNAL_API"
    ai_confidence: float = 0.95
    officer_verified: bool = False
    version: int = 1


class Tender(BaseModel):
    tender_id: str = ""
    bid_number: str = ""
    title: str = "Tender Notice"
    organization: str = "Government Department"
    ministry: str = ""
    department: Optional[str] = ""
    category: str = "Government Tender"
    item_description: Optional[str] = ""
    quantity: Optional[float] = 1.0
    unit: Optional[str] = "Units"
    estimated_value: Optional[float] = None
    issue_date: str = ""
    submission_deadline: str = ""
    bid_end_date: Optional[str] = ""
    bid_end_time: Optional[str] = ""
    bid_opening_date: Optional[str] = ""
    delivery_period: Optional[str] = "30 Days"
    place_of_delivery: Optional[str] = ""
    emd_amount: Optional[float] = 0.0
    emd_required: Optional[bool] = False
    performance_security: Optional[str] = "Not Required"
    bid_validity: Optional[str] = "180 Days"
    eligibility_criteria: Optional[str] = ""
    technical_requirements: Optional[str] = ""
    financial_requirements: Optional[str] = ""
    turnover_requirement: Optional[str] = ""
    experience_requirement: Optional[str] = ""
    oem_authorization_requirement: Optional[bool] = False
    mse_preference: Optional[str] = "Not Specified"
    make_in_india_preference: Optional[str] = "Not Specified"
    gst_required: Optional[bool] = True
    pan_required: Optional[bool] = True
    udyam_required: Optional[bool] = False
    contact_information: Optional[str] = ""
    source_drive_file_id: Optional[str] = None
    original_file_id: Optional[str] = None
    drive_folder_id: Optional[str] = None
    file_name: Optional[str] = None
    drive_folder_map: Optional[Dict[str, str]] = None
    extraction_status: Optional[str] = "COMPLETED"  # PENDING, PROCESSING, COMPLETED, FAILED
    extraction_source: Optional[str] = "PYMUPDF_GEM_PARSER"
    extracted_at: Optional[str] = ""
    extraction_error: Optional[str] = None
    status: str = "PUBLISHED"  # DRAFT, PUBLISHED, CLOSED
    rule_set_version: str = "v1.0"
    created_by: str = "officer_gem_01"
    created_at: str = ""
    published_at: Optional[str] = None
    requirements: List[Requirement] = []


class EvidenceField(BaseModel):
    field_name: str
    extracted_value: Any
    confidence: float = 0.95
    source_page: Optional[int] = 1
    raw_snippet: Optional[str] = None


class Evidence(BaseModel):
    evidence_id: str
    application_id: str
    requirement_id: Optional[str] = None
    document_type: str  # GST_CERTIFICATE, PAN_CARD, UDYAM_CERTIFICATE, CA_TURNOVER_CERTIFICATE, OEM_AUTHORIZATION, TECHNICAL_DECLARATION
    file_name: str
    drive_file_id: str
    sha256: str
    uploaded_by: str
    uploaded_at: str
    extraction_state: str = "COMPLETED"  # PENDING, PROCESSING, COMPLETED, FAILED
    fields: Dict[str, EvidenceField] = {}
    confidence: float = 0.95
    version: int = 1
    status: str = "ACTIVE"  # ACTIVE, SUPERSEDED, REJECTED


class RuleEvaluationResult(BaseModel):
    result_id: str
    requirement_id: str
    status: StatusEnum
    rule_version: str
    evidence_ids: List[str] = []
    evaluated_values: Dict[str, Any] = {}
    explanation: str
    plain_language_bidder_msg: str
    reason_codes: List[ReasonCodeEnum] = []
    engine_version: str = "1.0.0"
    timestamp: str
    officer_override: Optional[Dict[str, Any]] = None


class ReviewCase(BaseModel):
    case_id: str
    application_id: str
    requirement_id: str
    bidder_name: str
    tender_id: str
    status: str = "OPEN"  # OPEN, RESOLVED
    priority: str = "HIGH"  # HIGH, MEDIUM, LOW
    reason: str
    trigger: str
    rule_result: RuleEvaluationResult
    created_at: str
    resolved_at: Optional[str] = None
    resolved_by: Optional[str] = None
    resolution_action: Optional[str] = None  # ACCEPT, REJECT, REQUEST_CLARIFICATION, OVERRIDE_WITH_REASON
    resolution_comment: Optional[str] = None


class AuditLogEntry(BaseModel):
    audit_id: str
    actor_uid: str
    actor_name: str
    actor_role: RoleEnum
    action: str
    entity_type: str  # TENDER, REQUIREMENT, APPLICATION, EVIDENCE, REVIEW_CASE, DECISION
    entity_id: str
    previous_state: Optional[Union[str, Dict[str, Any]]] = None
    new_state: Optional[Union[str, Dict[str, Any]]] = None
    reason: Optional[str] = None
    evidence_ids: Optional[List[str]] = []
    correlation_id: Optional[str] = None
    timestamp: str


class BidderApplication(BaseModel):
    application_id: str
    tender_id: str
    bidder_company_id: str
    bidder_company_name: str
    bidder_uid: str
    submitted_at: str
    overall_status: ApplicationStatusEnum = ApplicationStatusEnum.IN_PROGRESS
    completion_percent: int = 0
    final_decision: Optional[str] = None  # QUALIFIED, DISQUALIFIED, PENDING_REVIEW
    decision_by: Optional[str] = None
    decision_at: Optional[str] = None
    decision_comments: Optional[str] = None
    results: List[RuleEvaluationResult] = []


class Notification(BaseModel):
    id: str
    user_id: str
    title: str
    message: str
    read: bool = False
    application_id: Optional[str] = None
    created_at: str


class GovernmentVerificationRequest(BaseModel):
    pan_number: str = Field(..., description="10-character PAN number")
    gst_number: str = Field(..., description="15-character GSTIN")
    udyam_number: str = Field(..., description="Udyam registration number")
    oem_authorization_number: str = Field(..., description="OEM authorization certificate number")
    pin: str = Field(..., description="Verification PIN")


class GovernmentVerificationResponse(BaseModel):
    verified: bool
    message: str
    user_id: Optional[str] = None
    custom_token: Optional[str] = None
    company: Optional[Dict[str, Any]] = None
    government_details: Optional[Dict[str, Any]] = None


# Step-by-step Government Verification Schemas (Simulated DigiLocker)
class PanVerificationRequest(BaseModel):
    pan_number: str = Field(..., description="Income Tax PAN Number")
    pin: str = Field(..., description="Verification PIN")


class UdyamVerificationRequest(BaseModel):
    udyam_number: str = Field(..., description="Udyam Registration Number")
    pin: str = Field(..., description="Verification PIN")


class GstVerificationRequest(BaseModel):
    gst_number: str = Field(..., description="GSTIN Identifier")
    pin: str = Field(..., description="Verification PIN")


class OemVerificationRequest(BaseModel):
    oem_authorization_number: str = Field(..., description="OEM Authorization Certificate Number")
    pin: str = Field(..., description="Verification PIN")


class SingleDocumentVerificationResponse(BaseModel):
    verified: bool
    document_type: str
    message: str
    details: Optional[Dict[str, Any]] = None


class FinalizeVerificationRequest(BaseModel):
    pan: Dict[str, Any]
    udyam: Dict[str, Any]
    gst: Dict[str, Any]
    oem: Dict[str, Any]


class FinalizeVerificationResponse(BaseModel):
    verified: bool
    message: str
    user_id: Optional[str] = None
    custom_token: Optional[str] = None
    company: Optional[Dict[str, Any]] = None




