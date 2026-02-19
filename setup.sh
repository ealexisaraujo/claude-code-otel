#!/usr/bin/env bash
set -euo pipefail

# ─── Colors & Helpers ─────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { printf "${BLUE}[INFO]${NC}  %s\n" "$1"; }
success() { printf "${GREEN}[OK]${NC}    %s\n" "$1"; }
warn()    { printf "${YELLOW}[WARN]${NC}  %s\n" "$1"; }
fail()    { printf "${RED}[ERROR]${NC} %s\n" "$1"; exit 1; }

# ─── Banner ───────────────────────────────────────────────────────────────────
echo ""
printf "${CYAN}${BOLD}"
cat << 'BANNER'
   ╔═══════════════════════════════════════════════════╗
   ║   Claude Code Observability Stack                 ║
   ║   Metrics · Events · Dashboards                   ║
   ╚═══════════════════════════════════════════════════╝
BANNER
printf "${NC}\n"

# ─── Step 1: Check Prerequisites ─────────────────────────────────────────────
info "Checking prerequisites..."

if ! command -v docker &>/dev/null; then
  fail "Docker is not installed. Get it at https://docs.docker.com/get-docker/"
fi

if ! docker info &>/dev/null; then
  fail "Docker is not running. Please start Docker Desktop and try again."
fi

if ! docker compose version &>/dev/null; then
  fail "Docker Compose is not available. Update Docker Desktop to the latest version."
fi

success "Docker is installed and running"

# ─── Step 2: Detect Shell Config ─────────────────────────────────────────────
SHELL_NAME="$(basename "$SHELL")"
case "$SHELL_NAME" in
  zsh)  SHELL_RC="$HOME/.zshrc" ;;
  bash) SHELL_RC="$HOME/.bashrc" ;;
  *)    SHELL_RC="$HOME/.${SHELL_NAME}rc" ;;
esac

info "Detected shell: $SHELL_NAME (config: $SHELL_RC)"

# ─── Step 3: Add Environment Variables ────────────────────────────────────────
MARKER="# Claude Code OpenTelemetry - Observability Stack"

if grep -qF "$MARKER" "$SHELL_RC" 2>/dev/null; then
  success "Environment variables already configured in $SHELL_RC"
else
  info "Adding environment variables to $SHELL_RC..."
  cat >> "$SHELL_RC" << 'ENVVARS'

# Claude Code OpenTelemetry - Observability Stack
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
export OTEL_METRIC_EXPORT_INTERVAL=60000
export OTEL_LOGS_EXPORT_INTERVAL=5000
export OTEL_METRICS_INCLUDE_SESSION_ID=true
export OTEL_METRICS_INCLUDE_ACCOUNT_UUID=true
export OTEL_LOG_TOOL_DETAILS=1
export OTEL_LOG_USER_PROMPTS=1
ENVVARS
  success "Environment variables added to $SHELL_RC"
fi

# ─── Step 4: Start Docker Services ───────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
info "Starting Docker containers..."
docker compose -f "$SCRIPT_DIR/docker-compose.yml" up -d --quiet-pull 2>&1 | while read -r line; do
  printf "  %s\n" "$line"
done

# ─── Step 5: Wait for Services ───────────────────────────────────────────────
info "Waiting for services to be ready..."

wait_for() {
  local name="$1" url="$2" max_attempts="${3:-30}"
  for i in $(seq 1 "$max_attempts"); do
    if curl -sf "$url" -o /dev/null 2>/dev/null; then
      success "$name is ready"
      return 0
    fi
    sleep 1
  done
  warn "$name did not become ready in ${max_attempts}s (it may still be starting)"
}

wait_for "Loki"       "http://localhost:3100/ready" 30
wait_for "Prometheus"  "http://localhost:9090/-/ready" 15
wait_for "Grafana"     "http://localhost:3001/api/health" 15

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
printf "${GREEN}${BOLD}"
cat << 'DONE'
   ╔═══════════════════════════════════════════════════╗
   ║                  Setup Complete!                   ║
   ╚═══════════════════════════════════════════════════╝
DONE
printf "${NC}\n"

echo "  Open Grafana:  ${BOLD}http://localhost:3001${NC}"
echo "    Login:       admin / ClaudeCode2026"
echo ""
echo "  Dashboards:"
echo "    Overview:    ${CYAN}http://localhost:3001/d/claude-code-personal/${NC}"
echo "    Deep Dive:   ${CYAN}http://localhost:3001/d/claude-code-deep/${NC}"
echo ""
printf "  ${YELLOW}${BOLD}IMPORTANT:${NC} Open a ${BOLD}new terminal${NC} and start Claude Code for\n"
echo "  telemetry to flow. Env vars are read at startup."
echo ""
