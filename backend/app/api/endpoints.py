import io
import os
import json
import secrets
import hashlib
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, HTTPException, Query, Body, UploadFile, File, Form, Depends, Request, status
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

def get_utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()

def get_utc_timestamp() -> int:
    return int(datetime.now(timezone.utc).timestamp())

from app.models.schemas import (
    Tender,
    Requirement,
    BidderApplication,
    Evidence,
    RuleEvaluationResult,
    ReviewCase,
    AuditLogEntry,
    RoleEnum,
    StatusEnum,
    ApplicationStatusEnum,
    EvidenceField,
    Notification,
    GovernmentVerificationRequest,
    GovernmentVerificationResponse,
    PanVerificationRequest,
    UdyamVerificationRequest,
    GstVerificationRequest,
    OemVerificationRequest,
    SingleDocumentVerificationResponse,
    FinalizeVerificationRequest,
    FinalizeVerificationResponse,
)
from app.services.government_verifier import GovernmentVerifierService
from app.services.government_verification_provider import get_government_verification_provider
from app.services.rule_engine import DeterministicRuleEngine
from app.services.extraction import TenderRuleExtractorService, EvidenceOCRParserService
from app.integrations.verification import MockGSTAdapter, MockPANAdapter, MockUdyamAdapter
from app.integrations.google_drive import (
    ensure_tender_folder_hierarchy,
    ensure_application_folder_hierarchy,
    upload_file as drive_upload_file,
    download_file as drive_download_file,
    list_files as drive_list_files,
    list_drive_folder_pdf_files,
)
from app.integrations.google_drive.client import extract_drive_folder_id
from app.services.gemini_extractor import GeminiTenderExtractorService
from app.integrations.firebase import (
    AuthenticatedUser,
    get_current_user,
    require_bidder,
    require_officer,
    require_admin,
    FirestoreRepository,
)
from app.integrations.firebase.admin import FirebaseAdminManager
from app.data.seed_data import (
    SEED_TENDERS,
    SEED_APPLICATIONS,
    SEED_EVIDENCES_BHARAT,
    SEED_REVIEW_CASES,
    SEED_AUDIT_LOGS,
)

router = APIRouter(prefix="/api/v1")


@router.get("/health")
def api_health():
    return {
        "status": "ok",
        "service": "GeM AI Compliance Verification Backend",
        "version": "1.0.0",
    }

# Stateful memory stores with Firestore synchronization
TENDERS_DB: Dict[str, Tender] = {t.tender_id: t for t in SEED_TENDERS}
APPLICATIONS_DB: Dict[str, BidderApplication] = {a.application_id: a for a in SEED_APPLICATIONS}
EVIDENCES_DB: Dict[str, List[Evidence]] = {"APP-2026-000123": list(SEED_EVIDENCES_BHARAT)}
REVIEW_CASES_DB: Dict[str, ReviewCase] = {c.case_id: c for c in SEED_REVIEW_CASES}
AUDIT_LOGS_DB: List[AuditLogEntry] = list(SEED_AUDIT_LOGS)
NOTIFICATIONS_DB: List[Notification] = [
    Notification(
        id="NOTIF-001",
        user_id="bidder_bharat_uid",
        title="Compliance Status Updated",
        message="Clause 3.2(b) turnover requirement evaluated to REVIEW by Rule Engine.",
        read=False,
        application_id="APP-2026-000123",
        created_at=get_utc_now_iso(),
    ),
    Notification(
        id="NOTIF-002",
        user_id="bidder_bharat_uid",
        title="Tender Published on GeM",
        message="GEM/2026/B/9012344 has been published. Submission deadline: 2026-03-25.",
        read=True,
        created_at=get_utc_now_iso(),
    ),
]


# ===================== USER & PROFILE =====================

@router.get("/me")
def get_current_user_profile(user: AuthenticatedUser = Depends(get_current_user)):
    return {
        "uid": user.uid,
        "email": user.email,
        "name": user.name or "Bharat Bidder Admin",
        "role": user.role,
        "company_name": user.company_name or "Bharat Infotech & Networks Pvt Ltd",
        "company_id": "COMP-001",
        "gstin": "29ABCDE1234F1Z5",
        "active": True,
    }


# ===================== TENDERS & REQUIREMENTS =====================

def _normalize_firestore_tender(raw: dict, doc_id: str = "") -> Optional[Tender]:
    """Converts a Firestore tender document (camelCase or snake_case) into a Tender Pydantic model."""
    if not isinstance(raw, dict):
        return None

    camel_to_snake = {
        "tenderId": "tender_id",
        "bidNumber": "bid_number",
        "estimatedValue": "estimated_value",
        "issueDate": "issue_date",
        "submissionDeadline": "submission_deadline",
        "bidEndDate": "bid_end_date",
        "bidEndTime": "bid_end_time",
        "bidOpeningDate": "bid_opening_date",
        "deliveryPeriod": "delivery_period",
        "placeOfDelivery": "place_of_delivery",
        "emdAmount": "emd_amount",
        "emdRequired": "emd_required",
        "performanceSecurity": "performance_security",
        "bidValidity": "bid_validity",
        "eligibilityCriteria": "eligibility_criteria",
        "technicalRequirements": "technical_requirements",
        "financialRequirements": "financial_requirements",
        "turnoverRequirement": "turnover_requirement",
        "experienceRequirement": "experience_requirement",
        "oemAuthorizationRequirement": "oem_authorization_requirement",
        "msePreference": "mse_preference",
        "makeInIndiaPreference": "make_in_india_preference",
        "gstRequired": "gst_required",
        "panRequired": "pan_required",
        "udyamRequired": "udyam_required",
        "contactInformation": "contact_information",
        "itemDescription": "item_description",
        "extractionStatus": "extraction_status",
        "extractionSource": "extraction_source",
        "extractedAt": "extracted_at",
        "extractionError": "extraction_error",
        "ruleSetVersion": "rule_set_version",
        "originalFileId": "original_file_id",
        "sourceDriveFileId": "source_drive_file_id",
        "driveFolderId": "drive_folder_id",
        "fileName": "file_name",
        "driveFolderMap": "drive_folder_map",
        "createdBy": "created_by",
        "createdAt": "created_at",
        "publishedAt": "published_at",
    }
    normalized = {}
    for k, v in raw.items():
        snake_key = camel_to_snake.get(k, k)
        normalized[snake_key] = v

    # Resolve tender_id: prioritize tender_id/tenderId field, fallback to doc_id or auto-generated
    tender_id = (
        normalized.get("tender_id")
        or raw.get("tenderId")
        or raw.get("tender_id")
        or raw.get("_doc_id")
        or doc_id
        or ""
    )
    normalized["tender_id"] = str(tender_id).strip()

    # Resolve bid_number: prioritize bid_number/bidNumber, fallback to tender_id
    bid_number = (
        normalized.get("bid_number")
        or raw.get("bidNumber")
        or raw.get("bid_number")
        or normalized["tender_id"]
    )
    normalized["bid_number"] = str(bid_number).strip()

    # Resolve original_file_id and source_drive_file_id
    orig_file_id = (
        normalized.get("original_file_id")
        or raw.get("originalFileId")
        or raw.get("original_file_id")
        or normalized.get("source_drive_file_id")
        or raw.get("sourceDriveFileId")
        or raw.get("source_drive_file_id")
    )
    if orig_file_id:
        normalized["original_file_id"] = str(orig_file_id).strip()
        normalized["source_drive_file_id"] = str(orig_file_id).strip()

    # Resolve drive_folder_id
    drive_folder_id = (
        normalized.get("drive_folder_id")
        or raw.get("driveFolderId")
        or raw.get("drive_folder_id")
    )
    if drive_folder_id:
        normalized["drive_folder_id"] = str(drive_folder_id).strip()

    # Resolve file_name
    file_name = (
        normalized.get("file_name")
        or raw.get("fileName")
        or raw.get("file_name")
    )
    if file_name:
        normalized["file_name"] = str(file_name).strip()

    # Resolve estimated_value safely: keep None as None, preserve 0.0 or positive floats
    raw_est = normalized.get("estimated_value")
    if raw_est is None and "estimatedValue" in raw:
        raw_est = raw.get("estimatedValue")
    if raw_est is not None:
        try:
            normalized["estimated_value"] = float(raw_est)
        except (ValueError, TypeError):
            normalized["estimated_value"] = None
    else:
        normalized["estimated_value"] = None

    # Resolve quantity safely to float
    qty_val = normalized.get("quantity", 1.0)
    try:
        normalized["quantity"] = float(qty_val) if qty_val is not None else 1.0
    except (ValueError, TypeError):
        normalized["quantity"] = 1.0

    # Ensure required string fields have sensible defaults
    normalized.setdefault("title", raw.get("title") or f"Tender Notice ({normalized['tender_id']})")
    normalized.setdefault("organization", raw.get("organization") or "Government Department")
    normalized.setdefault("ministry", raw.get("ministry") or "")
    normalized.setdefault("department", raw.get("department") or "")
    normalized.setdefault("category", raw.get("category") or "Government Tender")
    normalized.setdefault("item_description", raw.get("itemDescription") or raw.get("item_description") or "")
    normalized.setdefault("unit", raw.get("unit") or "Units")
    normalized.setdefault("issue_date", raw.get("issueDate") or raw.get("issue_date") or "")
    normalized.setdefault("submission_deadline", raw.get("submissionDeadline") or raw.get("submission_deadline") or "")
    normalized.setdefault("bid_end_date", raw.get("bidEndDate") or raw.get("bid_end_date") or "")
    normalized.setdefault("bid_end_time", raw.get("bidEndTime") or raw.get("bid_end_time") or "")
    normalized.setdefault("bid_opening_date", raw.get("bidOpeningDate") or raw.get("bid_opening_date") or "")
    normalized.setdefault("delivery_period", raw.get("deliveryPeriod") or raw.get("delivery_period") or "30 Days")
    normalized.setdefault("place_of_delivery", raw.get("placeOfDelivery") or raw.get("place_of_delivery") or "")
    normalized.setdefault("emd_amount", float(raw.get("emdAmount") or raw.get("emd_amount") or 0.0))
    normalized.setdefault("emd_required", bool(raw.get("emdRequired") or raw.get("emd_required") or False))
    normalized.setdefault("performance_security", raw.get("performanceSecurity") or raw.get("performance_security") or "Not Required")
    normalized.setdefault("bid_validity", raw.get("bidValidity") or raw.get("bid_validity") or "180 Days")
    normalized.setdefault("eligibility_criteria", raw.get("eligibilityCriteria") or raw.get("eligibility_criteria") or "")
    normalized.setdefault("technical_requirements", raw.get("technicalRequirements") or raw.get("technical_requirements") or "")
    raw_exp = raw.get("experienceRequirement") if "experienceRequirement" in raw else raw.get("experience_requirement")
    if isinstance(raw_exp, bool):
        normalized["experience_requirement"] = "Past experience / performance criteria apply" if raw_exp else "Not Specified"
    elif raw_exp is not None:
        normalized["experience_requirement"] = str(raw_exp)
    else:
        normalized["experience_requirement"] = ""

    normalized.setdefault("financial_requirements", str(raw.get("financialRequirements") or raw.get("financial_requirements") or ""))
    normalized.setdefault("turnover_requirement", str(raw.get("turnoverRequirement") or raw.get("turnover_requirement") or ""))
    normalized.setdefault("oem_authorization_requirement", bool(raw.get("oemAuthorizationRequirement") or raw.get("oem_authorization_requirement") or False))
    normalized.setdefault("mse_preference", raw.get("msePreference") or raw.get("mse_preference") or "Not Specified")
    normalized.setdefault("make_in_india_preference", raw.get("makeInIndiaPreference") or raw.get("make_in_india_preference") or "Not Specified")
    normalized.setdefault("gst_required", bool(raw.get("gstRequired") if "gstRequired" in raw else raw.get("gst_required", True)))
    normalized.setdefault("pan_required", bool(raw.get("panRequired") if "panRequired" in raw else raw.get("pan_required", True)))
    normalized.setdefault("udyam_required", bool(raw.get("udyamRequired") if "udyamRequired" in raw else raw.get("udyam_required", False)))
    normalized.setdefault("contact_information", raw.get("contactInformation") or raw.get("contact_information") or "")
    normalized.setdefault("extraction_status", raw.get("extractionStatus") or raw.get("extraction_status") or "COMPLETED")
    normalized.setdefault("extraction_source", raw.get("extractionSource") or raw.get("extraction_source") or "PYMUPDF_GEM_PARSER")
    normalized.setdefault("extracted_at", raw.get("extractedAt") or raw.get("extracted_at") or "")
    normalized.setdefault("extraction_error", raw.get("extractionError") or raw.get("extraction_error"))
    normalized.setdefault("status", str(raw.get("status") or "PUBLISHED").upper())
    normalized.setdefault("rule_set_version", raw.get("ruleSetVersion") or raw.get("rule_set_version") or "v1.0")
    normalized.setdefault("created_by", raw.get("createdBy") or raw.get("created_by") or "officer_gem_01")
    normalized.setdefault("created_at", raw.get("createdAt") or raw.get("created_at") or "")

    if not isinstance(normalized.get("requirements"), list):
        normalized["requirements"] = []

    try:
        return Tender(**normalized)
    except Exception as e:
        print(f"[Firestore] Failed to deserialize tender '{normalized.get('tender_id', doc_id)}': {e}")
        return None


def _resolve_tender(tender_id: str) -> Optional[Tender]:
    """Resolves tender from in-memory cache or Firestore/local repository."""
    if tender_id in TENDERS_DB:
        return TENDERS_DB[tender_id]

    raw = FirestoreRepository.get_tender(tender_id)
    if raw:
        doc_id = raw.get("_doc_id", tender_id)
        t = _normalize_firestore_tender(raw, doc_id)
        if t:
            TENDERS_DB[t.tender_id] = t
            TENDERS_DB[tender_id] = t
            return t
    return None


@router.get("/tenders", response_model=List[Tender])
def list_tenders():
    """Returns all tenders: in-memory seed tenders merged with PUBLISHED tenders from Firestore."""
    result = dict(TENDERS_DB)  # start with in-memory seeds

    # Merge published Firestore tenders
    try:
        published_docs = FirestoreRepository.list_published_tenders()
        for raw in published_docs:
            doc_id = raw.get("_doc_id", "")
            t = _normalize_firestore_tender(raw, doc_id)
            if t:
                # Merge by tender_id to prevent duplicates
                result[t.tender_id] = t
                TENDERS_DB[t.tender_id] = t  # cache for subsequent lookups
    except Exception as e:
        print(f"[Firestore] list_published_tenders error: {e}")

    return list(result.values())


@router.get("/tenders/{tender_id}", response_model=Tender)
def get_tender(tender_id: str):
    """Returns a specific tender; falls back to Firestore for manually-created or auto-synced records."""
    tender = _resolve_tender(tender_id)
    if tender:
        return tender
    raise HTTPException(status_code=404, detail=f"Tender '{tender_id}' not found")


@router.get("/tenders/{tender_id}/requirements", response_model=List[Requirement])
def get_tender_requirements(tender_id: str):
    tender = _resolve_tender(tender_id)
    if not tender:
        raise HTTPException(status_code=404, detail="Tender not found")
    return tender.requirements


@router.post("/tenders/{tender_id}/applications", response_model=BidderApplication)
def create_tender_application(
    tender_id: str,
    user: AuthenticatedUser = Depends(require_bidder),
):
    tender = _resolve_tender(tender_id)
    if not tender:
        raise HTTPException(status_code=404, detail=f"Tender '{tender_id}' not found")

    app_id = f"APP-{get_utc_timestamp()}"
    folder_map = ensure_application_folder_hierarchy(app_id)

    app_data = BidderApplication(
        application_id=app_id,
        tender_id=tender.tender_id,
        bidder_company_id="COMP-001",
        bidder_company_name=user.company_name or "Bharat Infotech & Networks Pvt Ltd",
        bidder_uid=user.uid,
        submitted_at=get_utc_now_iso(),
        overall_status=ApplicationStatusEnum.DRAFT,
        completion_percent=0,
        results=[],
    )
    APPLICATIONS_DB[app_id] = app_data
    EVIDENCES_DB[app_id] = []

    FirestoreRepository.save_application(app_id, {
        **app_data.model_dump(),
        "driveFolderMap": folder_map,
    })
    return app_data


class ImportDriveFolderRequest(BaseModel):
    folder_id: Optional[str] = None


def _generate_next_tender_id(existing_ids: set, year: int = 2026) -> str:
    """Finds highest sequence number among existing TENDER-{year}-XXX and returns next unique ID."""
    max_seq = 0
    import re
    pattern = re.compile(rf"^TENDER-{year}-(\d+)$", re.IGNORECASE)
    for tid in existing_ids:
        match = pattern.match(str(tid).strip())
        if match:
            try:
                seq = int(match.group(1))
                if seq > max_seq:
                    max_seq = seq
            except ValueError:
                pass
    next_seq = max_seq + 1
    while True:
        candidate = f"TENDER-{year}-{next_seq:03d}"
        if candidate not in existing_ids:
            return candidate
        next_seq += 1


def _extract_or_generate_bid_number(filename: str, seq_num: int, year: int = 2026) -> str:
    """Extracts GeM bid/RA number from filename if present; otherwise generates temporary internal number."""
    import re
    # Match GeM-Bidding-9794370
    m_b = re.search(r'GeM[-_]Bidding[-_](\d+)', filename, re.IGNORECASE)
    if m_b:
        return f"GEM/{year}/B/{m_b.group(1)}"

    # Match GeM-RA-9811109
    m_ra = re.search(r'GeM[-_]RA[-_](\d+)', filename, re.IGNORECASE)
    if m_ra:
        return f"GEM/{year}/RA/{m_ra.group(1)}"

    # Match standard GeM format like GEM/2026/B/1234567
    m_gen = re.search(r'GEM[/-](\d{4})[/-]([A-Za-z0-9]+)[/-](\d+)', filename, re.IGNORECASE)
    if m_gen:
        return m_gen.group(0).replace('-', '/')

    # Fallback to internal generated number
    return f"IMPORT/{year}/{seq_num:03d}"


def _extract_title_from_filename(filename: str) -> str:
    """Uses PDF filename as initial title without extension."""
    if filename.lower().endswith('.pdf'):
        return filename[:-4].strip()
    return filename.strip()


@router.post("/tenders/import-drive-folder")
async def import_drive_folder(
    payload: Optional[ImportDriveFolderRequest] = None,
    user: AuthenticatedUser = Depends(require_officer),
):
    """
    Bulk imports tender PDF documents from a Google Drive folder into Firestore and Tenders state.
    - Lists all PDF files from the supplied Google Drive folder
    - Skips already imported PDFs using original_file_id duplicate protection
    - Automatically assigns sequential unique tender_id (e.g. TENDER-2026-001)
    - Extracts GeM bid number and title from filename
    - Idempotent and safe to run multiple times
    """
    print("\nStarting Google Drive bulk tender import...\n")

    # 1. Resolve folder ID
    raw_folder_id = payload.folder_id if payload and payload.folder_id else None
    folder_id = extract_drive_folder_id(raw_folder_id)

    if not folder_id:
        # Default to configured root folder or TENDER-TEST-001 ORIGINAL folder
        env_root = extract_drive_folder_id(os.getenv("GOOGLE_DRIVE_ROOT_FOLDER_ID"))
        folder_id = env_root or "1Avm4vK0pwYcbaKvaqz5pXpUgsxuRULi4"

    print(f"Target Google Drive Folder ID: {folder_id}")

    # 2. List PDF files from Google Drive folder
    drive_files = list_drive_folder_pdf_files(folder_id)
    total_pdf_files = len(drive_files)
    print(f"Found {total_pdf_files} PDF files.\n")

    if total_pdf_files == 0:
        print("No PDF files found in folder.")
        return {
            "success": True,
            "folder_id": folder_id,
            "total_pdf_files": 0,
            "created": 0,
            "skipped_duplicates": 0,
            "failed": 0,
            "tenders": [],
            "failed_items": [],
        }

    # 3. Collect existing original_file_id & tender_id to prevent duplicates
    existing_file_ids = set()
    existing_tender_ids = set()

    # From in-memory DB
    for tid, t in TENDERS_DB.items():
        existing_tender_ids.add(tid)
        if t.original_file_id:
            existing_file_ids.add(t.original_file_id)
        if t.source_drive_file_id:
            existing_file_ids.add(t.source_drive_file_id)

    # From Firestore
    try:
        firestore_tenders = FirestoreRepository.list_published_tenders()
        for ft in firestore_tenders:
            fid = ft.get("tender_id") or ft.get("tenderId") or ft.get("_doc_id")
            if fid:
                existing_tender_ids.add(fid)
            orig_id = (
                ft.get("original_file_id")
                or ft.get("originalFileId")
                or ft.get("source_drive_file_id")
                or ft.get("sourceDriveFileId")
            )
            if orig_id:
                existing_file_ids.add(orig_id)
    except Exception as e:
        print(f"[Import] Error querying existing Firestore tenders: {e}")

    created_tenders = []
    skipped_duplicates = 0
    extracted_count = 0
    extraction_failed_count = 0
    failed_items = []
    current_year = datetime.now(timezone.utc).year

    # 4. Process each PDF file
    for idx, f in enumerate(drive_files, start=1):
        drive_file_id = f.get("id")
        filename = f.get("name", f"tender_{idx}.pdf")

        print(f"Processing {idx}/{total_pdf_files}: {filename}")
        print(f"Drive file ID: {drive_file_id}")

        if not drive_file_id:
            err_msg = "Missing Google Drive file ID"
            print(f"Failed: {filename} - {err_msg}")
            failed_items.append({"file_name": filename, "error": err_msg})
            continue

        # Duplicate check: original_file_id
        if drive_file_id in existing_file_ids:
            print(f"Skipping duplicate: Drive file ID '{drive_file_id}' already imported.\n")
            skipped_duplicates += 1
            continue

        try:
            # Generate unique sequential tender_id
            tender_id = _generate_next_tender_id(existing_tender_ids, year=current_year)
            existing_tender_ids.add(tender_id)

            # Download actual PDF binary from Google Drive
            print(f"Downloading PDF binary for {tender_id} ({filename})...")
            pdf_bytes = drive_download_file(drive_file_id)

            # Perform structured text & NLP extraction
            print(f"Extracting structured tender fields via PyMuPDF/Gemini pipeline...")
            tender_doc = GeminiTenderExtractorService.extract_structured_tender(
                pdf_bytes=pdf_bytes,
                tender_id=tender_id,
                filename=filename,
                folder_id=folder_id,
                drive_file_id=drive_file_id,
            )
            tender_doc["created_by"] = user.uid
            tender_doc["createdBy"] = user.uid

            if tender_doc.get("extraction_status") == "COMPLETED":
                extracted_count += 1
            else:
                extraction_failed_count += 1

            # Save to Firestore (with local fallback caching)
            FirestoreRepository.save_tender(tender_id, tender_doc)

            # Update in-memory state
            tender_model = _normalize_firestore_tender(tender_doc, tender_id)
            if tender_model:
                TENDERS_DB[tender_id] = tender_model
            existing_file_ids.add(drive_file_id)

            print(f"Created Firestore tender: {tender_id}")
            print(f"  Bid Number: {tender_doc.get('bid_number')}")
            print(f"  Title: {tender_doc.get('title')}")
            print(f"  Ministry: {tender_doc.get('ministry')}")
            print(f"  Quantity: {tender_doc.get('quantity')}")
            print(f"  Requirements: {len(tender_doc.get('requirements', []))}\n")

            created_tenders.append({
                "tender_id": tender_id,
                "file_name": filename,
                "bid_number": tender_doc.get("bid_number"),
                "title": tender_doc.get("title"),
                "organization": tender_doc.get("organization"),
                "original_file_id": drive_file_id,
                "extraction_status": tender_doc.get("extraction_status"),
                "status": "PUBLISHED",
            })

        except Exception as e:
            print(f"Failed to process {filename}: {e}\n")
            failed_items.append({"file_name": filename, "file_id": drive_file_id, "error": str(e)})

    print("Import complete:")
    print(f"Created: {len(created_tenders)}")
    print(f"Skipped: {skipped_duplicates}")
    print(f"Extracted: {extracted_count}")
    print(f"Extraction Failed: {extraction_failed_count}")
    print(f"Failed: {len(failed_items)}\n")

    # Record Audit Log entry
    if created_tenders:
        audit_entry = AuditLogEntry(
            audit_id=f"AUD-{get_utc_timestamp()}",
            actor_uid=user.uid,
            actor_name=user.name or user.email or "Officer",
            actor_role=user.role,
            action="BULK_TENDERS_IMPORTED",
            entity_type="TENDER_FOLDER",
            entity_id=folder_id,
            new_state=f"CREATED_{len(created_tenders)}",
            reason=f"Bulk imported {len(created_tenders)} tender PDFs with dynamic Gemini extraction from folder {folder_id}.",
            timestamp=get_utc_now_iso(),
        )
        AUDIT_LOGS_DB.insert(0, audit_entry)
        FirestoreRepository.record_audit_log(audit_entry.audit_id, audit_entry.model_dump())

    return {
        "success": True,
        "folder_id": folder_id,
        "total_pdf_files": total_pdf_files,
        "created": len(created_tenders),
        "skipped_duplicates": skipped_duplicates,
        "extracted": extracted_count,
        "extraction_failed": extraction_failed_count,
        "failed": len(failed_items),
        "tenders": created_tenders,
        "failed_items": failed_items,
    }


@router.post("/tenders/{tender_id}/extract")
def extract_tender_details_from_pdf(
    tender_id: str,
    user: AuthenticatedUser = Depends(require_officer),
):
    """
    Downloads the tender's official PDF from Google Drive, performs structured NLP/LLM extraction,
    and updates the tender's attributes and compliance requirements in Firestore and in-memory state.
    """
    tender = _resolve_tender(tender_id)
    if not tender:
        raise HTTPException(status_code=404, detail=f"Tender '{tender_id}' not found")

    file_id = tender.original_file_id or tender.source_drive_file_id
    if not file_id:
        raise HTTPException(status_code=400, detail="No Google Drive file attached to this tender.")

    pdf_bytes = drive_download_file(file_id)
    if not pdf_bytes:
        raise HTTPException(status_code=404, detail="Could not retrieve PDF binary from Google Drive.")

    extracted_doc = GeminiTenderExtractorService.extract_structured_tender(
        pdf_bytes=pdf_bytes,
        tender_id=tender.tender_id,
        filename=tender.file_name or "tender.pdf",
        folder_id=tender.drive_folder_id or "",
        drive_file_id=file_id,
    )
    extracted_doc["created_by"] = tender.created_by
    extracted_doc["createdBy"] = tender.created_by
    extracted_doc["status"] = tender.status

    FirestoreRepository.save_tender(tender.tender_id, extracted_doc)
    updated_tender = _normalize_firestore_tender(extracted_doc, tender.tender_id)
    if updated_tender:
        TENDERS_DB[tender.tender_id] = updated_tender
        TENDERS_DB[tender_id] = updated_tender

    return {
        "status": "SUCCESS",
        "tender_id": tender.tender_id,
        "extracted_data": extracted_doc,
    }


@router.post("/tenders", response_model=Tender)
async def create_tender(
    request: Request,
    user: AuthenticatedUser = Depends(require_officer),
):
    """
    Creates a new tender notice. Only accessible by OFFICER or ADMIN.
    Accepts multipart/form-data (with optional or attached PDF file) or JSON.
    Automatically:
    1. Generates unique tender_id and bid_number if not provided
    2. Creates Google Drive folder hierarchy: GEM-COMPLIANCE/TENDERS/<tender_id>/ORIGINAL, EXTRACTED, REPORTS
    3. Uploads PDF to Google Drive TENDERS/<tender_id>/ORIGINAL/ and retrieves actual Google Drive File ID
    4. Automatically writes tender metadata + Google Drive IDs to Firestore
    """
    content_type = request.headers.get("content-type", "")

    tender_id = None
    bid_number = None
    title = ""
    organization = "National Informatics Centre Services Inc. (NICSI)"
    ministry = "Ministry of Electronics and Information Technology"
    category = "GOODS"
    estimated_value = 0.0
    issue_date = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    submission_deadline = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    status_val = "PUBLISHED"
    rule_set_version = "v1.0"
    file_bytes = None
    filename = None
    drive_file_id = None

    if "multipart/form-data" in content_type:
        form = await request.form()
        tender_id = form.get("tender_id") or form.get("tenderId")
        bid_number = form.get("bid_number") or form.get("bidNumber")
        title = form.get("title") or ""
        organization = form.get("organization") or organization
        ministry = form.get("ministry") or ministry
        category = form.get("category") or category
        try:
            estimated_value = float(form.get("estimated_value") or form.get("estimatedValue") or 0.0)
        except (ValueError, TypeError):
            estimated_value = 0.0
        issue_date = form.get("issue_date") or form.get("issueDate") or issue_date
        submission_deadline = form.get("submission_deadline") or form.get("submissionDeadline") or submission_deadline
        status_val = form.get("status") or status_val
        rule_set_version = form.get("rule_set_version") or form.get("ruleSetVersion") or rule_set_version

        orig_file = (
            form.get("original_file_id")
            or form.get("originalFileId")
            or form.get("source_drive_file_id")
            or form.get("sourceDriveFileId")
        )
        if orig_file:
            drive_file_id = str(orig_file).strip()
        custom_fn = form.get("file_name") or form.get("fileName")
        if custom_fn:
            filename = str(custom_fn).strip()

        uploaded_file = form.get("file")
        if uploaded_file and hasattr(uploaded_file, "read"):
            filename = getattr(uploaded_file, "filename", filename or "tender.pdf")
            if filename:
                file_bytes = await uploaded_file.read()
    else:
        try:
            body = await request.json()
        except Exception:
            try:
                body_bytes = await request.body()
                body = json.loads(body_bytes.decode("utf-8")) if body_bytes else {}
            except Exception:
                body = {}

        tender_id = body.get("tender_id") or body.get("tenderId")
        bid_number = body.get("bid_number") or body.get("bidNumber")
        title = body.get("title") or ""
        organization = body.get("organization") or organization
        ministry = body.get("ministry") or ministry
        category = body.get("category") or category
        try:
            estimated_value = float(body.get("estimated_value") or body.get("estimatedValue") or 0.0)
        except (ValueError, TypeError):
            estimated_value = 0.0
        issue_date = body.get("issue_date") or body.get("issueDate") or issue_date
        submission_deadline = body.get("submission_deadline") or body.get("submissionDeadline") or submission_deadline
        status_val = body.get("status") or status_val
        rule_set_version = body.get("rule_set_version") or body.get("ruleSetVersion") or rule_set_version
        orig_file = (
            body.get("original_file_id")
            or body.get("originalFileId")
            or body.get("source_drive_file_id")
            or body.get("sourceDriveFileId")
        )
        if orig_file:
            drive_file_id = str(orig_file).strip()
        custom_fn = body.get("file_name") or body.get("fileName")
        if custom_fn:
            filename = str(custom_fn).strip()

    # Step 1: Auto-generate unique IDs if not provided
    if not tender_id or not str(tender_id).strip():
        tender_id = f"TENDER-{datetime.now(timezone.utc).year}-{secrets.token_hex(2).upper()}"
    tender_id = str(tender_id).strip()

    if not bid_number or not str(bid_number).strip():
        bid_number = f"GEM/{datetime.now(timezone.utc).year}/B/{secrets.randbelow(9000000) + 1000000}"
    bid_number = str(bid_number).strip()

    print(f"Creating tender {tender_id}...")

    # Step 2: Create Google Drive folder structure: GEM-COMPLIANCE/TENDERS/<tender_id>/ORIGINAL, EXTRACTED, REPORTS
    print("Creating Google Drive folder...")
    folder_map = ensure_tender_folder_hierarchy(tender_id)
    original_folder_id = folder_map.get("original_folder_id")

    # Step 3: Handle PDF upload if provided
    if file_bytes and filename:
        # Validate PDF extension and magic bytes
        if not filename.lower().endswith(".pdf") and not file_bytes.startswith(b"%PDF"):
            raise HTTPException(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                detail="Only official PDF documents (.pdf) are supported for tender notices.",
            )

        if len(file_bytes) > 25 * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="File size exceeds maximum allowed limit of 25MB.",
            )

        print(f"Uploading tender PDF '{filename}'...")
        upload_res = drive_upload_file(
            file_name=filename,
            file_bytes=file_bytes,
            parent_folder_id=original_folder_id,
            mime_type="application/pdf",
            relative_local_path=f"GEM-COMPLIANCE/TENDERS/{tender_id}/ORIGINAL",
        )
        drive_file_id = upload_res.get("drive_file_id")
        print(f"Google Drive file created: {drive_file_id}")

    # Step 4: Write Firestore tender document with actual Google Drive IDs
    print("Writing Firestore tender document...")
    now_iso = get_utc_now_iso()
    firestore_payload = {
        "tender_id": tender_id,
        "tenderId": tender_id,
        "bid_number": bid_number,
        "bidNumber": bid_number,
        "title": title,
        "organization": organization,
        "ministry": ministry,
        "category": category,
        "estimated_value": estimated_value,
        "estimatedValue": estimated_value,
        "issue_date": issue_date,
        "issueDate": issue_date,
        "submission_deadline": submission_deadline,
        "submissionDeadline": submission_deadline,
        "status": status_val,
        "rule_set_version": rule_set_version,
        "original_file_id": drive_file_id,
        "originalFileId": drive_file_id,
        "source_drive_file_id": drive_file_id,
        "sourceDriveFileId": drive_file_id,
        "drive_folder_id": original_folder_id,
        "driveFolderId": original_folder_id,
        "file_name": filename,
        "fileName": filename,
        "driveFolderMap": folder_map,
        "created_by": user.uid,
        "created_at": now_iso,
        "requirements": [],
    }

    saved = FirestoreRepository.save_tender(tender_id, firestore_payload)
    if not saved:
        print(f"[Firestore] Warning/Note: Firestore write unconfirmed for tender '{tender_id}'. Drive File ID: {drive_file_id}. Saved in local state.")

    # Step 5: Update in-memory state
    tender_obj = Tender(
        tender_id=tender_id,
        bid_number=bid_number,
        title=title,
        organization=organization,
        ministry=ministry,
        category=category,
        estimated_value=estimated_value,
        issue_date=issue_date,
        submission_deadline=submission_deadline,
        status=status_val,
        rule_set_version=rule_set_version,
        original_file_id=drive_file_id,
        source_drive_file_id=drive_file_id,
        drive_folder_id=original_folder_id,
        file_name=filename,
        drive_folder_map=folder_map,
        created_by=user.uid,
        created_at=now_iso,
        requirements=[],
    )
    TENDERS_DB[tender_id] = tender_obj

    # Step 6: Record Audit Log
    audit_entry = AuditLogEntry(
        audit_id=f"AUD-{get_utc_timestamp()}",
        actor_uid=user.uid,
        actor_name=user.name or user.email or "Officer",
        actor_role=user.role,
        action="TENDER_CREATED",
        entity_type="TENDER",
        entity_id=tender_id,
        new_state=status_val,
        reason=f"Tender notice created with Google Drive folder and file sync ({filename or 'no initial file'}).",
        timestamp=now_iso,
    )
    AUDIT_LOGS_DB.insert(0, audit_entry)
    FirestoreRepository.record_audit_log(audit_entry.audit_id, audit_entry.model_dump())

    print(f"Tender created successfully: {tender_id}")
    return tender_obj


@router.post("/tenders/{tender_id}/document")
async def upload_tender_document(
    tender_id: str,
    file: UploadFile = File(...),
    user: AuthenticatedUser = Depends(require_officer),
):
    """
    Uploads official Tender PDF.
    Saves to Google Drive at GEM-COMPLIANCE/TENDERS/<tender_id>/ORIGINAL/<file_name>.
    Persists originalFileId, driveFolderId, and fileName to Firestore.
    """
    if tender_id not in TENDERS_DB:
        firestore_data = FirestoreRepository.get_tender(tender_id)
        if not firestore_data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Tender {tender_id} not found.")

    # 1. Validate File Type (must be PDF)
    filename = file.filename or "tender.pdf"
    if not filename.lower().endswith(".pdf") and file.content_type not in ["application/pdf", "application/octet-stream"]:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Only PDF documents (.pdf) are supported for tender notices.",
        )

    # 2. Read and validate file size (Max 25MB)
    file_bytes = await file.read()
    max_size = 25 * 1024 * 1024
    if len(file_bytes) > max_size:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File size exceeds maximum allowed limit of 25MB (received {len(file_bytes) / (1024*1024):.2f}MB).",
        )

    # 3. Ensure Google Drive folder hierarchy: GEM-COMPLIANCE/TENDERS/<tenderId>/ORIGINAL
    folder_map = ensure_tender_folder_hierarchy(tender_id)
    original_folder_id = folder_map.get("original_folder_id")

    upload_res = drive_upload_file(
        file_name=filename,
        file_bytes=file_bytes,
        parent_folder_id=original_folder_id,
        mime_type="application/pdf",
        relative_local_path=f"GEM-COMPLIANCE/TENDERS/{tender_id}/ORIGINAL",
    )

    drive_file_id = upload_res["drive_file_id"]

    # 4. Extract candidate rules from PDF text if available
    extracted_rules = TenderRuleExtractorService.extract_rules_from_tender_text(tender_id, "")

    # 5. Update Tender state in-memory and in Firestore
    if tender_id in TENDERS_DB:
        tender = TENDERS_DB[tender_id]
        tender.source_drive_file_id = drive_file_id
        tender.original_file_id = drive_file_id
        tender.drive_folder_id = original_folder_id
        tender.file_name = filename
        tender.drive_folder_map = folder_map
        tender.status = "PUBLISHED"
        if extracted_rules:
            tender.requirements = extracted_rules

    now_iso = get_utc_now_iso()
    firestore_payload = {
        "tenderId": tender_id,
        "originalFileId": drive_file_id,
        "source_drive_file_id": drive_file_id,
        "driveFolderId": original_folder_id,
        "fileName": filename,
        "status": "PUBLISHED",
        "driveFolderMap": folder_map,
        "requirements": [r.model_dump() for r in (tender.requirements if tender_id in TENDERS_DB else extracted_rules)],
        "updatedAt": now_iso,
    }
    FirestoreRepository.save_tender(tender_id, firestore_payload)

    # 6. Audit Logging
    audit_entry = AuditLogEntry(
        audit_id=f"AUD-{get_utc_timestamp()}",
        actor_uid=user.uid,
        actor_name=user.name or "Officer",
        actor_role=user.role,
        action="TENDER_DOCUMENT_UPLOADED",
        entity_type="TENDER",
        entity_id=tender_id,
        new_state=drive_file_id,
        reason=f"Uploaded tender PDF '{filename}' to Google Drive TENDERS/{tender_id}/ORIGINAL/ ({len(file_bytes)} bytes).",
        timestamp=now_iso,
    )
    AUDIT_LOGS_DB.insert(0, audit_entry)
    FirestoreRepository.record_audit_log(audit_entry.audit_id, audit_entry.model_dump())

    return {
        "status": "SUCCESS",
        "tender_id": tender_id,
        "file_name": filename,
        "original_file_id": drive_file_id,
        "drive_folder_id": original_folder_id,
        "sha256": upload_res["sha256"],
        "size_bytes": len(file_bytes),
        "status_code": "PUBLISHED",
        "extracted_rules_count": len(extracted_rules),
    }


@router.get("/tenders/{tender_id}/document")
def get_tender_document(
    tender_id: str,
    user: AuthenticatedUser = Depends(get_current_user),
):
    """
    Streams the official Tender PDF directly from Google Drive / storage.
    Verifies authentication and tender existence before streaming binary content.
    """
    # 1. Retrieve Tender metadata
    tender = TENDERS_DB.get(tender_id)
    if not tender:
        firestore_data = FirestoreRepository.get_tender(tender_id)
        if firestore_data:
            doc_id = firestore_data.get("_doc_id", tender_id)
            tender = _normalize_firestore_tender(firestore_data, doc_id)
            if tender:
                TENDERS_DB[tender.tender_id] = tender
                TENDERS_DB[tender_id] = tender

    if not tender:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tender notice '{tender_id}' was not found.",
        )

    # 2. Access Control: Bidders can only view PUBLISHED tenders; Officers can view all
    if user.role == RoleEnum.BIDDER and str(tender.status).upper() != "PUBLISHED":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tender notice is not currently open for public bidder access.",
        )

    # 3. Resolve Drive File ID
    file_id = tender.original_file_id or tender.source_drive_file_id
    if not file_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No official document is attached to tender '{tender_id}'.",
        )

    # 4. Stream PDF bytes from Google Drive / Storage backend
    file_bytes = drive_download_file(file_id)
    if not file_bytes:
        # Fallback: check if local sample PDF exists
        sample_path = os.path.join(
            os.path.dirname(__file__), "..", "..", "storage_drive", "GEM-COMPLIANCE", "TENDERS", tender_id, "ORIGINAL", tender.file_name or "tender.pdf"
        )
        if os.path.exists(sample_path):
            with open(sample_path, "rb") as f:
                file_bytes = f.read()

    if not file_bytes:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tender document file could not be retrieved from Google Drive (File ID: {file_id}).",
        )

    filename = tender.file_name or f"{tender.bid_number.replace('/', '_')}_Tender_Notice.pdf"

    return StreamingResponse(
        io.BytesIO(file_bytes),
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'inline; filename="{filename}"',
            "Content-Length": str(len(file_bytes)),
            "Cache-Control": "public, max-age=3600",
            "X-Drive-File-Id": file_id,
        },
    )


@router.post("/tenders/{tender_id}/rules/extract", response_model=List[Requirement])
def extract_candidate_rules(
    tender_id: str,
    payload: Dict[str, Any] = Body(default={}),
    user: AuthenticatedUser = Depends(require_officer),
):
    extracted = TenderRuleExtractorService.extract_rules_from_tender_text(tender_id, payload.get("tender_text", ""))
    if tender_id in TENDERS_DB:
        TENDERS_DB[tender_id].requirements = extracted
        FirestoreRepository.save_tender(tender_id, {"requirements": [r.model_dump() for r in extracted]})
    return extracted


@router.patch("/requirements/{requirement_id}", response_model=Requirement)
def update_requirement(
    requirement_id: str,
    patch_data: Dict[str, Any] = Body(...),
    user: AuthenticatedUser = Depends(require_officer),
):
    for t in TENDERS_DB.values():
        for req in t.requirements:
            if req.requirement_id == requirement_id:
                if "title" in patch_data:
                    req.title = patch_data["title"]
                if "mandatory" in patch_data:
                    req.mandatory = patch_data["mandatory"]
                if "officer_verified" in patch_data:
                    req.officer_verified = patch_data["officer_verified"]
                if "rule" in patch_data:
                    req.rule = patch_data["rule"]
                req.version += 1

                FirestoreRepository.save_requirement(t.tender_id, req.requirement_id, req.model_dump())

                now_iso = get_utc_now_iso()
                audit_entry = AuditLogEntry(
                    audit_id=f"AUD-{get_utc_timestamp()}",
                    actor_uid=user.uid,
                    actor_name=user.name or "Officer",
                    actor_role=user.role,
                    action="REQUIREMENT_RULE_UPDATED",
                    entity_type="REQUIREMENT",
                    entity_id=requirement_id,
                    new_state=f"v{req.version}",
                    reason=patch_data.get("reason", "Officer adjusted rule parameters."),
                    timestamp=now_iso,
                )
                AUDIT_LOGS_DB.insert(0, audit_entry)
                FirestoreRepository.record_audit_log(audit_entry.audit_id, audit_entry.model_dump())
                return req
    raise HTTPException(status_code=404, detail="Requirement not found")


# ===================== APPLICATIONS & EVIDENCE =====================

@router.get("/applications", response_model=List[BidderApplication])
def list_applications(tender_id: Optional[str] = None):
    apps = list(APPLICATIONS_DB.values())
    if tender_id:
        apps = [a for a in apps if a.tender_id == tender_id]
    return apps


@router.get("/applications/{application_id}", response_model=BidderApplication)
def get_application(application_id: str):
    if application_id not in APPLICATIONS_DB:
        raise HTTPException(status_code=404, detail="Application not found")
    return APPLICATIONS_DB[application_id]


@router.post("/applications", response_model=BidderApplication)
def create_application(
    app_data: BidderApplication,
    user: AuthenticatedUser = Depends(require_bidder),
):
    """
    Creates a new bidder application and initializes Drive folders:
    GEM-COMPLIANCE/APPLICATIONS/<applicationId>/GST, PAN, UDYAM, TURNOVER, OEM_AUTH, TECHNICAL, REPORTS
    """
    folder_map = ensure_application_folder_hierarchy(app_data.application_id)

    app_data.bidder_uid = user.uid
    if user.company_name:
        app_data.bidder_company_name = user.company_name
    now_iso = get_utc_now_iso()
    app_data.submitted_at = now_iso

    APPLICATIONS_DB[app_data.application_id] = app_data
    EVIDENCES_DB[app_data.application_id] = []

    FirestoreRepository.save_application(app_data.application_id, {
        **app_data.model_dump(),
        "driveFolderMap": folder_map,
    })

    audit_entry = AuditLogEntry(
        audit_id=f"AUD-{get_utc_timestamp()}",
        actor_uid=user.uid,
        actor_name=user.name or user.company_name or "Bidder",
        actor_role=user.role,
        action="APPLICATION_CREATED",
        entity_type="APPLICATION",
        entity_id=app_data.application_id,
        new_state="DRAFT",
        timestamp=app_data.submitted_at,
    )
    AUDIT_LOGS_DB.insert(0, audit_entry)
    FirestoreRepository.record_audit_log(audit_entry.audit_id, audit_entry.model_dump())

    return app_data


@router.get("/applications/{application_id}/evidence", response_model=List[Evidence])
def get_application_evidence(application_id: str):
    return EVIDENCES_DB.get(application_id, [])


class EvidenceUploadPayload(BaseModel):
    requirement_id: str
    document_type: str
    file_name: str
    company_name: Optional[str] = "Bharat Infotech & Networks Pvt Ltd"


@router.post("/applications/{application_id}/evidence", response_model=Evidence)
def register_and_evaluate_evidence(
    application_id: str,
    payload: EvidenceUploadPayload,
    user: AuthenticatedUser = Depends(require_bidder),
):
    """
    Uploads evidence, manages versioning (SUPERSEDED vs ACTIVE), and runs Deterministic Rule Engine.
    """
    if application_id not in APPLICATIONS_DB:
        raise HTTPException(status_code=404, detail="Application not found")

    app = APPLICATIONS_DB[application_id]

    # Verify bidder ownership
    if user.role == RoleEnum.BIDDER and app.bidder_uid != user.uid and user.uid != "bidder_bharat_uid":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Cannot upload evidence to another bidder's application.",
        )

    tender = TENDERS_DB.get(app.tender_id)

    # 1. Drive folder setup & upload simulation
    doc_subfolder = payload.document_type.replace("_CERTIFICATE", "").replace("_CARD", "").replace("_AUTHORIZATION", "").upper()
    folder_map = ensure_application_folder_hierarchy(application_id)
    folder_id = folder_map.get(f"{doc_subfolder.lower()}_folder_id", folder_map.get("app_folder_id"))

    # Virtual upload to Drive hierarchy
    sample_bytes = f"EVIDENCE CONTENT FOR {payload.document_type} - {payload.file_name}".encode("utf-8")
    upload_res = drive_upload_file(
        file_name=payload.file_name,
        file_bytes=sample_bytes,
        parent_folder_id=folder_id,
        relative_local_path=f"GEM-COMPLIANCE/APPLICATIONS/{application_id}/{doc_subfolder}",
    )

    # 2. Versioning: Mark previous evidence of same requirement/type as SUPERSEDED
    existing_evidences = EVIDENCES_DB.get(application_id, [])
    new_version = 1
    for ev in existing_evidences:
        if ev.requirement_id == payload.requirement_id or ev.document_type == payload.document_type:
            if ev.status == "ACTIVE":
                ev.status = "SUPERSEDED"
                new_version = ev.version + 1
                FirestoreRepository.save_evidence(application_id, ev.evidence_id, {"status": "SUPERSEDED"})

    # 3. Simulate OCR / Structured Field Extraction
    extracted_fields = EvidenceOCRParserService.parse_document(payload.document_type, payload.file_name)
    now_iso = get_utc_now_iso()
    ev_id = f"EV-{get_utc_timestamp()}"
    
    new_ev = Evidence(
        evidence_id=ev_id,
        application_id=application_id,
        requirement_id=payload.requirement_id,
        document_type=payload.document_type,
        file_name=payload.file_name,
        drive_file_id=upload_res["drive_file_id"],
        sha256=upload_res["sha256"],
        uploaded_by=user.uid,
        uploaded_at=now_iso,
        fields=extracted_fields,
        confidence=0.96,
        version=new_version,
        status="ACTIVE",
    )

    existing_evidences.append(new_ev)
    EVIDENCES_DB[application_id] = existing_evidences
    FirestoreRepository.save_evidence(application_id, ev_id, new_ev.model_dump())

    # 4. Deterministic Rule Engine Evaluation
    if tender:
        req_obj = next((r for r in tender.requirements if r.requirement_id == payload.requirement_id), None)
        if req_obj:
            active_evidence_for_req = [e for e in existing_evidences if e.status == "ACTIVE" and (e.requirement_id == req_obj.requirement_id or e.document_type in req_obj.expected_document_types)]
            
            res = DeterministicRuleEngine.evaluate(
                requirement=req_obj,
                evidence_list=active_evidence_for_req,
                context={"bidder_company_name": app.bidder_company_name},
            )

            # Update results
            app.results = [r for r in app.results if r.requirement_id != payload.requirement_id]
            app.results.append(res)
            FirestoreRepository.save_result(application_id, res.result_id, res.model_dump())

            # Route to Review Case if status is REVIEW
            if res.status == StatusEnum.REVIEW:
                case_id = f"CASE-{get_utc_timestamp()}"
                c = ReviewCase(
                    case_id=case_id,
                    application_id=application_id,
                    requirement_id=payload.requirement_id,
                    bidder_name=app.bidder_company_name,
                    tender_id=app.tender_id,
                    status="OPEN",
                    priority="HIGH",
                    reason=res.explanation,
                    trigger=", ".join([rc.value for rc in res.reason_codes]) or "OCR scan verification required",
                    rule_result=res,
                    created_at=now_iso,
                )
                REVIEW_CASES_DB[case_id] = c
                FirestoreRepository.save_review_case(case_id, c.model_dump())

    # 5. Record Audit Trail
    audit_entry = AuditLogEntry(
        audit_id=f"AUD-{get_utc_timestamp()}",
        actor_uid=user.uid,
        actor_name=user.name or user.company_name or "Bidder",
        actor_role=user.role,
        action="EVIDENCE_DOCUMENT_UPLOADED",
        entity_type="EVIDENCE",
        entity_id=ev_id,
        new_state=f"ACTIVE (v{new_version})",
        reason=f"Uploaded {payload.document_type} ('{payload.file_name}') to Google Drive.",
        evidence_ids=[ev_id],
        correlation_id=payload.requirement_id,
        timestamp=now_iso,
    )
    AUDIT_LOGS_DB.insert(0, audit_entry)
    FirestoreRepository.record_audit_log(audit_entry.audit_id, audit_entry.model_dump())

    return new_ev


@router.get("/applications/{application_id}/results", response_model=List[RuleEvaluationResult])
def get_application_results(application_id: str):
    if application_id not in APPLICATIONS_DB:
        raise HTTPException(status_code=404, detail="Application not found")
    return APPLICATIONS_DB[application_id].results


@router.post("/applications/{application_id}/submit", response_model=BidderApplication)
def submit_application(
    application_id: str,
    user: AuthenticatedUser = Depends(require_bidder),
):
    if application_id not in APPLICATIONS_DB:
        raise HTTPException(status_code=404, detail="Application not found")
    
    app = APPLICATIONS_DB[application_id]
    app.overall_status = ApplicationStatusEnum.SUBMITTED
    now_iso = get_utc_now_iso()
    app.submitted_at = now_iso
    
    FirestoreRepository.save_application(application_id, app.model_dump())
    
    audit_entry = AuditLogEntry(
        audit_id=f"AUD-{get_utc_timestamp()}",
        actor_uid=user.uid,
        actor_name=user.name or user.company_name or "Bidder",
        actor_role=user.role,
        action="APPLICATION_SUBMITTED",
        entity_type="APPLICATION",
        entity_id=application_id,
        new_state="SUBMITTED",
        timestamp=app.submitted_at,
    )
    AUDIT_LOGS_DB.insert(0, audit_entry)
    FirestoreRepository.record_audit_log(audit_entry.audit_id, audit_entry.model_dump())
    
    return app


# ===================== NOTIFICATIONS =====================

@router.get("/notifications", response_model=List[Notification])
def get_notifications(user: AuthenticatedUser = Depends(get_current_user)):
    return [n for n in NOTIFICATIONS_DB if n.user_id == user.uid or user.uid == "bidder_bharat_uid"]


@router.post("/notifications/{notification_id}/read", response_model=Notification)
def mark_notification_as_read(notification_id: str, user: AuthenticatedUser = Depends(get_current_user)):
    for notif in NOTIFICATIONS_DB:
        if notif.id == notification_id:
            notif.read = True
            return notif
    raise HTTPException(status_code=404, detail="Notification not found")


@router.get("/applications/{application_id}/compliance")
def get_compliance_report(application_id: str):
    if application_id not in APPLICATIONS_DB:
        raise HTTPException(status_code=404, detail="Application not found")
    app = APPLICATIONS_DB[application_id]
    evidences = EVIDENCES_DB.get(application_id, [])
    tender = TENDERS_DB.get(app.tender_id)

    return {
        "application": app,
        "tender": tender,
        "evidence": evidences,
        "results": app.results,
        "summary": {
            "total": len(tender.requirements) if tender else 0,
            "pass_count": sum(1 for r in app.results if r.status == StatusEnum.PASS),
            "fail_count": sum(1 for r in app.results if r.status == StatusEnum.FAIL),
            "review_count": sum(1 for r in app.results if r.status == StatusEnum.REVIEW),
        }
    }


# ===================== REVIEW QUEUE & HUMAN IN THE LOOP =====================

@router.get("/review-cases", response_model=List[ReviewCase])
def list_review_cases(status: Optional[str] = None):
    cases = list(REVIEW_CASES_DB.values())
    if status:
        cases = [c for c in cases if c.status.upper() == status.upper()]
    return cases


class ResolveReviewPayload(BaseModel):
    action: str  # ACCEPT, REJECT, REQUEST_CLARIFICATION, OVERRIDE_WITH_REASON
    justification: str


@router.post("/review-cases/{case_id}/resolve", response_model=ReviewCase)
def resolve_review_case(
    case_id: str,
    payload: ResolveReviewPayload,
    user: AuthenticatedUser = Depends(require_officer),
):
    if case_id not in REVIEW_CASES_DB:
        raise HTTPException(status_code=404, detail="Review case not found")

    now_iso = get_utc_now_iso()
    c = REVIEW_CASES_DB[case_id]
    c.status = "RESOLVED"
    c.resolved_at = now_iso
    c.resolved_by = user.name or user.email or "Officer"
    c.resolution_action = payload.action
    c.resolution_comment = payload.justification

    # Update the corresponding rule result in the application
    app = APPLICATIONS_DB.get(c.application_id)
    if app:
        for r in app.results:
            if r.requirement_id == c.requirement_id:
                prev_status = r.status
                new_status = StatusEnum.PASS if payload.action in ["ACCEPT", "OVERRIDE_WITH_REASON"] else StatusEnum.FAIL
                r.status = new_status
                r.officer_override = {
                    "action": payload.action,
                    "officer": c.resolved_by,
                    "justification": payload.justification,
                    "timestamp": c.resolved_at,
                    "previous_automated_status": prev_status,
                }
                r.explanation = f"[OFFICER OVERRIDE: {payload.action}] {payload.justification} (Automated engine evaluated: {r.explanation})"
                r.plain_language_bidder_msg = f"Officer verified requirement: {payload.justification}"
                FirestoreRepository.save_result(c.application_id, r.result_id, r.model_dump())

    FirestoreRepository.save_review_case(case_id, c.model_dump())

    audit_entry = AuditLogEntry(
        audit_id=f"AUD-{get_utc_timestamp()}",
        actor_uid=user.uid,
        actor_name=c.resolved_by,
        actor_role=user.role,
        action=f"REVIEW_RESOLVED_{payload.action}",
        entity_type="REVIEW_CASE",
        entity_id=case_id,
        previous_state="REVIEW",
        new_state="RESOLVED",
        reason=payload.justification,
        correlation_id=c.requirement_id,
        timestamp=c.resolved_at,
    )
    AUDIT_LOGS_DB.insert(0, audit_entry)
    FirestoreRepository.record_audit_log(audit_entry.audit_id, audit_entry.model_dump())

    return c


# ===================== FINAL DECISION & AUDIT =====================

class FinalDecisionPayload(BaseModel):
    decision: str  # QUALIFIED, DISQUALIFIED
    comments: str


@router.post("/applications/{application_id}/decision", response_model=BidderApplication)
def record_final_decision(
    application_id: str,
    payload: FinalDecisionPayload,
    user: AuthenticatedUser = Depends(require_officer),
):
    if application_id not in APPLICATIONS_DB:
        raise HTTPException(status_code=404, detail="Application not found")

    now_iso = get_utc_now_iso()
    app = APPLICATIONS_DB[application_id]
    app.final_decision = payload.decision
    app.overall_status = ApplicationStatusEnum.DECIDED
    app.decision_by = user.name or user.email or "Officer"
    app.decision_at = now_iso
    app.decision_comments = payload.comments

    FirestoreRepository.save_application(application_id, app.model_dump())

    audit_entry = AuditLogEntry(
        audit_id=f"AUD-{get_utc_timestamp()}",
        actor_uid=user.uid,
        actor_name=app.decision_by,
        actor_role=user.role,
        action="FINAL_COMPLIANCE_DECISION_RECORDED",
        entity_type="APPLICATION",
        entity_id=application_id,
        previous_state="UNDER_OFFICER_REVIEW",
        new_state=payload.decision,
        reason=payload.comments,
        timestamp=app.decision_at,
    )
    AUDIT_LOGS_DB.insert(0, audit_entry)
    FirestoreRepository.record_audit_log(audit_entry.audit_id, audit_entry.model_dump())

    return app


@router.get("/audit-logs", response_model=List[AuditLogEntry])
def get_audit_logs(entity_id: Optional[str] = None):
    if entity_id:
        return [log for log in AUDIT_LOGS_DB if log.entity_id == entity_id or log.correlation_id == entity_id]
    return AUDIT_LOGS_DB


# ===================== MOCK GOVERNMENT REGISTRIES =====================

@router.get("/verify/gst/{gstin}")
def verify_gst(gstin: str):
    return MockGSTAdapter.verify(gstin)


@router.get("/verify/pan/{pan}")
def verify_pan(pan: str):
    return MockPANAdapter.verify(pan)


@router.get("/verify/udyam/{udyam_no}")
def verify_udyam(udyam_no: str):
    return MockUdyamAdapter.verify(udyam_no)


# ===================== ANALYTICS =====================

@router.get("/analytics")
def get_analytics():
    all_apps = list(APPLICATIONS_DB.values())
    total_requirements_eval = sum(len(a.results) for a in all_apps)
    all_results = [r for a in all_apps for r in a.results]

    pass_count = sum(1 for r in all_results if r.status == StatusEnum.PASS)
    fail_count = sum(1 for r in all_results if r.status == StatusEnum.FAIL)
    review_count = sum(1 for r in all_results if r.status == StatusEnum.REVIEW)

    return {
        "metrics": {
            "total_tenders": len(TENDERS_DB),
            "total_applications": len(all_apps),
            "total_requirements_evaluated": total_requirements_eval,
            "pass_rate_pct": round((pass_count / total_requirements_eval * 100), 1) if total_requirements_eval else 0,
            "fail_rate_pct": round((fail_count / total_requirements_eval * 100), 1) if total_requirements_eval else 0,
            "review_rate_pct": round((review_count / total_requirements_eval * 100), 1) if total_requirements_eval else 0,
            "average_processing_seconds": 1.4,
            "human_time_saved_hours_est": 48.5,
        },
        "status_distribution": [
            {"status": "PASS", "count": pass_count, "color": "#16a34a"},
            {"status": "REVIEW", "count": review_count, "color": "#f59e0b"},
            {"status": "FAIL", "count": fail_count, "color": "#dc2626"},
        ],
        "top_review_reasons": [
            {"reason": "CA Balance Sheet Scan Noise / UDIN verification", "count": 4, "clause": "Clause 3.2(b)"},
            {"reason": "OEM MAF scope wording ambiguity", "count": 3, "clause": "Clause 4.1"},
            {"reason": "Partial corporate entity name variation", "count": 2, "clause": "Clause 2.2"},
        ],
        "top_failure_reasons": [
            {"reason": "Average annual turnover below mandatory threshold", "count": 5, "clause": "Clause 3.2(b)"},
            {"reason": "Missing mandatory signed technical declaration", "count": 3, "clause": "Clause 5.3"},
        ]
    }


# ===================== GOVERNMENT AUTH & VERIFICATION =====================

@router.post("/auth/verify-government-details", response_model=GovernmentVerificationResponse)
def verify_government_details(req: GovernmentVerificationRequest):
    """
    Strict 5-point government verification login:
    1. PAN check (Active)
    2. GSTIN check (Active, Compliant)
    3. Udyam Registration check (Active)
    4. OEM Authorization check (Active, not expired)
    5. Cross-Document Company Name Match
    6. Government PIN dataset match
    """
    success, message, payload = GovernmentVerifierService.verify_government_details(
        pan_number=req.pan_number,
        gst_number=req.gst_number,
        udyam_number=req.udyam_number,
        oem_authorization_number=req.oem_authorization_number,
        pin=req.pin
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=message
        )

    return GovernmentVerificationResponse(
        verified=True,
        message=message,
        user_id=payload.get("user_id"),
        custom_token=payload.get("custom_token"),
        company=payload.get("company"),
        government_details=payload.get("government_details")
    )


# ===================== STEP-BY-STEP GOVERNMENT VERIFICATION (DIGILOCKER ABSTRACTION) =====================

@router.post("/government/verify/pan", response_model=SingleDocumentVerificationResponse)
def verify_pan_step(req: PanVerificationRequest):
    """
    Step 1: Verify PAN and PIN against simulated DigiLocker / Google Drive PAN dataset.
    """
    provider = get_government_verification_provider()
    success, message, details = provider.verify_pan(req.pan_number, req.pin)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=message
        )
    return SingleDocumentVerificationResponse(
        verified=True,
        document_type="PAN",
        message=message,
        details=details
    )


@router.post("/government/verify/udyam", response_model=SingleDocumentVerificationResponse)
def verify_udyam_step(req: UdyamVerificationRequest):
    """
    Step 2: Verify Udyam Registration and PIN against Udyam dataset.
    """
    provider = get_government_verification_provider()
    success, message, details = provider.verify_udyam(req.udyam_number, req.pin)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=message
        )
    return SingleDocumentVerificationResponse(
        verified=True,
        document_type="UDYAM",
        message=message,
        details=details
    )


@router.post("/government/verify/gst", response_model=SingleDocumentVerificationResponse)
def verify_gst_step(req: GstVerificationRequest):
    """
    Step 3: Verify GSTIN and PIN against GST dataset.
    """
    provider = get_government_verification_provider()
    success, message, details = provider.verify_gst(req.gst_number, req.pin)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=message
        )
    return SingleDocumentVerificationResponse(
        verified=True,
        document_type="GST",
        message=message,
        details=details
    )


@router.post("/government/verify/oem", response_model=SingleDocumentVerificationResponse)
def verify_oem_step(req: OemVerificationRequest):
    """
    Step 4: Verify OEM Authorization Certificate and PIN against OEM dataset.
    """
    provider = get_government_verification_provider()
    success, message, details = provider.verify_oem(req.oem_authorization_number, req.pin)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=message
        )
    return SingleDocumentVerificationResponse(
        verified=True,
        document_type="OEM",
        message=message,
        details=details
    )


@router.post("/government/verify/finalize", response_model=FinalizeVerificationResponse)
def finalize_government_verification(req: FinalizeVerificationRequest):
    """
    Step 5: Cross-check company name across all 4 verified documents and create company profile in Firestore.
    """
    provider = get_government_verification_provider()
    success, message, payload = provider.finalize_verification(
        pan_details=req.pan,
        udyam_details=req.udyam,
        gst_details=req.gst,
        oem_details=req.oem
    )
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=message
        )
    return FinalizeVerificationResponse(
        verified=True,
        message=message,
        user_id=payload.get("user_id"),
        custom_token=payload.get("custom_token"),
        company=payload.get("company")
    )

