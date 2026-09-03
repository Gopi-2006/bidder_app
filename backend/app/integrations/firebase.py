import os
from typing import Optional, Dict, Any

try:
    import firebase_admin
    from firebase_admin import credentials, auth, firestore
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False


class FirebaseAdapter:
    SERVICE_ACCOUNT_FILE = os.getenv("FIREBASE_CREDENTIALS", "firebase_service_account.json")

    def __init__(self):
        self.app = None
        self.db = None
        self._init_firebase()

    def _init_firebase(self):
        if not FIREBASE_AVAILABLE:
            print("[Firebase] firebase_admin SDK not installed or available.")
            return

        if os.path.exists(self.SERVICE_ACCOUNT_FILE):
            try:
                cred = credentials.Certificate(self.SERVICE_ACCOUNT_FILE)
                self.app = firebase_admin.initialize_app(cred)
                self.db = firestore.client()
                print(f"[Firebase] Initialized Firebase Admin SDK with {self.SERVICE_ACCOUNT_FILE}")
            except Exception as e:
                print(f"[Firebase] Warning: Could not initialize Firebase Admin: {e}")
        else:
            print(f"[Firebase] Service account file '{self.SERVICE_ACCOUNT_FILE}' not found. Ready to connect when file is provided.")

    def verify_token(self, id_token: str) -> Optional[Dict[str, Any]]:
        """Verifies a Firebase ID token from Flutter/React client."""
        if not self.app or not FIREBASE_AVAILABLE:
            # Fallback for dev mode
            return {"uid": "officer_rajesh_nicsi", "email": "officer@gem.gov.in", "role": "OFFICER"}
        try:
            decoded_token = auth.verify_id_token(id_token)
            return decoded_token
        except Exception as e:
            print(f"[Firebase] Token verification error: {e}")
            return None


firebase_adapter = FirebaseAdapter()
