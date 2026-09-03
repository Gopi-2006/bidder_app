# Production Dockerfile for FastAPI Backend on Render / Cloud Container
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8080 \
    ENVIRONMENT=production

WORKDIR /app

# Upgrade pip and install python dependencies
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy backend application source
COPY . /app

EXPOSE 8080

# Production startup dynamically listening on 0.0.0.0 and $PORT
CMD exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080} --workers 1
