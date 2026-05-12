---
description: Scaffold a new minimal reusable workflow (single responsibility). Follow .claude/skills/add-workflow.md.
argument-hint: <workflow-name> "<purpose-1-line>"
---

Scaffold a new reusable workflow from `$ARGUMENTS` following the
procedure in [`.claude/skills/add-workflow.md`](../skills/add-workflow.md).

Key rules:
- 1 file = 1 responsibility (no mixing test/build/push).
- Match existing input/output naming (see `.claude/rules/workflow-conventions.md`).
- top-level `permissions: {}`, per-job minimum grants.
- Every job has `timeout-minutes:`.
- All caller inputs are regex-validated in the first step.
- Pin third-party `uses:` to commit SHA with `# v<semver>` comment.
- Update the README Workflows table.

After scaffolding, run `/validate` to confirm actionlint passes.
