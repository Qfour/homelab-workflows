---
description: Delegate to the Opus security-reviewer subagent for a deep security review of the working branch. Anchored to the qfour-workflows threat model (supply chain, secret leakage, untrusted input injection, token retention).
argument-hint: [optional focus area]
---

Use the `security-reviewer` subagent (Opus) to audit the changes on
this branch against the qfour-workflows threat model. The agent loads
the threat model from its own definition and the project conventions
from CLAUDE.md / .claude/rules/.

If the user supplied a focus area (a specific threat, a file, a
service), pass it forward: $ARGUMENTS

The agent will produce severity-ranked findings (CRITICAL / HIGH /
MEDIUM / LOW) with concrete exploit sketches and suggested mitigations.
Do not write exploit code or fixes — surface the findings and let the
user decide.
