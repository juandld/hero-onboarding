# Hero Ecosystem — Agent Bootstrap Instructions

You've been given this repo to set up the Hero project ecosystem. Your user wants the full system running on their machine.

## What this is

A family of 4 repos that work together. narrativeHero is the hub. The others plug into it.

## Step 1: Understand what you're setting up

Read `ONBOARDING.md` in this repo — it explains why the system is built this way and what each project does. Read the "The problem we were solving" and "The architecture that emerged" sections. This context matters because the setup decisions flow from it.

Then read `ECOSYSTEM.md` for the technical architecture: who owns what, how data flows, how projects communicate.

## Step 2: Run the setup script

```bash
bash setup.sh --check
```

This detects the OS, checks for required tools (Python 3.10+, Node 18+, FFmpeg, Git), and tells you exactly what to install. If anything is missing, install it using the commands the script suggests, then re-run.

Once dependencies are satisfied:

```bash
bash setup.sh
```

This clones all 4 repos (narrativeHero, dataHero, crankHero, osHero) side by side in the current directory, creates Python virtualenvs, installs dependencies, and creates `.env` files from templates.

## Step 3: Configure API keys

The minimum viable setup needs ONE key:

1. Ask the user for their Gemini API key (or help them get one at https://aistudio.google.com/app/apikey)
2. Add it to `narrativeHero/backend/.env`:
   ```
   GOOGLE_API_KEY=their-key-here
   ```

For full setup (email, Google Sheets, Telegram), see the credentials table in `ONBOARDING.md`.

## Step 4: Start narrativeHero

```bash
cd narrativeHero && ./dev.sh
```

This starts the backend (:8000) and frontend (:5173). Verify:
- Backend: `curl http://localhost:8000/api/models` should return JSON
- Frontend: open http://localhost:5173 in browser

## Step 5: Verify the system works

Record or upload a voice note in the UI. It should transcribe automatically.

## What to read before modifying each project

Each project has playbooks in `development/playbooks/` (or `development/` for crankHero). These document the non-obvious rules that will trip you up. Key ones:

- **Sending emails?** Read `crankHero/development/email-playbook.md` FIRST. The send script blocks em dashes, duplicates, and requires dry-run.
- **Writing TTS scripts?** Read `narrativeHero/development/playbooks/content-tts-pipeline.md`. Strict format rules, caching strategy.
- **Using the task queue?** Read `narrativeHero/development/playbooks/orchestrator-workflow.md`. Must verify in running system, never simulate.
- **Working with data/Google?** Read `dataHero/development/playbooks/data-ownership.md`. dataHero reads Gmail but does NOT send.

## Verification standard

A task is NOT done until verified in the running system:
- Backend changes: curl the real endpoint on localhost:8000
- Frontend changes: `npm run check` + verify renders
- Never use `python -c` to simulate — hit the real server
- If you can't verify, say "NOT VERIFIED — needs server restart"
