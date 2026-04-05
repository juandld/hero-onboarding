# Hero Ecosystem — How We Got Here (and How You Can Help)

## The problem we were solving

It started simple: record a voice note, get it transcribed, keep it organized. That's narrativeHero. But once you can reliably capture ideas by voice, you start wanting to do things with them — turn them into content scripts, send emails, track sales deals, manage data from Google Sheets.

Each of those needs became its own project. Not because we wanted complexity, but because each problem has different tools, different rules, and different failure modes. An email sender needs deduplication and tone rules. A web crawler needs headless browsers and batch confirmation. A voice transcriber needs FFmpeg and key rotation. Forcing all of that into one repo would have been worse.

So we split by responsibility:

| Project | Born from the need to... |
|---------|--------------------------|
| **narrativeHero** | Capture voice, transcribe it, organize notes, plan content |
| **dataHero** | Read Google Sheets/Docs/Gmail without building OAuth into every project |
| **crankHero** | Send sales emails with the right tone, track CRM deals, not embarrass yourself |
| **osHero** | Know when things break, restart them, gate risky commands |
| **langHero** | Generate TTS audio, handle multilingual scripts |
| **mediaHero** | Process video, cut clips, work with DaVinci Resolve |

narrativeHero became the hub because it has the web UI and the API. Everything else plugs into it.

## The architecture that emerged

We tried a few patterns before landing on this:

**Data reads go through APIs, not messages.** We used to send hero-comms messages asking "can you read this Sheet for me?" and wait 5 minutes for the dispatch daemon to spin up an agent. Then we built a synchronous API bridge that returns data in 2-5 seconds. Lesson: async messaging is for coordination, sync APIs are for data.

**One queue for all work.** Instead of each project tracking its own tasks, everything goes through narrativeHero's orchestrator queue. You create a task with `target_project: "crankHero"` and the worker routes it. One dashboard shows everything. We learned this after losing track of work scattered across project-specific task boards.

**Permission gate for risky ops.** Automated agents running `git push` or `rm -rf` without a check is how you lose a Saturday. osHero's permission gate evaluates each risky command on its own merit — stateless, one-shot, anti-coercion. It's not perfect, but it's caught real mistakes.

**Playbooks over tribal knowledge.** The email sending script rejects em dashes, blocks duplicate sends, and auto-logs to CRM — but it took a new person 45 minutes to figure out why their email was rejected. Now there's a playbook that explains the "why" in 3 minutes. Every project has playbooks for its non-obvious workflows. See [ECOSYSTEM.md](ECOSYSTEM.md) for the architecture details.

## What you're walking into

You're getting a system that works but has rough edges. Some things that might bug you:

- **The email send script is strict.** It blocks em dashes because David doesn't use them. It blocks 3+ unanswered emails because that's spamming. It requires `--dry-run` first. This feels annoying until you realize it prevented duplicate sends twice in the first week. → [email playbook](../crankHero/development/email-playbook.md)

- **Voice note categorization is keyword-based, not LLM.** We chose deterministic heuristics over LLM calls because we wanted zero API cost for categorization and predictable results. It learns from corrections (move a note to the right folder and it remembers). If you think it should use an LLM, you can — the categorization module is isolated. → [categorization playbook](../narrativeHero/development/playbooks/categorization.md)

- **TTS scripts have rigid formatting rules.** No markdown, no decorative lines, only STEP/PASO markers. This is because the scripts go directly to ElevenLabs — any formatting becomes spoken text. Unchanged wording is cached (free), changed wording costs money. If you're editing a script and only need to fix step 3, leave steps 1, 2, 4 untouched. → [content-tts playbook](../narrativeHero/development/playbooks/content-tts-pipeline.md)

- **The CRM is markdown files with YAML frontmatter.** Not a database, not a SaaS tool. This was intentional — every deal is a file you can grep, diff, and version control. The trade-off is no fancy UI (yet). If that bugs you, building a web interface for it would be a great contribution. → [CRM playbook](../crankHero/development/crm-playbook.md)

- **The permission gate is one-shot.** If your command gets denied, you can't just retry with the same request. You need to provide better context or escalate to a human. This is by design (prevents agents from hammering until approved). → [permission-guard playbook](../osHero/development/playbooks/permission-guard.md)

- **osHero gives up after 3 restart failures.** If a service crashes 3 times, the daemon stops trying and marks it `manual_intervention`. This prevents restart loops from hiding real problems. → [service-supervision playbook](../osHero/development/playbooks/service-supervision.md)

- **dataHero reads Gmail but doesn't send emails.** Email sending moved to crankHero because it needs CRM integration, tone rules, and dedup checks that don't belong in a data tool. If you see `send_gmail_email.py` in dataHero, it's deprecated. → [data-ownership playbook](../dataHero/development/playbooks/data-ownership.md)

## Setting up

### What you need depends on what you want to do

**"I want to capture and play with voice notes"** — just narrativeHero. 10 minutes.

**"I want to work with Google Sheets or send emails"** — narrativeHero + dataHero + crankHero. 20 minutes. Read the data-ownership and email playbooks first.

**"I want the full system running"** — everything. 30 minutes. Read [ECOSYSTEM.md](ECOSYSTEM.md) first so you understand how the pieces connect.

### Step 1: Check your machine

```bash
bash setup.sh --check
```

Tells you what's installed, what's missing, and how to install it on your OS.

### Step 2: Run setup

```bash
bash setup.sh                              # everything
bash setup.sh --project narrativeHero      # just one project
```

The script clones repos, creates virtualenvs, installs dependencies, and sets up `.env` files from templates.

### Step 3: Add your Gemini API key

The one key every path needs:
1. https://aistudio.google.com/app/apikey → Create key
2. Paste into `narrativeHero/backend/.env` as `GOOGLE_API_KEY=...`

### Step 4: Start it

```bash
cd narrativeHero && ./dev.sh
```

Backend at :8000, frontend at :5173. Record a note. It works.

### If you need Google Workspace access (Sheets, Docs, Gmail)

Follow the OAuth setup in the [data-ownership playbook](../dataHero/development/playbooks/data-ownership.md#google-oauth-setup). Takes 5 minutes at the Google Cloud Console.

### If you need Telegram voice capture

See the [telegram playbook](../narrativeHero/development/playbooks/telegram-integration.md). Quick phone testing: `START_FAST_TUNNELS=1 ./dev.sh`.

## Where to find what you need

### Credentials

| What | Where | When you need it |
|------|-------|-----------------|
| Gemini API key | `narrativeHero/backend/.env` | Always |
| Extra Gemini keys | same file, `GOOGLE_API_KEY_1..3` | Under heavy load (rotation) |
| OpenAI key | same file | Fallback transcription |
| Google OAuth | `dataHero/.env` + `.credentials/` | Sheets/Docs/Gmail access |
| Telegram bot token | `narrativeHero/backend/.env` or `osHero/.env` | Voice capture or health alerts |

### Playbooks (the "why" behind the "how")

Each is 2-5 minutes of reading. They explain what the code enforces, what it doesn't, and what'll bite you if you don't know.

| When you're... | Read this | Key insight |
|----------------|-----------|-------------|
| Sending emails | [email-playbook.md](../crankHero/development/email-playbook.md) | Script blocks em dashes, duplicates, 3+ unanswered |
| Managing CRM deals | [crm-playbook.md](../crankHero/development/crm-playbook.md) | Deals auto-create from bookings; log format is `MM/DD: action` |
| Writing content scripts | [content-tts-pipeline.md](../narrativeHero/development/playbooks/content-tts-pipeline.md) | Unchanged wording = cache hit = free |
| Using the task queue | [orchestrator-workflow.md](../narrativeHero/development/playbooks/orchestrator-workflow.md) | Never say "done" without live verification |
| Running data ops | [data-ownership.md](../dataHero/development/playbooks/data-ownership.md) | dataHero reads Gmail but does NOT send |
| Running crawl jobs | [crawl-pipeline.md](../dataHero/development/playbooks/crawl-pipeline.md) | Always dry-run first |
| Processing onboarding | [onboarding-ingestion.md](../dataHero/development/playbooks/onboarding-ingestion.md) | Don't delete processed state or you re-ingest everything |
| Deploying infrastructure | [permission-guard.md](../osHero/development/playbooks/permission-guard.md) | Never retry denied requests with same wording |
| Debugging service health | [service-supervision.md](../osHero/development/playbooks/service-supervision.md) | Daemon gives up after 3 restart failures |
| Investigating categorization | [categorization.md](../narrativeHero/development/playbooks/categorization.md) | System learns from folder corrections |
| Setting up Telegram | [telegram-integration.md](../narrativeHero/development/playbooks/telegram-integration.md) | Fast tunnels for instant phone testing |
| Understanding the big picture | [ECOSYSTEM.md](ECOSYSTEM.md) | APIs for data, messages for coordination |

## Things that could be better (and you can fix)

These are real gaps. If one of them bugs you, the codebase is set up so you can improve it:

- **CRM has no web UI** — deal files are markdown, queried via CLI. A web interface would be a significant improvement.
- **Categorization could use an LLM** — currently keyword-based. The module is isolated if you want to experiment.
- **No unified search across projects** — you can grep, but there's no cross-project search UI.
- **Onboarding ingestion is tightly coupled to Gmail subject format** — a more flexible parser would help.
- **The content planner is Google Sheets** — works but feels fragile. A purpose-built UI might be better.
- **No automated tests for crankHero email rules** — the send script enforces rules in code, but there are no unit tests for the dedup/threading logic.
- **osHero dashboard is localhost-only by default** — needs nginx reverse proxy for external access.
- **Commission sync uses fuzzy company name matching** — could break with unusual company names.

Every project has a `CLAUDE.md` that AI agents read, but those same rules aren't always in the human-readable playbooks. If you find a gap, add to the playbook — that's how the system improves.

## Tests

```bash
cd narrativeHero && bash tests/backend/test.sh    # backend
cd narrativeHero/frontend && npm run check          # frontend types
cd crankHero && bash tests/test_all.sh              # CRM + infrastructure
```

## Troubleshooting

| Problem | Fix | Playbook |
|---------|-----|----------|
| Python 3.9 error | `brew install python@3.11` | — |
| "GOOGLE_API_KEY not set" | Add to `backend/.env` | — |
| Port busy | `./stop-dev.sh` or `lsof -ti:8000 \| xargs kill` | — |
| Email rejected | Probably em dashes or duplicate | [email-playbook](../crankHero/development/email-playbook.md) |
| Permission denied | Resubmit with better context | [permission-guard](../osHero/development/playbooks/permission-guard.md) |
| Service won't restart | Check if it hit 3 failures | [service-supervision](../osHero/development/playbooks/service-supervision.md) |
| CORS blocked | Set `ALLOWED_ORIGINS` in `backend/.env` | — |
| FFmpeg missing | `brew install ffmpeg` / `apt install ffmpeg` | — |
