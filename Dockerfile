# Use Python 3.11 slim image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy backend files
COPY backend/requirements.txt /app/
COPY backend/ /app/

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose port (Railway will set PORT env var)
EXPOSE 8000

# Start command
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}
