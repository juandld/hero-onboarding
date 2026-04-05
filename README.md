# Hero Ecosystem

A system for capturing voice notes, managing sales, and automating workflows — built as a family of projects that work together.

## Get started

1. Open [Claude Code](https://claude.ai/code)
2. Paste this:

```
git clone https://github.com/juandld/hero-onboarding.git && cd hero-onboarding
```

3. Then say: **"start this up"**

Claude will walk you through what the system does, ask what you're interested in, set up what you need, and help you get running.

## What's inside

- **setup.sh** — detects your OS, installs dependencies, clones projects, configures everything
- **ONBOARDING.md** — the story of how this system evolved and why it's built this way
- **ECOSYSTEM.md** — technical architecture: who owns what, how data flows
- **CLAUDE.md** — instructions for AI agents bootstrapping the system

## The projects

| Project | What it does |
|---------|-------------|
| [narrativeHero](https://github.com/juandld/narritive-hero) | Voice capture, transcription, content planner — the hub |
| [dataHero](https://github.com/juandld/datahero) | Google Sheets/Docs/Gmail, web crawling |
| [crankHero](https://github.com/juandld/crankHero) | Sales CRM, email sending, deal management |
| [osHero](https://github.com/juandld/osHero) | Service health, permission gate, alerts |
