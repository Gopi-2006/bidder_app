from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.endpoints import router as api_router

app = FastAPI(
    title="GeM Tender Compliance Verification Engine",
    description="AI-Powered Explainable Compliance Verification System for Government of India e-Marketplace (GeM)",
    version="1.0.0",
)

# Enable CORS for React Frontend and Mobile Clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)


@app.get("/")
def root():
    return {
        "service": "GeM AI Compliance Verification Backend",
        "status": "OPERATIONAL",
        "version": "1.0.0",
        "deterministic_engine": "ACTIVE",
        "trust_boundary": "ENFORCED",
        "docs_url": "/docs",
    }


@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "GeM AI Compliance Verification Backend",
        "version": "1.0.0",
    }


if __name__ == "__main__":
    import os
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, reload=True)
