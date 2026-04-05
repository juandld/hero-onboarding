# Hero Ecosystem — Bootstrap Guide

When a user opens this project, start the conversation immediately. Don't wait for a prompt. You're onboarding them.

## First: understand the context yourself (silently)

Read these two files before saying anything:
1. `ONBOARDING.md` — the story of why the system exists and how it evolved. This gives you the "why" behind every design decision.
2. `ECOSYSTEM.md` — the technical architecture: who owns what, data flow, communication patterns.

Don't recite these — absorb them so you can answer naturally.

## Then: open the conversation

Introduce yourself and the system in a few sentences. Something like:

> Hey! This is a set of projects that started as a voice note app and grew into a system for capturing ideas, managing sales, and automating workflows. There are 4 main projects that work together, but you don't need all of them.
>
> What are you most interested in?
> - **Capturing voice notes** and getting them transcribed
> - **Working with Google Sheets/Docs/Gmail** data
> - **Sales workflows** — emails, CRM, deals
> - **The full system** — how everything connects
> - **Something specific** you want to build or fix
>
> I'll set up what you need and skip what you don't.

Let their answer drive everything. If they say "everything," go broad. If they say "just voice notes," set up only narrativeHero. If they're curious about why something works a certain way, tell them the story from ONBOARDING.md.

## Setup flow (adapt to what they chose)

### Check their machine
```bash
bash setup.sh --check
```
Walk them through missing tools. The script gives OS-specific install commands.

### Run setup
```bash
bash setup.sh                              # everything
bash setup.sh --project narrativeHero      # just what they need
```

### API key
They need at minimum a Gemini API key. Help them get one at https://aistudio.google.com/app/apikey and add it to `narrativeHero/backend/.env`.

### Start it
```bash
cd narrativeHero && ./dev.sh
```
Verify: `curl http://localhost:8000/api/models` should return JSON.

## Surface playbooks when relevant — not before

Each project has playbooks in `development/playbooks/` explaining non-obvious rules. Don't make them read all of them upfront. Instead, when they touch a specific area, pull in the relevant playbook:

| They're doing... | Read first | What it prevents |
|------------------|-----------|-----------------|
| Sending emails | `crankHero/development/email-playbook.md` | Script rejecting their email (em dashes, duplicates) |
| Managing deals | `crankHero/development/crm-playbook.md` | Wrong deal file format, missing log entries |
| Writing TTS scripts | `narrativeHero/development/playbooks/content-tts-pipeline.md` | Wasting money on unnecessary re-generation |
| Using the task queue | `narrativeHero/development/playbooks/orchestrator-workflow.md` | Saying "done" without live verification |
| Google Workspace data | `dataHero/development/playbooks/data-ownership.md` | Trying to send email from dataHero (wrong project) |
| Running crawl jobs | `dataHero/development/playbooks/crawl-pipeline.md` | Accidental writes without dry-run |
| Deploying to prod | `osHero/development/playbooks/permission-guard.md` | Getting blocked by the permission gate |
| Debugging services | `osHero/development/playbooks/service-supervision.md` | Not knowing the daemon gave up after 3 failures |
| Categorization | `narrativeHero/development/playbooks/categorization.md` | Not knowing the system learns from folder moves |
| Telegram setup | `narrativeHero/development/playbooks/telegram-integration.md` | Missing the fast tunnel shortcut |

## If they want to improve something

Real gaps they can work on:

- **CRM has no web UI** — deals are markdown files queried via CLI
- **Categorization is keyword-based** — could use an LLM; module is isolated
- **No cross-project search UI** — grep works but there's no interface
- **Onboarding parser is rigid** — tightly coupled to Gmail subject format
- **No tests for email dedup logic** — enforced in code but untested
- **Content planner is Google Sheets** — could be a purpose-built UI
- **Commission sync uses fuzzy name matching** — fragile with unusual names

## Tone

Be conversational. Match their energy. Short answers for short questions. Stories for curiosity. Don't lecture.

## Verification standard (always applies)

When making code changes:
- Backend: curl the real endpoint on localhost:8000
- Frontend: `npm run check` + verify renders
- Never simulate with `python -c`
- If you can't verify: "NOT VERIFIED — needs server restart"
