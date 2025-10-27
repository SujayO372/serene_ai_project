#!/bin/sh
set -eu

DOMAINS="${DOMAINS:-}"
EMAIL="${EMAIL:-}"
WEBROOT="${WEBROOT:-/var/www/certbot}"
PROXY_NAME="${PROXY_NAME:-reverse-proxy}"
HEALTH_URL_HTTP="${HEALTH_URL_HTTP:-http://localhost/.well-known/acme-challenge/health}"
RUN_AT_MINUTE="${RUN_AT_MINUTE:-5}"

primary_domain="$(printf '%s\n' $DOMAINS | awk 'NR==1')"
cert_dir="/etc/letsencrypt/live/$primary_domain"
fullchain="$cert_dir/fullchain.pem"

sleep_until_midnight() {
  now=$(date +%s)
  next_midnight=$(date -d "tomorrow 00:00" +%s 2>/dev/null || date -v+1d -v0H -v0M -v0S +%s)
  target=$(( next_midnight + RUN_AT_MINUTE*60 ))
  [ "$target" -le "$now" ] && target=$(( target + 86400 ))
  sleep $(( target - now ))
}

mkdir -p "$WEBROOT/.well-known/acme-challenge"
echo OK > "$WEBROOT/.well-known/acme-challenge/health"

echo "[certbot] Waiting for HTTP health: $HEALTH_URL_HTTP"
i=0
until curl -fsS --max-time 5 "$HEALTH_URL_HTTP" >/dev/null 2>&1; do
  i=$((i+1)); [ $i -gt 120 ] && { echo "[certbot] health timeout, retrying in 60s"; sleep 60; i=0; } || sleep 5
done
echo "[certbot] HTTP health OK."

issue_if_needed() {
  # Issue if missing
  if [ ! -f "$fullchain" ]; then
    echo "[certbot] No cert found. Issuing…"
    set -- certonly --webroot -w "$WEBROOT" --email "$EMAIL" --agree-tos --no-eff-email --non-interactive
    for d in $DOMAINS; do set -- "$@" -d "$d"; done
    certbot "$@"
    return 0
  fi

  # Check if cert expires within 30 days (2592000 seconds)
  if ! openssl x509 -in "$fullchain" -noout -checkend 2592000 >/dev/null 2>&1; then
    echo "[certbot] Cert expires within 30 days. Renewing…"
    certbot renew --webroot -w "$WEBROOT" --quiet
    return 0
  fi

  echo "[certbot] Cert valid >30 days. No action."
  return 1
}

reload_nginx() {
  # Requires docker CLI in container; if not present, this will be a no-op.
  if command -v docker >/dev/null 2>&1; then
    docker exec "$PROXY_NAME" nginx -s reload || true
  fi
}

# Initial run
if issue_if_needed; then
  reload_nginx
fi

# Nightly check at 00:05
while :; do
  sleep_until_midnight
  if issue_if_needed; then
    reload_nginx
  fi
done
