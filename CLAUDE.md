# Hero Ecosystem — Bootstrap Guide

When a user opens this project, start the conversation immediately. Don't wait for a prompt. You're onboarding them.

## First: understand the context yourself (silently)

Read these two files before saying anything:
1. `ONBOARDING.md` — the story of why the system exists and how it evolved. This gives you the "why" behind every design decision.
2. `ECOSYSTEM.md` — the technical architecture: who owns what, data flow, communication patterns.

Don't recite these — absorb them so you can answer naturally.

## The code: 4 repos

This onboarding repo has no application code — it's the guide. The actual projects live in separate repositories:

| Project | Repo | What it is |
|---------|------|-----------|
| **narrativeHero** | https://github.com/juandld/narritive-hero | Voice capture, transcription, content planner, orchestrator — FastAPI + SvelteKit |
| **dataHero** | https://github.com/juandld/datahero | Google Sheets/Docs/Gmail bridge, web crawling — Python CLI |
| **crankHero** | https://github.com/juandld/crankHero | Sales CRM, email sending, deal management — Python scripts |
| **osHero** | https://github.com/juandld/osHero | Service health monitor, permission gate, Telegram alerts — Python daemon |

`setup.sh` clones these automatically. If you need to clone them manually:
```bash
git clone https://github.com/juandld/narritive-hero.git narrativeHero
git clone https://github.com/juandld/datahero.git dataHero
git clone https://github.com/juandld/crankHero.git crankHero
git clone https://github.com/juandld/osHero.git osHero
```

Each project has its own `CLAUDE.md` with project-specific rules, and playbooks in `development/playbooks/` with detailed workflow guides.

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

## Keeping up to date

Run this to pull the latest from all repos:
```bash
bash update.sh
```
This pulls every project repo and reports what changed. Run it before starting a session to make sure you're working on current code.

## Contributing back (hivemind)

This ecosystem gets smarter as more people use it. When you or the user discover something — a better way to do things, a missing playbook section, a bug fix, a new feature — contribute it back so everyone benefits.

### How to contribute

1. **Create a branch** in the relevant project:
   ```bash
   cd narrativeHero   # or whichever project
   git checkout -b improve/descriptive-name
   ```

2. **Make the improvement.** This could be:
   - Fixing a bug or adding a feature
   - Updating a playbook with something you learned the hard way
   - Adding a missing rule to CLAUDE.md that would have saved you time
   - Improving the setup script or onboarding flow
   - Writing tests for untested logic

3. **Open a PR**:
   ```bash
   gh pr create --title "Short description" --body "What changed and why"
   ```

### What to contribute (and when)

**During your session**, if you notice any of these, fix them before you finish:

- **A playbook is wrong or incomplete** — you followed it and hit something it didn't mention. Update the playbook.
- **A CLAUDE.md rule is missing** — you figured out a convention by reading code that should have been documented. Add it.
- **The setup script fails on your OS** — fix it and PR so the next person doesn't hit it.
- **You wrote a workaround for something** — if it took you more than 10 minutes to figure out, it belongs in a playbook or in the code.

**Don't contribute**:
- Style-only changes (reformatting, reordering) without substance
- Speculative features nobody asked for
- Changes to core architecture without discussion

### Contribution quality bar

Every PR should make the next person's experience better. Ask: "If I cloned this fresh and hit the area I just changed, would the improvement be obvious?"

## Tone

Be conversational. Match their energy. Short answers for short questions. Stories for curiosity. Don't lecture.

## Verification standard (always applies)

When making code changes:
- Backend: curl the real endpoint on localhost:8000
- Frontend: `npm run check` + verify renders
- Never simulate with `python -c`
- If you can't verify: "NOT VERIFIED — needs server restart"
