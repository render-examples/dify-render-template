#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "Starting Dify (template-shaped local stack)..."
echo "  UI:  http://localhost:3000"
echo "  API: http://localhost:5001"
echo "  First-time password (INIT_PASSWORD): difyai123456"
echo ""

docker compose -f docker-compose.local.yml pull
docker compose -f docker-compose.local.yml up -d

echo ""
echo "Waiting for API health (may take several minutes on first boot)..."
for i in $(seq 1 60); do
  if curl -sf http://localhost:5001/health >/dev/null 2>&1; then
    echo "API is healthy."
    exit 0
  fi
  sleep 10
  echo "  ... still starting ($((i * 10))s)"
done

echo "API not healthy yet. Check logs: docker compose -f docker-compose.local.yml logs -f api"
exit 1
