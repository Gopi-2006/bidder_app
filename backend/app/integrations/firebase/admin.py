import os
import json
import base64
import tempfile
from typing import Optional
from dotenv import load_dotenv

load_dotenv()

try:
    import firebase_admin
    from firebase_admin import credentials, auth, firestore
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False


_CACHED_CREDENTIALS_PATH: Optional[str] = None


def _resolve_credentials() -> Optional[str]:
    """
    Resolves Google/Firebase service account credentials.

    Priority order:
    1. GOOGLE_SERVICE_ACCOUNT_JSON_BASE64 or GOOGLE_APPLICATION_CREDENTIALS_JSON env var
       — base64-encoded (or raw) service account JSON string.
       Allows Render / Cloud Run injection without a file committed to disk.
    2. FIREBASE_CREDENTIALS_PATH env var — explicit file path.
    3. GOOGLE_APPLICATION_CREDENTIALS env var — explicit file path.
    4. Known candidate file paths relative to backend root.
    5. Returns None → caller falls back to Application Default Credentials (ADC).
    """
    global _CACHED_CREDENTIALS_PATH
    if _CACHED_CREDENTIALS_PATH and os.path.exists(_CACHED_CREDENTIALS_PATH):
        return _CACHED_CREDENTIALS_PATH

    # Option 1: base64-encoded or raw JSON in env var (Render / Cloud Run friendly)
    raw_b64 = (
        os.getenv("GOOGLE_SERVICE_ACCOUNT_JSON_BASE64")
        or os.getenv("GOOGLE_APPLICATION_CREDENTIALS_JSON")
        or ""
    ).strip()

    if raw_b64:
        try:
            if raw_b64.startswith("{"):
                json_bytes = raw_b64.encode("utf-8")
            else:
                json_bytes = base64.b64decode(raw_b64)

            parsed = json.loads(json_bytes.decode("utf-8"))
            if not isinstance(parsed, dict) or "type" not in parsed:
                raise ValueError("Service account JSON missing 'type' field.")

            tmp = tempfile.NamedTemporaryFile(
                mode="wb", suffix=".json", delete=False, prefix="sa_render_"
            )
            tmp.write(json_bytes)
            tmp.flush()
            tmp.close()

            os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = tmp.name
            _CACHED_CREDENTIALS_PATH = tmp.name
            print("[Credentials] Successfully loaded service account from environment variable.")
            return tmp.name
        except Exception as e:
            print(f"[Credentials] Warning: Could not decode service account env var: {e}")

    # Option 2: explicit path env var
    env_path = os.getenv("FIREBASE_CREDENTIALS_PATH") or os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if env_path:
        backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
        full_path = os.path.join(backend_dir, env_path) if not os.path.isabs(env_path) else env_path
        if os.path.exists(full_path):
            _CACHED_CREDENTIALS_PATH = full_path
            return full_path

    # Option 3: well-known candidate paths
    backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
    candidates = [
        os.path.join(backend_dir, "credentials", "bidder-fdede-b13f4f369c8a.json"),
        os.path.join(backend_dir, "credentials", "firebase_service_account.json"),
        os.path.join(backend_dir, "credentials", "google-drive-service-account.json"),
        os.path.join(backend_dir, "service_account.json"),
    ]
    for cand in candidates:
        if os.path.exists(cand):
            _CACHED_CREDENTIALS_PATH = os.path.abspath(cand)
            return _CACHED_CREDENTIALS_PATH

    # Option 4: ADC (Application Default Credentials)
    return None


class FirebaseAdminManager:
    _instance: Optional['FirebaseAdminManager'] = None

    def __init__(self):
        self.app: Optional[firebase_admin.App] = None
        self.db: Optional[firestore.Client] = None
        self.project_id: str = os.getenv("FIREBASE_PROJECT_ID", "bidder-fdede")
        self.database_id: str = os.getenv("FIRESTORE_DATABASE_ID", "(default)")
        self.credentials_path = _resolve_credentials()
        self._init_app()

    @classmethod
    def get_instance(cls) -> 'FirebaseAdminManager':
        if cls._instance is None:
            cls._instance = FirebaseAdminManager()
        return cls._instance

    @classmethod
    def get_app(cls) -> Optional[firebase_admin.App]:
        return cls.get_instance().app

    def _init_app(self):
        if not FIREBASE_AVAILABLE:
            print("[FirebaseAdmin] firebase-admin package not available.")
            return

        emulator_host = os.getenv("FIRESTORE_EMULATOR_HOST")
        emulator_status = f"enabled ({emulator_host})" if emulator_host else "disabled"

        try:
            # Check if already initialized
            if firebase_admin._apps:
                self.app = firebase_admin.get_app()
            else:
                if self.credentials_path and os.path.exists(self.credentials_path):
                    # Explicit service account file (local dev or Cloud Run with Secret Manager)
                    os.environ.setdefault("GOOGLE_CLOUD_PROJECT", self.project_id)
                    cred = credentials.Certificate(self.credentials_path)
                    self.app = firebase_admin.initialize_app(cred, {
                        'projectId': self.project_id,
                        'databaseURL': f'https://{self.project_id}.firebaseio.com'
                    })
                    print(f"[FirebaseAdmin] Initialized with service account file: {os.path.basename(self.credentials_path)}")
                else:
                    # Application Default Credentials — works on Cloud Run automatically
                    os.environ.setdefault("GOOGLE_CLOUD_PROJECT", self.project_id)
                    cred = credentials.ApplicationDefault()
                    self.app = firebase_admin.initialize_app(cred, {
                        'projectId': self.project_id,
                        'databaseURL': f'https://{self.project_id}.firebaseio.com'
                    })
                    print("[FirebaseAdmin] Initialized with Application Default Credentials (ADC).")

            # Initialize Firestore client
            try:
                self.db = firestore.client(app=self.app, database_id=self.database_id)
            except Exception as fe:
                print(f"[FirebaseAdmin] Firestore client init error: {fe}")
                self.db = None

            print(f"[FirebaseAdmin] Project: {self.project_id} | Database: {self.database_id} | Emulator: {emulator_status}")

        except Exception as e:
            print(f"[FirebaseAdmin] Error initializing Firebase Admin: {e}")
            print("[FirebaseAdmin] Running with local simulated state only.")
            self.app = None
            self.db = None

    def is_connected(self) -> bool:
        return self.app is not None and self.db is not None


def get_firestore_client() -> Optional[firestore.Client]:
    return FirebaseAdminManager.get_instance().db
