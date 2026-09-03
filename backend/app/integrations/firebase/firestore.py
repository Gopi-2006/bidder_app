import os
import json
from typing import Optional, Dict, Any, List
from datetime import datetime
from app.integrations.firebase.admin import get_firestore_client

LOCAL_CACHE_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..", "storage_drive", "local_firestore")
)
os.makedirs(LOCAL_CACHE_DIR, exist_ok=True)
TENDERS_CACHE_FILE = os.path.join(LOCAL_CACHE_DIR, "tenders.json")
APPLICATIONS_CACHE_FILE = os.path.join(LOCAL_CACHE_DIR, "applications.json")


def _read_local_tenders() -> Dict[str, Dict[str, Any]]:
    if os.path.exists(TENDERS_CACHE_FILE):
        try:
            with open(TENDERS_CACHE_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {}


def _write_local_tender(tender_id: str, data: Dict[str, Any]):
    try:
        current = _read_local_tenders()
        if tender_id in current:
            current[tender_id].update(data)
        else:
            current[tender_id] = data
        with open(TENDERS_CACHE_FILE, "w", encoding="utf-8") as f:
            json.dump(current, f, indent=2, default=str)
    except Exception as e:
        print(f"[LocalFirestore] Error saving local tender {tender_id}: {e}")


def _read_local_applications() -> Dict[str, Dict[str, Any]]:
    if os.path.exists(APPLICATIONS_CACHE_FILE):
        try:
            with open(APPLICATIONS_CACHE_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {}


def _write_local_application(app_id: str, data: Dict[str, Any]):
    try:
        current = _read_local_applications()
        if app_id in current:
            current[app_id].update(data)
        else:
            current[app_id] = data
        with open(APPLICATIONS_CACHE_FILE, "w", encoding="utf-8") as f:
            json.dump(current, f, indent=2, default=str)
    except Exception as e:
        print(f"[LocalFirestore] Error saving local application {app_id}: {e}")


class FirestoreRepository:
    """
    Manages structured state and metadata in Google Cloud Firestore.
    Falls back to stateful local persistence if Firestore is not directly reachable.
    """

    @classmethod
    def save_tender(cls, tender_id: str, data: Dict[str, Any]) -> bool:
        # Always persist to local cache for resilience
        _write_local_tender(tender_id, data)
        db = get_firestore_client()
        if db:
            try:
                db.collection("tenders").document(tender_id).set(data, merge=True)
                return True
            except Exception as e:
                print(f"[Firestore] Note: Cloud Firestore write unconfirmed ({e}). Cached locally.")
        return True

    @classmethod
    def get_tender(cls, tender_id: str) -> Optional[Dict[str, Any]]:
        db = get_firestore_client()
        if db:
            try:
                # 1. Direct document ID lookup
                doc = db.collection("tenders").document(tender_id).get()
                if doc.exists:
                    d = doc.to_dict() or {}
                    d["_doc_id"] = doc.id
                    return d

                # 2. Query/search across collection by tender_id, tenderId, bid_number, bidNumber
                docs = db.collection("tenders").stream()
                for doc_item in docs:
                    d = doc_item.to_dict() or {}
                    d["_doc_id"] = doc_item.id
                    if (
                        doc_item.id == tender_id
                        or d.get("tender_id") == tender_id
                        or d.get("tenderId") == tender_id
                        or d.get("bid_number") == tender_id
                        or d.get("bidNumber") == tender_id
                    ):
                        return d
            except Exception as e:
                print(f"[Firestore] Error reading tender {tender_id} from cloud: {e}")

        # Local fallback
        local_data = _read_local_tenders()
        if tender_id in local_data:
            d = dict(local_data[tender_id])
            d["_doc_id"] = tender_id
            return d
        for k, d in local_data.items():
            if (
                k == tender_id
                or d.get("tender_id") == tender_id
                or d.get("tenderId") == tender_id
                or d.get("bid_number") == tender_id
                or d.get("bidNumber") == tender_id
            ):
                d = dict(d)
                d["_doc_id"] = k
                return d
        return None

    @classmethod
    def list_published_tenders(cls) -> List[Dict[str, Any]]:
        cloud_tenders: Dict[str, Dict[str, Any]] = {}
        db = get_firestore_client()
        if db:
            try:
                docs = db.collection("tenders").stream()
                for doc in docs:
                    d = doc.to_dict() or {}
                    d["_doc_id"] = doc.id
                    status_val = str(d.get("status", "PUBLISHED")).upper()
                    if status_val == "PUBLISHED":
                        tid = d.get("tender_id") or d.get("tenderId") or doc.id
                        cloud_tenders[tid] = d
            except Exception as e:
                print(f"[Firestore] Cloud Firestore stream error: {e}")

        # Merge local tenders
        local_tenders = _read_local_tenders()
        merged = dict(cloud_tenders)
        for tid, d in local_tenders.items():
            status_val = str(d.get("status", "PUBLISHED")).upper()
            if status_val == "PUBLISHED":
                canonical_id = d.get("tender_id") or d.get("tenderId") or tid
                if canonical_id not in merged:
                    entry = dict(d)
                    entry["_doc_id"] = canonical_id
                    merged[canonical_id] = entry

        return list(merged.values())

    @classmethod
    def save_requirement(cls, tender_id: str, req_id: str, data: Dict[str, Any]) -> bool:
        db = get_firestore_client()
        if db:
            try:
                db.collection("tenders").document(tender_id).collection("requirements").document(req_id).set(data, merge=True)
                return True
            except Exception as e:
                print(f"[Firestore] Error saving requirement {req_id}: {e}")
        return False

    @classmethod
    def save_application(cls, app_id: str, data: Dict[str, Any]) -> bool:
        _write_local_application(app_id, data)
        db = get_firestore_client()
        if db:
            try:
                db.collection("applications").document(app_id).set(data, merge=True)
                return True
            except Exception as e:
                pass
        return True

    @classmethod
    def get_application(cls, app_id: str) -> Optional[Dict[str, Any]]:
        db = get_firestore_client()
        if db:
            try:
                doc = db.collection("applications").document(app_id).get()
                if doc.exists:
                    d = doc.to_dict() or {}
                    d["_doc_id"] = doc.id
                    return d
            except Exception:
                pass
        local_apps = _read_local_applications()
        if app_id in local_apps:
            d = dict(local_apps[app_id])
            d["_doc_id"] = app_id
            return d
        return None

    @classmethod
    def list_applications(cls, tender_id: Optional[str] = None) -> List[Dict[str, Any]]:
        cloud_apps: Dict[str, Dict[str, Any]] = {}
        db = get_firestore_client()
        if db:
            try:
                query = db.collection("applications")
                if tender_id:
                    query = query.where("tender_id", "==", tender_id)
                for doc in query.stream():
                    d = doc.to_dict() or {}
                    d["_doc_id"] = doc.id
                    aid = d.get("application_id") or d.get("applicationId") or doc.id
                    cloud_apps[aid] = d
            except Exception:
                pass

        local_apps = _read_local_applications()
        merged = dict(cloud_apps)
        for aid, d in local_apps.items():
            t_id = d.get("tender_id") or d.get("tenderId")
            if not tender_id or t_id == tender_id:
                canonical_id = d.get("application_id") or d.get("applicationId") or aid
                if canonical_id not in merged:
                    entry = dict(d)
                    entry["_doc_id"] = canonical_id
                    merged[canonical_id] = entry

        return list(merged.values())

    @classmethod
    def save_evidence(cls, app_id: str, evidence_id: str, data: Dict[str, Any]) -> bool:
        db = get_firestore_client()
        if db:
            try:
                db.collection("applications").document(app_id).collection("evidence").document(evidence_id).set(data, merge=True)
                return True
            except Exception as e:
                print(f"[Firestore] Error saving evidence {evidence_id}: {e}")
        return False

    @classmethod
    def save_result(cls, app_id: str, result_id: str, data: Dict[str, Any]) -> bool:
        db = get_firestore_client()
        if db:
            try:
                db.collection("applications").document(app_id).collection("results").document(result_id).set(data, merge=True)
                return True
            except Exception as e:
                print(f"[Firestore] Error saving result {result_id}: {e}")
        return False

    @classmethod
    def save_review_case(cls, case_id: str, data: Dict[str, Any]) -> bool:
        db = get_firestore_client()
        if db:
            try:
                db.collection("review_cases").document(case_id).set(data, merge=True)
                return True
            except Exception as e:
                print(f"[Firestore] Error saving review case {case_id}: {e}")
        return False

    @classmethod
    def record_audit_log(cls, audit_id: str, data: Dict[str, Any]) -> bool:
        return cls.set_document("audit_logs", audit_id, data)

    @classmethod
    def set_document(cls, collection_name: str, doc_id: str, data: Dict[str, Any]) -> bool:
        db = get_firestore_client()
        if db:
            try:
                db.collection(collection_name).document(doc_id).set(data, merge=True)
                return True
            except Exception as e:
                pass
        return True

    @classmethod
    def get_document(cls, collection_name: str, doc_id: str) -> Optional[Dict[str, Any]]:
        db = get_firestore_client()
        if db:
            try:
                doc = db.collection(collection_name).document(doc_id).get()
                if doc.exists:
                    return doc.to_dict()
            except Exception as e:
                pass
        return None
