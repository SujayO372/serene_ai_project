---

# 🚀 SereneSpaceAI — Deployment & Development Guide

This project provides both Docker-based and manual developer deployment options.

---

## 🧱 1. Clone the Repository

```bash
git clone https://github.com/SujayO372/serene_ai_project.git
cd serene_ai_project
```

---

## 🐳 2. Docker-Based Deployment (Recommended for Production)

### Prerequisites

* Docker 24+
* Docker Compose v2+
* A domain name (e.g. `www.serenespaceai.com`) with ports **80** and **443** open

### Steps

```bash
# Build and start all services (backend, frontend, nginx, certbot)
docker compose up -d --build
```

### (Optional) Issue Let’s Encrypt Certificate (first time only)

```bash
docker compose run --rm certbot certbot certonly \
  --webroot -w /var/www/certbot \
  -d www.serenespaceai.com \
  --email you@example.com --agree-tos --no-eff-email
docker compose exec revproxy nginx -s reload
```

### Check running containers

```bash
docker compose ps
```

### View logs

```bash
docker compose logs -f
```

### Stop / remove stack

```bash
docker compose down
```

Your app should now be available at:

```
https://www.serenespaceai.com
```

---

## 💻 3. Local Development (Without Docker)

### Prerequisites

* Python 3.10+
* Node.js 18+ and npm
* Git

---

### Backend Setup

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp ../.env.example .env   # create your local .env and fill secrets
python Backend.py         # or uvicorn Backend:app --reload --port 8000
```

---

### Frontend Setup

Open a second terminal:

```bash
cd frontend
npm ci
cp ../.env.example .env.local   # optional, if Vite vars exist
npm run dev
```

Open in your browser:
👉 **[http://localhost:5173](http://localhost:5173)**

---

### Local API Connection

If you’re using the Vite proxy (recommended), API requests like `/api/...` will automatically route to your backend at `http://localhost:8000`.

Otherwise, ensure your `.env.local` contains:

```bash
VITE_API_BASE=http://localhost:8000
```

---

## ⚙️ 4. Environment Setup

* **Never commit real `.env`** — only `.env.example` is versioned.
* To create your own `.env`:

  ```bash
  cp .env.example .env
  ```
* Fill in real keys (e.g., API tokens, database URLs).

---

## 🔄 5. Updating the App

```bash
git pull
# For Docker:
docker compose up -d --build
# For local dev:
# restart your backend and frontend
```

---

## 🧹 6. Cleanup Commands

```bash
# Stop and remove all containers, networks, and caches
docker compose down -v
docker system prune -f
```

---

✅ **Summary**

| Mode              | Command to Start                    | URL                                                            |
| ----------------- | ----------------------------------- | -------------------------------------------------------------- |
| Docker Deployment | `docker compose up -d --build`      | [https://www.serenespaceai.com](https://www.serenespaceai.com) |
| Local Development | `npm run dev` + `python Backend.py` | [http://localhost:5173](http://localhost:5173)                 |

---


