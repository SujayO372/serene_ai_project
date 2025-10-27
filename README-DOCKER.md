Got it — here’s a tight, copy-pasteable **Docker deployment guide** that assumes your repo already contains working configs (`docker-compose.yml`, `reverse-proxy/nginx.https.conf`, `certbot/`, `letsencrypt/`, etc.). No edits to configs are required.

---

# Deploy / Undeploy with Docker

## Prerequisites

* Docker 24+ and Docker Compose v2+
* DNS A-record for your domain points to this server
* Ports **80** and **443** open

> Run all commands from your project root: `/scratch/sujay/serene_ai_project`

---

## One-Time Setup (first HTTPS issuance)

1. **Start stack (HTTP & internal services)**

```bash
docker compose up -d --build
```

2. **Issue Let’s Encrypt cert (webroot)**

```bash
# Replace values ONLY if your compose uses different service names
CERTBOT_SVC=certbot
DOMAIN=www.serenespaceai.com
EMAIL=you@example.com

docker compose run --rm $CERTBOT_SVC certbot certonly \
  --webroot -w /var/www/certbot \
  -d $DOMAIN \
  --email $EMAIL --agree-tos --no-eff-email
```

3. **Reload Nginx to pick up TLS**

```bash
docker compose exec revproxy nginx -s reload
```

Verify in browser: `https://www.serenespaceai.com`

---

## Day-to-Day Operations

### Deploy (fresh or update code)

```bash
git pull                     # if using git on the server
docker compose up -d --build
docker compose ps
docker compose logs -f       # Ctrl+C to stop tailing
```

### Zero-downtime style refresh (when only backend/frontend code changed)

```bash
# Rebuild only what changed and restart gracefully
docker compose build
docker compose up -d
docker compose exec revproxy nginx -s reload   # optional, if proxy rules changed
```

### Undeploy (stop everything)

```bash
docker compose down
```

### Undeploy and remove anonymous volumes (be careful)

```bash
docker compose down -v
```

> Do **not** delete the `letsencrypt/` directory if you want to keep existing certs.

---

## SSL Renewal

### Manual dry-run (check)

```bash
docker compose exec certbot certbot renew --dry-run -v
```

### Manual renewal now + reload Nginx

```bash
docker compose exec certbot certbot renew --quiet
docker compose exec revproxy nginx -s reload
```

### (Optional) Cron job

```bash
crontab -e
# run daily at 02:30
30 2 * * * cd /scratch/sujay/serene_ai_project && docker compose exec -T certbot certbot renew --quiet && docker compose exec -T revproxy nginx -s reload
```

---

## Quick Health & Debug

```bash
# Show status
docker compose ps

# Tail logs for all services
docker compose logs -f

# Only Nginx logs (reverse proxy)
docker compose logs -f revproxy

# Validate Nginx config
docker compose exec revproxy nginx -t

# Check cert files exist
ls -l ./letsencrypt/live/www.serenespaceai.com/{fullchain.pem,privkey.pem}
```

**Common gotchas**

* **HTTP-01 challenge fails** → confirm port **80** open, DNS correct, and `/.well-known/acme-challenge/` is served from `./certbot/www`.
* **502/504** → backend/frontend service name or internal port mismatch with `proxy_pass`.
* **Permission issues** → ensure `letsencrypt/` is writable by the certbot container.

---

## Cleanup (optional)

Remove dangling images/unused layers (safe routine maintenance):

```bash
docker image prune -f
docker builder prune -f
```

---

## Backup (recommended)

Persist these between hosts/rebuilds:

* `./letsencrypt/` (certificates)
* Any persistent app data volumes you configured in `docker-compose.yml`

---

That’s it — deploy = `docker compose up -d --build`, undeploy = `docker compose down`, first-time HTTPS = run the `certbot certonly` command once, then `nginx -s reload`.

