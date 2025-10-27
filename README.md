# README — Developer Setup (No Docker)

> This guide runs the Python backend and the Vite frontend **directly** on your machine (no containers). Ideal for fast iteration with hot reload.

## Prerequisites

* **Python 3.10+**
* **Node.js 18+** (Node 20 recommended) and **npm** (or yarn/pnpm)
* **Git** (optional)
* macOS/Linux/WSL are all fine

## Repo Layout

```
.
├── backend
│   ├── Backend.py
│   ├── requirements.txt
│   └── Dockerfile            # not used in this guide
├── frontend
│   ├── package.json
│   ├── src/ …
│   ├── vite.config.js
│   └── Dockerfile            # not used in this guide
└── reverse-proxy/            # not used in this guide
```

## 1) Backend — Python API

1. Create and activate a virtualenv:

   ```bash
   cd backend
   python3 -m venv .venv
   source .venv/bin/activate   # Windows: .venv\Scripts\activate
   ```

2. Install dependencies:

   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

3. Configure environment (create `.env` at `backend/.env` if you use env vars):

   ```bash
   # backend/.env (example)
   HOST=127.0.0.1
   PORT=8000
   # Add any keys you use, e.g. OPENAI_API_KEY=..., DB_URL=..., etc.
   ```

4. Run the backend (pick the command that matches your app):

   * **If `Backend.py` is the entry point**:

     ```bash
     python Backend.py
     ```

   * **If you’re using FastAPI + Uvicorn** (common in projects like this):

     ```bash
     uvicorn Backend:app --reload --host 127.0.0.1 --port 8000
     ```

     > Adjust `Backend:app` to the module and variable name of your FastAPI app.

   * **If you’re using Flask**:

     ```bash
     export FLASK_APP=Backend.py
     export FLASK_ENV=development
     flask run --host=127.0.0.1 --port=8000
     ```

5. Quick health check:

   ```bash
   curl http://127.0.0.1:8000/
   ```

   > Replace `/` with a known health route like `/health` if you have one.

### CORS in dev (only if you **don’t** use the Vite proxy below)

If the frontend hits `http://localhost:8000` directly, enable CORS in the API.

* **FastAPI**:

  ```python
  # in Backend.py
  from fastapi.middleware.cors import CORSMiddleware

  app.add_middleware(
      CORSMiddleware,
      allow_origins=["http://localhost:5173"],
      allow_credentials=True,
      allow_methods=["*"],
      allow_headers=["*"],
  )
  ```
* **Flask**:

  ```python
  # pip install flask-cors
  from flask_cors import CORS
  CORS(app, resources={r"/*": {"origins": "http://localhost:5173"}})
  ```

## 2) Frontend — Vite App

1. Install Node deps:

   ```bash
   cd ../frontend
   npm ci
   ```

2. Create a frontend env file:

   ```bash
   # frontend/.env.local
   VITE_API_BASE=http://localhost:8000
   ```

   Use this in your code via `import.meta.env.VITE_API_BASE`.

3. **Dev proxy (recommended)** — avoids CORS entirely.
   In `vite.config.js`, add a proxy so that calls to `/api` go to the backend:

   ```js
   // vite.config.js
   export default {
     server: {
       port: 5173,
       strictPort: true,
       proxy: {
         '/api': {
           target: 'http://localhost:8000',
           changeOrigin: true,
           rewrite: (path) => path.replace(/^\/api/, ''),
         },
       },
     },
   }
   ```

   Then, in the frontend code, call your API with `/api/...` (no hardcoded host).

4. Start the dev server:

   ```bash
   npm run dev
   ```

   Open [http://localhost:5173](http://localhost:5173)

## 3) Running Both Together

* Terminal A:

  ```bash
  cd backend
  source .venv/bin/activate
  python Backend.py   # or uvicorn / flask run as above
  ```
* Terminal B:

  ```bash
  cd frontend
  npm run dev
  ```

**Flow**:

* Browser → `http://localhost:5173` (Vite)
* API calls → `http://localhost:5173/api/*` → proxied to `http://localhost:8000/*`

## 4) Environment Variables Summary

* **Backend** (`backend/.env`):

  * `HOST`, `PORT`
  * Any service keys: `OPENAI_API_KEY`, `DB_URL`, etc.
* **Frontend** (`frontend/.env.local`):

  * `VITE_API_BASE` (if not using the proxy), otherwise you can omit

> Never commit real secrets. Commit `.env.example` files instead.

## 5) Common Troubleshooting

* **CORS errors**: Prefer the **Vite proxy**. If you must hit the API directly, enable CORS in the backend as shown.
* **Port conflicts**: Change `PORT` in backend or `server.port` in `vite.config.js`.
* **Env not loading**: Ensure you `source .venv/bin/activate` (backend) and use `.env.local` (frontend) for Vite.
* **Mixed Content (HTTPS)**: In dev, avoid HTTPS locally. Keep both services on plain `http://localhost`.
* **Path issues on reverse-proxy configs**: Not used in this no-Docker dev flow; keep Nginx/certbot for prod only.

## 6) Suggested NPM/Python Scripts (optional quality-of-life)

**backend/Makefile** (optional)

```makefile
run:
\t. .venv/bin/activate && python Backend.py
install:
\tpython3 -m venv .venv && . .venv/bin/activate && pip install -r requirements.txt
```

**frontend/package.json** (add)

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview --port 5173"
  }
}
```

---

## Production note (future)

* Keep **reverse-proxy + TLS** in prod (Nginx + certbot).
* Maintain two compose files:

  * `docker-compose.dev.yml` → just `backend`, `frontend` with bind mounts and hot reload.
  * `docker-compose.prod.yml` → `backend`, `frontend` (built), `reverse-proxy`, `certbot`.

If you want, I can generate those two compose files from your current `docker-compose.yml` and simplify the certbot/renew flow.

