#!/bin/bash
set -euo pipefail

PRJ="/scratch/sujay/serene_ai_project"
WEBROOT="$PRJ/certbot/www"
LE="$PRJ/letsencrypt"
PRIMARY="www.serenespaceai.com"         # first SAN
DOMS=(-d www.serenespaceai.com -d serenespaceai.com)

mkdir -p "$WEBROOT/.well-known/acme-challenge"
echo OK > "$WEBROOT/.well-known/acme-challenge/health"

# Wait until the reverse-proxy serves the health file locally on :80
for i in {1..120}; do
  if curl -fsS --max-time 5 "http://localhost/.well-known/acme-challenge/health" >/dev/null; then
    break
  fi
  sleep 5
done

needs=0
if [ ! -f "$LE/live/$PRIMARY/fullchain.pem" ]; then
  needs=1
elif ! openssl x509 -in "$LE/live/$PRIMARY/fullchain.pem" -noout -checkend 2592000 >/dev/null; then
  # expires within 30 days (2592000 sec)
  needs=1
fi

if [ $needs -eq 1 ]; then
  docker run --rm --network host \
    -v "$LE:/etc/letsencrypt" \
    -v "$WEBROOT:/var/www/certbot" \
    certbot/certbot:latest \
    certonly --webroot -w /var/www/certbot \
    "${DOMS[@]}" \
    --email sujayoggu@gmail.com --agree-tos --no-eff-email --non-interactive
  # reload nginx inside the proxy container (named "reverse-proxy")
  docker exec reverse-proxy nginx -s reload || true
fi
