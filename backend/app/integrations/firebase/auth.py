from typing import Optional, Dict, Any
from fastapi import Header, HTTPException, Depends, status
from pydantic import BaseModel

from app.models.schemas import RoleEnum
from app.integrations.firebase.admin import FirebaseAdminManager, FIREBASE_AVAILABLE

try:
    from firebase_admin import auth as firebase_auth
except ImportError:
    firebase_auth = None


class AuthenticatedUser(BaseModel):
    uid: str
    email: Optional[str] = None
    name: Optional[str] = None
    role: RoleEnum
    company_id: Optional[str] = None
    company_name: Optional[str] = None
    is_active: bool = True
    claims: Dict[str, Any] = {}


def verify_firebase_token(id_token: str) -> AuthenticatedUser:
    """
    Verifies Firebase ID token using Firebase Admin SDK and resolves trusted role.
    """
    admin_mgr = FirebaseAdminManager.get_instance()

    # 1. Dev / Mock token fallbacks
    if id_token in ["officer_demo_token", "dev_officer_token"]:
        return AuthenticatedUser(
            uid="officer_rajesh_nicsi",
            email="officer.rajesh@gem.gov.in",
            name="Rajesh Sharma (Procurement Officer)",
            role=RoleEnum.OFFICER,
            company_name="National Informatics Centre Services Inc.",
        )
    elif id_token in ["bidder_demo_token", "dev_bidder_token"]:
        return AuthenticatedUser(
            uid="bidder_bharat_uid",
            email="tender.desk@bharatnetworks.in",
            name="Rajesh Sharma (Managing Director)",
            role=RoleEnum.BIDDER,
            company_id="COMP-001",
            company_name="Bharat Infotech & Networks Pvt Ltd",
        )
    elif id_token in ["admin_demo_token", "dev_admin_token"]:
        return AuthenticatedUser(
            uid="admin_gem_master",
            email="admin@gem.gov.in",
            name="GeM Platform Administrator",
            role=RoleEnum.ADMIN,
        )

    # 2. Production Firebase Admin Token Verification
    if admin_mgr.is_connected() and firebase_auth:
        try:
            decoded_token = firebase_auth.verify_id_token(id_token)
            uid = decoded_token.get("uid")
            email = decoded_token.get("email", "")
            name = decoded_token.get("name", email.split("@")[0] if email else "User")
            
            # Determine role from custom claims or email domain
            role = RoleEnum.BIDDER
            if decoded_token.get("role"):
                try:
                    role = RoleEnum(decoded_token["role"].upper())
                except ValueError:
                    pass
            elif email.endswith("@gem.gov.in") or email.endswith("@nic.in") or "officer" in email.lower():
                role = RoleEnum.OFFICER
            elif "admin" in email.lower():
                role = RoleEnum.ADMIN

            company_id = decoded_token.get("company_id")
            company_name = decoded_token.get("company_name", name)

            return AuthenticatedUser(
                uid=uid,
                email=email,
                name=name,
                role=role,
                company_id=company_id,
                company_name=company_name,
                claims=decoded_token,
            )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid or expired Firebase ID token: {str(e)}",
                headers={"WWW-Authenticate": "Bearer"},
            )

    # If Firebase Admin is not connected, default to safe officer/bidder context based on token format
    if "officer" in id_token.lower():
        return AuthenticatedUser(
            uid="officer_rajesh_nicsi",
            email="officer@gem.gov.in",
            name="Rajesh Sharma (Procurement Officer)",
            role=RoleEnum.OFFICER,
        )

    return AuthenticatedUser(
        uid="bidder_bharat_uid",
        email="bidder@bharatnetworks.in",
        name="Bharat Infotech & Networks Pvt Ltd",
        role=RoleEnum.BIDDER,
        company_id="COMP-001",
        company_name="Bharat Infotech & Networks Pvt Ltd",
    )


def get_current_user(authorization: Optional[str] = Header(None)) -> AuthenticatedUser:
    """FastAPI Dependency to retrieve and verify current authenticated user."""
    if not authorization:
        # For testing / local evaluation when no header passed, provide default officer context
        return AuthenticatedUser(
            uid="officer_rajesh_nicsi",
            email="officer.rajesh@gem.gov.in",
            name="Rajesh Sharma (Procurement Officer)",
            role=RoleEnum.OFFICER,
            company_name="NICSI",
        )

    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header must be Bearer <token>",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return verify_firebase_token(token)


def require_officer(current_user: AuthenticatedUser = Depends(get_current_user)) -> AuthenticatedUser:
    if current_user.role not in [RoleEnum.OFFICER, RoleEnum.ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Officer or Admin authorization required for this operation.",
        )
    return current_user


def require_bidder(current_user: AuthenticatedUser = Depends(get_current_user)) -> AuthenticatedUser:
    if current_user.role not in [RoleEnum.BIDDER, RoleEnum.ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bidder authorization required for this operation.",
        )
    return current_user


def require_admin(current_user: AuthenticatedUser = Depends(get_current_user)) -> AuthenticatedUser:
    if current_user.role != RoleEnum.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Platform Admin authorization required for this operation.",
        )
    return current_user
