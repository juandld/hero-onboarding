# Hero Ecosystem — Developer Onboarding

## What is this?

A family of specialized projects that work together:

| Project | What it does | Tech | Has server? |
|---------|-------------|------|-------------|
| **narrativeHero** | Voice capture, transcription, content planner, orchestrator | FastAPI + SvelteKit | Yes (:8000 + :5173) |
| **dataHero** | Google Workspace bridge (Sheets/Docs/Gmail), web crawling | Python CLI + API | No (subprocess) |
| **crankHero** | CRM for sales deals, cron jobs, landing pages | Python scripts (stdlib) | No |
| **osHero** | Service health monitor, Telegram alerts, permission gate | Python daemon | Yes (:8765) |

narrativeHero is the hub — it runs the web UI and API. The others are tools or services it coordinates with.

## Quick Start

### 1. Run the setup script

```bash
# Clone this repo first, then from the projects directory:
bash setup.sh

# Or just check what you have / what's missing:
bash setup.sh --check

# Set up only one project:
bash setup.sh --project narrativeHero
```

The script will:
- Check your OS and tell you what to install (and how)
- Clone any missing repos
- Create Python virtualenvs and install dependencies
- Create .env files from templates
- Tell you what API keys to fill in

### 2. Get a Gemini API Key

This is the one key you absolutely need. Everything else is optional.

1. Go to https://aistudio.google.com/app/apikey
2. Click "Create API Key"
3. Paste it into `narrativeHero/backend/.env` as `GOOGLE_API_KEY=...`

### 3. Start the app

```bash
cd narrativeHero
./dev.sh
```

This launches:
- **Backend** at http://localhost:8000 (FastAPI, auto-reloads on save)
- **Frontend** at http://localhost:5173 (SvelteKit/Vite, hot-reloads)

Open http://localhost:5173 in your browser. Record a note or upload audio.

## System Requirements

### Required

| Tool | Why | Min version |
|------|-----|-------------|
| **Python** | Backend servers, scripts, automation | 3.10+ |
| **Node.js** | Frontend dev server (SvelteKit) | 18+ |
| **npm** | Frontend package management | comes with Node |
| **FFmpeg** | Audio format conversion (wav→m4a), video→audio extraction | any recent |
| **Git** | Version control | any recent |

### Optional

| Tool | Why | When you need it |
|------|-----|-----------------|
| **Docker** | Production deployment, Appwrite stack | Deploying to a server |
| **Tesseract** | OCR image text extraction | dataHero image processing |
| **Playwright** | Headless browser for web crawling | dataHero crawl jobs |

### Install by OS

**macOS (Homebrew):**
```bash
brew install python@3.11 node ffmpeg git
# Optional:
brew install --cask docker
brew install tesseract
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip ffmpeg git
# Node 20:
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
# Optional:
sudo apt install -y docker.io tesseract-ocr
```

**Windows (WSL recommended):**
Use WSL2 with Ubuntu, then follow the Ubuntu instructions above.

## Project Directory Layout

All projects live side by side in one parent directory:

```
projects/
├── narrativeHero/       # Central hub
│   ├── backend/         #   FastAPI app
│   │   ├── .env         #   API keys (gitignored)
│   │   ├── main.py      #   Routes
│   │   ├── services.py  #   Business logic
│   │   └── config.py    #   Env + model config
│   ├── frontend/        #   SvelteKit app
│   │   └── src/lib/     #     Components, stores, pages
│   ├── storage/         #   Audio files + JSON notes (gitignored)
│   ├── dev.sh           #   Start both servers
│   └── compose.yaml     #   Docker production stack
├── dataHero/            # Data operations
│   ├── cli/             #   CLI commands (ingest, export, crawl)
│   ├── ingestion/       #   Gmail/Sheets loaders
│   ├── operations/      #   Scheduled tasks, scripts
│   └── .env             #   Google OAuth + API keys
├── crankHero/           # Sales CRM
│   ├── scripts/         #   Cron jobs, CRM CLI, email tools
│   ├── crm/             #   Deal files as markdown (gitignored)
│   ├── landing/         #   SvelteKit landing page
│   └── development/     #   Plans, task board
└── osHero/              # Service monitor
    ├── daemon.py        #   Main supervisor loop
    ├── alerter.py       #   Telegram/Slack alerts
    ├── config.py        #   Service registry, paths
    └── .env             #   Bot tokens, alert config
```

## API Keys & Credentials

### What each project needs

**narrativeHero** (`backend/.env`):
- `GOOGLE_API_KEY` — **required** — Gemini for transcription + titles
- `GOOGLE_API_KEY_1..3` — optional extra keys for rotation under load
- `OPENAI_API_KEY` — optional fallback transcription
- `TELEGRAM_BOT_TOKEN` — optional Telegram voice note bot

**dataHero** (`.env`):
- `GOOGLE_API_KEY` — for LLM-powered data extraction
- `GOOGLE_OAUTH_CLIENT_ID/SECRET` — for Sheets/Gmail/Drive access
- Google OAuth credentials file at `.credentials/google_workspace.json`

**osHero** (`.env`):
- `TELEGRAM_BOT_TOKEN` — for health alerts
- `TELEGRAM_ALERT_CHAT_ID` — chat to send alerts to

**crankHero**: No API keys needed (uses narrativeHero's API for Sheets access).

### Google OAuth Setup (dataHero)

1. Go to https://console.cloud.google.com/apis/credentials
2. Create an OAuth 2.0 Client ID (Desktop app type)
3. Download the JSON, save as `dataHero/.credentials/google_workspace.json`
4. Set `GOOGLE_OAUTH_CLIENT_ID` and `GOOGLE_OAUTH_CLIENT_SECRET` in `.env`
5. Run any dataHero CLI command — it will open a browser for consent on first use

## Common Tasks

### Add a new voice note
Upload or record in the browser UI. The backend transcribes it with Gemini and generates a title automatically.

### Run CRM scripts (crankHero)
```bash
cd crankHero
python3 scripts/crm.py list          # all deals
python3 scripts/crm.py stale         # deals with no contact > 7 days
python3 scripts/crm.py actions       # pending next actions
python3 scripts/crm.py pipeline      # total pipeline value
```

### Run onboarding ingestion (dataHero)
```bash
cd dataHero
.venv/bin/python -m cli.ingest_onboarding --max-messages 5
```

### Check service health (osHero)
```bash
curl http://localhost:8765/api/status
```

## Tests

```bash
# narrativeHero backend
cd narrativeHero && bash tests/backend/test.sh

# Frontend type check
cd narrativeHero/frontend && npm run check

# crankHero
cd crankHero && bash tests/test_all.sh
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Python 3.9 error | Install 3.11+: `brew install python@3.11` or `pyenv install 3.11` |
| "GOOGLE_API_KEY not set" | Add it to `backend/.env` |
| Port 8000/5173 busy | Run `./stop-dev.sh` or `lsof -ti:8000 \| xargs kill` |
| CORS blocked | Set `ALLOWED_ORIGINS` in `backend/.env` |
| FFmpeg not found | Install it: `brew install ffmpeg` / `apt install ffmpeg` |
| Svelte type errors | 4 pre-existing errors in `uiApp.ts` — safe to ignore |

## Project-Specific Playbooks

Each project has workflows that go beyond code setup. **Read these before doing real work.**

| Project | Playbook | What it covers |
|---------|----------|---------------|
| **crankHero** | `development/email-playbook.md` | Email tone rules, the send script, pre-send checks, CRM integration, threading |
| **crankHero** | `CLAUDE.md` | Full agent instructions including email drafting, CRM conventions |
| **narrativeHero** | `CLAUDE.md` | Verification workflow, content planner rules, script format for TTS |
| **narrativeHero** | `development/north-star.md` | Product direction, design principles |
| **osHero** | `CLAUDE.md` | Daemon behavior, service registry, alerting conventions |

These aren't optional reading. The email playbook, for example, explains why the send script will reject your email (em dashes, duplicates, missing thread IDs) and what tone to use. The code enforces some rules but not all — the playbooks fill the gap.
