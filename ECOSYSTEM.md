# Hero Ecosystem Architecture

## Who owns what

| Project | Owns | Does NOT own |
|---------|------|-------------|
| **narrativeHero** | Voice notes, content planner, orchestrator queue, TTS pipeline, dashboard | Email sending, CRM, web crawling |
| **dataHero** | Google Sheets/Docs/Gmail READ, web crawling, data ingestion | Email sending, voice notes |
| **crankHero** | Email sending, CRM deals, sales materials, landing pages | Data fetching, transcription |
| **osHero** | Permission gate, service health, Telegram alerts, OAuth | Business logic, data ops |
| **langHero** | Transcription, TTS, language generation | Storage, orchestration |
| **mediaHero** | Video/audio processing, DaVinci Resolve | Web apps, data ops |

## Data access pattern

**Rule: Use APIs for data, hero-comms for coordination.**

```
Other heroes ──API──> narrativeHero ──bridge──> dataHero ──OAuth──> Google
                      (2-5 sec sync)           (subprocess)        (Sheets/Docs/Gmail)
```

Don't use hero-comms to ask for data. Call the API directly:

```bash
# Read a Google Sheet (any hero can call this)
curl -X POST http://localhost:8000/api/google/sheets/fetch \
  -H "Content-Type: application/json" \
  -d '{"url":"https://docs.google.com/spreadsheets/d/..."}'

# Read a Google Doc
curl -X POST http://localhost:8000/api/google/docs/read \
  -H "Content-Type: application/json" \
  -d '{"doc_url":"https://docs.google.com/document/d/..."}'
```

## Cross-project task routing

Use the orchestrator queue to dispatch work to other heroes:

```bash
curl -X POST http://localhost:8000/api/orchestrator/queue/create \
  -H "Content-Type: application/json" \
  -d '{"title":"Task","description":"Context","target_project":"crankHero"}'
```

Valid targets: narrativeHero, crankHero, dataHero, osHero, langHero, mediaHero.
Shows on dashboard immediately. Worker auto-routes to the target project.

## Hero-comms protocol

File-based messaging for notifications and coordination (NOT data reads).

**Location**: `/opt/projects/.hero-comms/`

**Message format** (markdown files in `inbox/<project>/`):
```markdown
# Short title

- **From**: sourceProject
- **To**: targetProject
- **Priority**: low | normal | urgent
- **Status**: pending | acknowledged | done
- **Created**: 2026-04-05 22:00 UTC

## What
1-3 sentences

## Context
File paths, links, code snippets

## Action Required
Concrete steps or "None - informational only"

## Outcome
(Filled by receiver when done)
```

**Status lifecycle**: `pending` (unread) -> `acknowledged` (working on it) -> `done` (completed with Outcome filled)

## Permission gate

For risky commands (git push, rm, chmod, installs), use osHero's gate:

```bash
python /opt/osHero/permission_gate.py \
  --requester myProject \
  --intent "Why I need this" \
  --cmd "the exact command" \
  --sandbox-permissions require_escalated \
  --justification "Context" \
  --workdir "/abs/path"
```

Exit codes: 0 = approved, 2 = needs review, 3 = denied. Never retry denied requests with the same wording.

## Dispatch system

**Auto-dispatch daemon** polls hero-comms inboxes every 60 seconds and spawns Claude agents for pending messages.

- Systemd service: `hero-dispatch.service`
- Max concurrent: 3 dispatches
- Dedup: `.dispatch-ledger.jsonl` prevents duplicate work across sessions
- Agents MUST check the ledger before acting and record their actions after

## Design principles

1. **Single source of truth** — orchestrator queue DB for all work items
2. **API over messaging** — sync calls (2-5s) beat async relay (5+ min) for reads
3. **Every dispatch visible** — if work is happening, it shows on the dashboard
4. **Permission gate for risky ops** — one-shot, stateless, anti-coercion
5. **File-based comms** — durable, auditable, no external dependencies
