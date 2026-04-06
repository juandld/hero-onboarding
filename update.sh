#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Hero Ecosystem — Update all projects
# Pulls latest from all repos, reports what changed.
# Run before starting a session to stay current.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PROJECTS_ROOT="${HERO_PROJECTS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

REPOS=(
  "narrativeHero"
  "dataHero"
  "crankHero"
  "osHero"
)

echo -e "${BOLD}Updating hero ecosystem${NC}"
echo -e "${DIM}Projects root: $PROJECTS_ROOT${NC}"
echo ""

# Update this repo first
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SELF_DIR/.git" ]; then
  echo -e "${CYAN}→${NC} hero-onboarding"
  cd "$SELF_DIR"
  BEFORE=$(git rev-parse HEAD 2>/dev/null)
  git pull --quiet 2>/dev/null || echo -e "  ${YELLOW}!${NC} pull failed (offline?)"
  AFTER=$(git rev-parse HEAD 2>/dev/null)
  if [ "$BEFORE" != "$AFTER" ]; then
    CHANGES=$(git log --oneline "$BEFORE..$AFTER" 2>/dev/null | wc -l | tr -d ' ')
    echo -e "  ${GREEN}✓${NC} Updated ($CHANGES new commits)"
    git log --oneline "$BEFORE..$AFTER" 2>/dev/null | head -5 | sed 's/^/    /'
  else
    echo -e "  ${GREEN}✓${NC} Already up to date"
  fi
  echo ""
fi

# Update each project
for name in "${REPOS[@]}"; do
  dir="$PROJECTS_ROOT/$name"
  if [ ! -d "$dir/.git" ]; then
    echo -e "${YELLOW}!${NC} $name — not found at $dir (run setup.sh first)"
    echo ""
    continue
  fi

  echo -e "${CYAN}→${NC} $name"
  cd "$dir"

  # Check for uncommitted changes
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo -e "  ${YELLOW}!${NC} Has uncommitted changes — pulling anyway (your changes preserved)"
  fi

  BEFORE=$(git rev-parse HEAD 2>/dev/null)
  git pull --quiet 2>/dev/null || echo -e "  ${YELLOW}!${NC} pull failed (offline?)"
  AFTER=$(git rev-parse HEAD 2>/dev/null)

  if [ "$BEFORE" != "$AFTER" ]; then
    CHANGES=$(git log --oneline "$BEFORE..$AFTER" 2>/dev/null | wc -l | tr -d ' ')
    echo -e "  ${GREEN}✓${NC} Updated ($CHANGES new commits)"
    git log --oneline "$BEFORE..$AFTER" 2>/dev/null | head -5 | sed 's/^/    /'

    # Flag playbook or CLAUDE.md changes specifically
    PLAYBOOK_CHANGES=$(git diff --name-only "$BEFORE..$AFTER" 2>/dev/null | grep -E 'playbook|CLAUDE.md|ONBOARDING|ECOSYSTEM' || true)
    if [ -n "$PLAYBOOK_CHANGES" ]; then
      echo -e "  ${YELLOW}!${NC} Playbooks/docs updated — worth reading:"
      echo "$PLAYBOOK_CHANGES" | sed 's/^/    /'
    fi
  else
    echo -e "  ${GREEN}✓${NC} Already up to date"
  fi
  echo ""
done

echo -e "${GREEN}Done.${NC}"
