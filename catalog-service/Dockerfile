FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Set environment variables
ENV DATABASE_URL=sqlite:///./catalog.db
ENV USER_SERVICE_URL=http://user-service:8000
ENV ADMIN_EMAILS=admin@seneca.ca,admin@example.com

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
