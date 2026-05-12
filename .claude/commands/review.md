---
description: Pre-PR review — runs workflow-reviewer (Opus, design) + security-reviewer (Opus, security) + actionlint-runner (Haiku, syntax) as parallel subagents and merges the verdicts.
argument-hint: [optional focus area]
---

Run THREE subagents in a **single message with three parallel Agent
tool calls** so they execute concurrently. Do NOT run them
sequentially.

1. **`workflow-reviewer` subagent** (Opus) — Design: 1-responsibility,
   input/output compatibility, naming, README sync, internal action
   `@v1`, third-party SHA pinning.
2. **`security-reviewer` subagent** (Opus) — Security: supply-chain
   pinning, untrusted input handling, `permissions:` minimization,
   OIDC, secret leakage, timeouts, `persist-credentials: false`.
3. **`actionlint-runner` subagent** (Haiku) — Mechanical: actionlint
   syntax / type / shellcheck output, grouped by file.

Pass any focus area to all three: $ARGUMENTS

After ALL THREE complete, present a **merged report**:

```
## Overall Verdict
APPROVE / APPROVE WITH NITS / REQUEST CHANGES
(blocked if any agent returns REQUEST CHANGES, or actionlint has
violations)

## Blocking (must-fix)
<combined list, prefixed with [design], [security], or [lint]>

## Non-blocking
<combined list>

## Nits
<combined list>

## Coverage
- Design review: <verdict from workflow-reviewer>
- Security review: <verdict from security-reviewer>
- actionlint: <clean / N violations>
```

Do NOT implement fixes. Surface findings only. Match the user's language.
