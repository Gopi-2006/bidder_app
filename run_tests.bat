@echo off
echo ===================================================
echo Running GeM Deterministic Rule Engine Test Suite
echo ===================================================
cd backend
python -m pytest tests/ -v
pause
