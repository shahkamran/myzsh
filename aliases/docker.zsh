#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: aliases/docker                                           ║
# ║  Docker & docker-compose shortcuts                                  ║
# ╚══════════════════════════════════════════════════════════════════════╝

# ─── Docker ───────────────────────────────────────────────────────────
alias d='docker'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dpsa='docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias di='docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"'
alias drm='docker rm'
alias drmi='docker rmi'
alias dex='docker exec -it'
alias dlog='docker logs -f'
alias dstop='docker stop $(docker ps -q)'
alias dprune='docker system prune -af --volumes'
alias dbuild='docker build -t'
alias drun='docker run --rm -it'

# ─── Docker Compose ───────────────────────────────────────────────────
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcr='docker compose restart'
alias dcl='docker compose logs -f'
alias dcb='docker compose build'
alias dce='docker compose exec'
alias dcps='docker compose ps'
