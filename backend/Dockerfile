FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# OS deps (certs, basic build tools if you need wheels later)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
 && update-ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Non-root user for runtime
RUN useradd -ms /bin/bash sujay

WORKDIR /app

# Install deps (system-wide) and suppress the root warning
COPY requirements.txt .
RUN python -m pip install --upgrade pip \
 && pip install --no-cache-dir --root-user-action=ignore -r requirements.txt

# App code
COPY Backend.py .

# Drop privileges for runtime
USER sujay

EXPOSE 8000
CMD ["gunicorn", "-w", "2", "-k", "gthread", "--threads", "8", "-b", "0.0.0.0:8000", "Backend:application"]
