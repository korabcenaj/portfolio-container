# Portfolio Container Deployment

This directory contains a static site container for `portfolio.html` and a Cloudflare Tunnel service.

## Quick start

1. Copy `portfolio.html` to this folder (already done).
2. Get Cloudflare tunnel credentials:
   - Install `cloudflared` locally or in container.
   - Run: `cloudflared tunnel login`
   - Run: `cloudflared tunnel create <NAME>`
   - Add DNS route: `cloudflared tunnel route dns <NAME> <YOUR_DOMAIN>`
   - Copy the generated `credentials.json` into `.cloudflared/`.
   - Set `tunnel` ID in `.cloudflared/config.yml` and your hostname.
3. Start stack:
   - `docker compose up --build`.
4. Verify locally at: `http://localhost:8080`

## Environment

- NGINX static server on `web` service
- Cloudflared tunnel on `cloudflared` service

## Notes

- You may use `command` in `docker-compose.yml` with `--url http://web:80` as alternative.
- Ensure `CLOUDFLARED_TOKEN` is set in the shell when using token mode.
