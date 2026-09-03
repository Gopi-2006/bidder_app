from datetime import datetime
from typing import Dict, Any, Optional
from pydantic import BaseModel


class VerificationResponse(BaseModel):
    source: str
    identifier: str
    status: str
    legal_name: str
    details: Dict[str, Any]
    verified_at: str
    is_mock: bool = True


class MockGSTAdapter:
    REGISTRY = {
        "29ABCDE1234F1Z5": {
            "status": "ACTIVE",
            "legal_name": "Bharat Infotech & Networks Pvt Ltd",
            "trade_name": "Bharat Networks",
            "registration_date": "2018-04-12",
            "constitution": "Private Limited Company",
            "state": "Karnataka",
        },
        "27AABCT3518Q1ZV": {
            "status": "ACTIVE",
            "legal_name": "Apex Enterprise Telecom Solutions LLP",
            "trade_name": "Apex Telecom",
            "registration_date": "2020-09-15",
            "constitution": "Limited Liability Partnership",
            "state": "Maharashtra",
        },
        "07AAAAA0000A1Z5": {
            "status": "CANCELLED",
            "legal_name": "Defunct Enterprises Ltd",
            "trade_name": "Defunct Systems",
            "registration_date": "2016-01-10",
            "constitution": "Public Limited",
            "state": "Delhi",
        }
    }

    @classmethod
    def verify(cls, gstin: str) -> VerificationResponse:
        gstin_clean = gstin.strip().upper()
        info = cls.REGISTRY.get(gstin_clean, {
            "status": "ACTIVE",
            "legal_name": "Verified Vendor Pvt Ltd",
            "trade_name": "Verified Vendor",
            "registration_date": "2019-06-01",
            "constitution": "Private Limited Company",
            "state": "Delhi",
        })
        return VerificationResponse(
            source="MOCK_GST_PORTAL",
            identifier=gstin_clean,
            status=info["status"],
            legal_name=info["legal_name"],
            details=info,
            verified_at=datetime.utcnow().isoformat() + "Z",
            is_mock=True,
        )


class MockPANAdapter:
    REGISTRY = {
        "ABCDE1234F": {
            "status": "ACTIVE",
            "legal_name": "Bharat Infotech & Networks Pvt Ltd",
            "category": "Company",
        },
        "AABCT3518Q": {
            "status": "ACTIVE",
            "legal_name": "Apex Enterprise Telecom Solutions LLP",
            "category": "LLP",
        }
    }

    @classmethod
    def verify(cls, pan: str) -> VerificationResponse:
        pan_clean = pan.strip().upper()
        info = cls.REGISTRY.get(pan_clean, {
            "status": "ACTIVE",
            "legal_name": "Verified Vendor Pvt Ltd",
            "category": "Company",
        })
        return VerificationResponse(
            source="MOCK_INCOME_TAX_NSDL",
            identifier=pan_clean,
            status=info["status"],
            legal_name=info["legal_name"],
            details=info,
            verified_at=datetime.utcnow().isoformat() + "Z",
            is_mock=True,
        )


class MockUdyamAdapter:
    REGISTRY = {
        "UDYAM-KR-03-0019284": {
            "status": "ACTIVE",
            "legal_name": "Bharat Infotech & Networks Pvt Ltd",
            "enterprise_type": "Medium",
            "major_activity": "Services & Manufacturing",
        }
    }

    @classmethod
    def verify(cls, udyam_no: str) -> VerificationResponse:
        udyam_clean = udyam_no.strip().upper()
        info = cls.REGISTRY.get(udyam_clean, {
            "status": "ACTIVE",
            "legal_name": "Bharat Infotech & Networks Pvt Ltd",
            "enterprise_type": "Medium",
            "major_activity": "IT & Telecom Services",
        })
        return VerificationResponse(
            source="MOCK_UDYAM_MSME_PORTAL",
            identifier=udyam_clean,
            status=info["status"],
            legal_name=info["legal_name"],
            details=info,
            verified_at=datetime.utcnow().isoformat() + "Z",
            is_mock=True,
        )
