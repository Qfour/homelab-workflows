---
description: Delegate to the Haiku actionlint-runner subagent for a mechanical lint of all reusable workflows.
argument-hint: [unused]
---

Use the `actionlint-runner` subagent (Haiku) to run actionlint over
`.github/workflows/` and sanity-check `.github/actions/*/action.yaml`
via `yq`.

The agent returns either `✅ actionlint: clean` or a violation list
grouped by file. No fixes are proposed — that's a separate step.
