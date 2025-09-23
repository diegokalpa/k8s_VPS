# n8n via Docker (Hostinger VPS)

Simple, reliable `docker-compose` setup to run n8n on your VPS.

## Files
- `docker-compose.yml`: service, volume, port mapping (host 8080 → container 5678).
- `.env.example`: configuration template for n8n. Copy to `.env` and fill values.

## Quick Start
1) Install Docker + Compose on Ubuntu:
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# log out and back in (or: newgrp docker)
```

2) Prepare env file:
```bash
cp .env.example .env
nano .env
# - Set N8N_ENCRYPTION_KEY (long random string)
# - Set N8N_BASIC_AUTH_*
# - Set N8N_HOST/WEBHOOK_URL to your IP or domain initially
```

3) Launch n8n:
```bash
docker compose up -d
```

4) Verify:
```bash
docker ps
curl -I http://localhost:8080/healthz
# Open http://<VPS-IP>:8080 in browser
```

## Secure Access
- Recommended: put n8n behind a reverse proxy with TLS (Caddy/Traefik/Nginx), or point DNS to your VPS and set `N8N_PROTOCOL=https` with a proxy handling HTTPS.
- Keep `.env` out of source control. Store secrets in a private repo or a secret manager.

## Connect Existing Supabase (Postgres)
1) Stop the container: `docker compose down`.
2) Edit `.env` and switch to Postgres:
```env
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=<supabase-host>
DB_POSTGRESDB_PORT=6543
DB_POSTGRESDB_DATABASE=postgres
DB_POSTGRESDB_SCHEMA=public
DB_POSTGRESDB_USER=<user>
DB_POSTGRESDB_PASSWORD=<password>
DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false
```
3) Start: `docker compose up -d`.
4) Validate in UI and run a couple of workflows.

## Hardening Tips
- Change default port mapping and enforce Basic Auth.
- Use firewall (UFW): allow only 80/443 (if using reverse proxy) and 22 from your IP.
- Regularly backup `/home/node/.n8n` (volume `n8n_data`).

## Migrate from Cloud Run
- Export workflows from your current n8n; import them into the new instance.
- For minimal downtime, switch DNS (or update webhook endpoints) once verified.
- Keep Cloud Run paused for a few days before decommissioning.
