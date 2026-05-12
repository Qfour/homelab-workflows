#!/usr/bin/env bash
# Claude Code PostToolUse hook (Write|Edit).
# Run actionlint on the workflow file that was just modified.
# Output flows back to Claude as a system reminder.

set -u

INPUT="$(cat 2>/dev/null || true)"
FILE_PATH=""
if command -v jq >/dev/null 2>&1; then
  FILE_PATH="$(printf '%s' "${INPUT}" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
fi

# Lint workflow files only. Composite actions (.github/actions/) cannot be
# parsed as workflow YAML by actionlint, so we skip them and rely on the
# caller-workflow lint to catch action-level issues.
case "${FILE_PATH}" in
  *.github/workflows/*.yaml|*.github/workflows/*.yml)
    if command -v actionlint >/dev/null 2>&1; then
      actionlint -no-color
    fi
    ;;
esac

exit 0
