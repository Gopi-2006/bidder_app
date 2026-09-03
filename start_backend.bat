@echo off
echo ===================================================
echo Starting GeM AI Compliance FastAPI Backend Engine
echo API Docs: http://127.0.0.1:8000/docs
echo ===================================================
cd backend
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
pause
