#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Hero Ecosystem — Developer Setup
# Run this once on a new machine to get all hero projects ready for development.
#
# Usage:
#   curl -sL <your-url>/setup.sh | bash          # full setup
#   bash setup.sh --check                         # just verify what's installed
#   bash setup.sh --project narrativeHero          # set up one project only
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}!${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; }
info() { echo -e "  ${CYAN}→${NC} $1"; }
section() { echo -e "\n${BOLD}── $1 ──${NC}"; }

# ── Detect OS ─────────────────────────────────────────────────────────────────
detect_os() {
  case "$(uname -s)" in
    Darwin) OS="macos"; PKG="brew" ;;
    Linux)
      if [ -f /etc/debian_version ]; then OS="debian"; PKG="apt"
      elif [ -f /etc/redhat-release ]; then OS="rhel"; PKG="dnf"
      elif [ -f /etc/arch-release ]; then OS="arch"; PKG="pacman"
      else OS="linux"; PKG="unknown"
      fi ;;
    *) OS="unknown"; PKG="unknown" ;;
  esac
  echo -e "${DIM}Detected: $OS ($(uname -m))${NC}"
}

# ── Check / install a system dependency ───────────────────────────────────────
need() {
  local cmd="$1" name="${2:-$1}" why="${3:-}"
  if command -v "$cmd" &>/dev/null; then
    local ver="$("$cmd" --version 2>&1 | head -1)"
    ok "$name found: $ver"
    return 0
  fi

  warn "$name not found${why:+ — $why}"
  echo ""
  case "$PKG" in
    brew)
      case "$cmd" in
        python3)  info "Install: brew install python@3.11" ;;
        node)     info "Install: brew install node" ;;
        ffmpeg)   info "Install: brew install ffmpeg" ;;
        git)      info "Install: brew install git" ;;
        docker)   info "Install: brew install --cask docker" ;;
        tesseract) info "Install: brew install tesseract" ;;
      esac ;;
    apt)
      case "$cmd" in
        python3)  info "Install: sudo apt install -y python3 python3-venv python3-pip" ;;
        node)     info "Install: curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt install -y nodejs" ;;
        ffmpeg)   info "Install: sudo apt install -y ffmpeg" ;;
        git)      info "Install: sudo apt install -y git" ;;
        docker)   info "Install: sudo apt install -y docker.io docker-compose-v2" ;;
        tesseract) info "Install: sudo apt install -y tesseract-ocr" ;;
      esac ;;
    *)
      info "Please install $name manually for your OS" ;;
  esac
  return 1
}

# ── Check Python version ──────────────────────────────────────────────────────
check_python_version() {
  local py="${1:-python3}"
  local ver="$("$py" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || echo 0.0)"
  local major="${ver%%.*}" minor="${ver##*.}"
  if [ "$major" -ge 3 ] && [ "$minor" -ge 10 ]; then
    ok "Python $ver (>= 3.10 required)"
    return 0
  else
    fail "Python $ver is too old — need 3.10+"
    case "$PKG" in
      brew) info "Upgrade: brew install python@3.11" ;;
      apt)  info "Upgrade: sudo apt install -y python3.11 python3.11-venv" ;;
    esac
    return 1
  fi
}

# ── Check Node version ────────────────────────────────────────────────────────
check_node_version() {
  local ver="$(node -v 2>/dev/null | sed 's/v//')"
  local major="${ver%%.*}"
  if [ "${major:-0}" -ge 18 ]; then
    ok "Node.js v$ver (>= 18 required)"
    return 0
  else
    fail "Node.js v${ver:-not installed} — need 18+"
    return 1
  fi
}

# ── Set up a Python project ──────────────────────────────────────────────────
setup_python_project() {
  local dir="$1" name="$2" why="$3"
  if [ ! -d "$dir" ]; then
    warn "$name not found at $dir — skipping"
    return 0
  fi

  info "${BOLD}$name${NC} — $why"

  # Create venv if missing
  if [ ! -d "$dir/.venv" ]; then
    info "Creating Python virtual environment..."
    python3 -m venv "$dir/.venv"
    ok "venv created"
  else
    ok "venv exists"
  fi

  # Install deps if requirements.txt exists
  if [ -f "$dir/requirements.txt" ]; then
    info "Installing Python dependencies..."
    "$dir/.venv/bin/pip" install -q -r "$dir/requirements.txt" 2>&1 | tail -1
    ok "dependencies installed"
  fi

  # Check for .env
  if [ -f "$dir/.env" ]; then
    ok ".env exists"
  elif [ -f "$dir/.env.example" ]; then
    cp "$dir/.env.example" "$dir/.env"
    warn ".env created from template — fill in your API keys"
  else
    warn "No .env or .env.example found"
  fi
}

# ── Set up a Node project ────────────────────────────────────────────────────
setup_node_project() {
  local dir="$1" name="$2" why="$3"
  if [ ! -d "$dir" ]; then
    warn "$name not found at $dir — skipping"
    return 0
  fi

  info "${BOLD}$name${NC} — $why"

  if [ -f "$dir/package.json" ]; then
    if [ ! -d "$dir/node_modules" ]; then
      info "Installing npm dependencies..."
      (cd "$dir" && npm install --silent 2>&1 | tail -1)
      ok "node_modules installed"
    else
      ok "node_modules exist"
    fi
  fi
}

# ── .env template helper ─────────────────────────────────────────────────────
create_env_if_missing() {
  local dir="$1" name="$2"
  if [ -f "$dir/.env" ]; then return 0; fi

  # narrativeHero backend .env
  if [ "$name" = "narrativeHero" ] && [ ! -f "$dir/backend/.env" ]; then
    cat > "$dir/backend/.env" << 'ENVEOF'
# narrativeHero backend — minimum config
# Get a Gemini API key at https://aistudio.google.com/app/apikey

GOOGLE_API_KEY=your-gemini-key-here

# Optional: extra keys for rotation (avoids 429s under load)
# GOOGLE_API_KEY_1=
# GOOGLE_API_KEY_2=

# Optional: OpenAI fallback for transcription
# OPENAI_API_KEY=

# Optional: Telegram bot
# TELEGRAM_BOT_TOKEN=
# TELEGRAM_WEBHOOK_SECRET=

# Optional: allowed frontend origins (production CORS)
# ALLOWED_ORIGINS=https://your-app.example.com
ENVEOF
    warn "Created backend/.env — add your GOOGLE_API_KEY to start"
  fi
}

# ═════════════════════════════════════════════════════════════════════════════
# MAIN
# ═════════════════════════════════════════════════════════════════════════════

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║    Hero Ecosystem — Developer Setup      ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

CHECK_ONLY=false
TARGET_PROJECT=""
PROJECTS_ROOT="${HERO_PROJECTS_ROOT:-$(pwd)}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) CHECK_ONLY=true; shift ;;
    --project) TARGET_PROJECT="$2"; shift 2 ;;
    --root) PROJECTS_ROOT="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

detect_os

# ── 1. System Dependencies ───────────────────────────────────────────────────
section "System Dependencies"
echo -e "  ${DIM}These are tools the hero projects need at the OS level.${NC}"
echo ""

DEPS_OK=true
need git     "Git"       "version control for all projects" || DEPS_OK=false
need python3 "Python 3"  "backend servers, scripts, automation" || DEPS_OK=false
need node    "Node.js"   "frontend dev server (SvelteKit)" || DEPS_OK=false
need ffmpeg  "FFmpeg"    "audio format conversion, video extraction" || DEPS_OK=false

echo ""
echo -e "  ${DIM}Optional (only needed for specific projects):${NC}"
need docker    "Docker"    "production deployment, Appwrite stack" || true
need tesseract "Tesseract" "OCR image text extraction (dataHero)" || true

if $DEPS_OK; then
  echo ""
  ok "All required dependencies present"
else
  echo ""
  fail "Some dependencies missing — install them and re-run"
  if $CHECK_ONLY; then exit 1; fi
fi

# ── 2. Version Checks ────────────────────────────────────────────────────────
section "Version Checks"
check_python_version || true
check_node_version || true

if $CHECK_ONLY; then
  echo ""
  echo -e "${GREEN}Check complete.${NC}"
  exit 0
fi

# ── 3. Clone Repos (if not present) ──────────────────────────────────────────
section "Project Repositories"
echo -e "  ${DIM}Each project is a separate repo. They live side by side.${NC}"
echo ""

REPOS=(
  "narrativeHero|https://github.com/juandld/narritive-hero.git|Voice capture, content planner, orchestrator — the central hub"
  "dataHero|https://github.com/juandld/datahero.git|Google Workspace bridge, web crawling, data ops"
  "crankHero|https://github.com/juandld/crankHero.git|CrankWheel sales CRM, communications, landing pages"
  "osHero|https://github.com/juandld/osHero.git|Service supervisor, health checks, Telegram alerts"
)

for entry in "${REPOS[@]}"; do
  IFS='|' read -r name url desc <<< "$entry"

  if [ -n "$TARGET_PROJECT" ] && [ "$name" != "$TARGET_PROJECT" ]; then
    continue
  fi

  if [ -d "$PROJECTS_ROOT/$name" ]; then
    ok "$name exists — $desc"
  else
    info "Cloning $name — $desc"
    git clone "$url" "$PROJECTS_ROOT/$name" 2>&1 | tail -1
    ok "$name cloned"
  fi
done

# ── 4. Project Setup ─────────────────────────────────────────────────────────
section "Setting Up Projects"
echo -e "  ${DIM}Creating virtual environments, installing deps, checking .env files.${NC}"
echo ""

P="$PROJECTS_ROOT"

# narrativeHero — backend (Python)
if [ -z "$TARGET_PROJECT" ] || [ "$TARGET_PROJECT" = "narrativeHero" ]; then
  setup_python_project "$P/narrativeHero/backend" "narrativeHero/backend"     "FastAPI server — transcription, content planner, orchestrator queue"
  setup_node_project "$P/narrativeHero/frontend" "narrativeHero/frontend"     "SvelteKit UI — notes, recordings, content planner, dashboard"
  create_env_if_missing "$P/narrativeHero" "narrativeHero"
fi

# dataHero
if [ -z "$TARGET_PROJECT" ] || [ "$TARGET_PROJECT" = "dataHero" ]; then
  setup_python_project "$P/dataHero" "dataHero"     "Google Sheets/Docs/Gmail bridge, web crawler, onboarding ingestion"
  if [ -d "$P/dataHero/.venv" ] && command -v playwright &>/dev/null; then
    info "Installing Playwright browsers (needed for web crawling)..."
    "$P/dataHero/.venv/bin/python" -m playwright install chromium 2>&1 | tail -1 || true
  fi
fi

# osHero
if [ -z "$TARGET_PROJECT" ] || [ "$TARGET_PROJECT" = "osHero" ]; then
  setup_python_project "$P/osHero" "osHero"     "Service health monitor, Telegram alerts, permission gate"
fi

# crankHero — no deps, just env
if [ -z "$TARGET_PROJECT" ] || [ "$TARGET_PROJECT" = "crankHero" ]; then
  if [ -d "$P/crankHero" ]; then
    info "${BOLD}crankHero${NC} — CRM scripts, cron jobs (stdlib only, no pip install needed)"
    if [ -f "$P/crankHero/.env" ]; then
      ok ".env exists"
    elif [ -f "$P/crankHero/.env.example" ]; then
      cp "$P/crankHero/.env.example" "$P/crankHero/.env"
      warn ".env created from template"
    fi
    ok "crankHero ready (no external deps)"
  fi
fi

# ── 5. Summary ────────────────────────────────────────────────────────────────
section "What's Next"
echo ""
echo -e "  1. ${BOLD}Add API keys${NC} to each project's .env file"
echo -e "     At minimum: ${CYAN}GOOGLE_API_KEY${NC} in narrativeHero/backend/.env"
echo -e "     Get one at: https://aistudio.google.com/app/apikey"
echo ""
echo -e "  2. ${BOLD}Start narrativeHero${NC} (the main app):"
echo -e "     ${DIM}cd $P/narrativeHero && ./dev.sh${NC}"
echo -e "     This starts both backend (:8000) and frontend (:5173)"
echo ""
echo -e "  3. ${BOLD}Open in browser${NC}: http://localhost:5173"
echo ""
echo -e "  4. ${BOLD}Run tests${NC}:"
echo -e "     ${DIM}cd $P/narrativeHero && bash tests/backend/test.sh${NC}"
echo ""
echo -e "  ${DIM}For more: see narrativeHero/README.md${NC}"
echo ""
echo -e "${GREEN}Setup complete.${NC}"
