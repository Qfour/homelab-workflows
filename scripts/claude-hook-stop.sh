#!/usr/bin/env bash
# Claude Code Stop hook.
# End-of-session sanity check: actionlint summary + dirty file count.
# Designed to be informational; never blocks the session.

set -u

# 1. actionlint over all workflows.
if command -v actionlint >/dev/null 2>&1; then
  if ! actionlint -no-color; then
    echo ""
    echo "::warning::actionlint reported issues. Run /validate or 'actionlint -no-color' before committing."
  fi
fi

# 2. Dirty file summary.
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "${DIRTY}" -gt 0 ]; then
    UNSTAGED=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    echo "::notice::working tree: ${DIRTY} dirty (${STAGED} staged, ${UNSTAGED} unstaged). Use /commit when ready."
  fi
fi

exit 0
