## Summary
<!-- 1-3 bullet points describing what this PR does -->
-

## Why
<!-- Motivation. Link issues / related repos if relevant. -->

## Caller impact
<!-- Mark one. Breaking changes require a v2 tag (NOT bumping v1). -->
- [ ] **Non-breaking** — caller continues to work with `@v1`. Next release: `v1.x.y` (patch/minor).
- [ ] **Breaking** — input/output rename, default change, or workflow removal. Next release: `v2.0.0`. Title prefixed `[breaking]`.

## Test plan
<!-- Local pre-merge gates. Check what was run. -->
- [ ] `/validate` (actionlint) clean
- [ ] `/review` — workflow + security + lint all APPROVE
- [ ] caller workflows (`falco-ctf-app`, `falco-ctf-platform`) still resolve `@v1` correctly
- [ ] Manual smoke: <!-- describe, or "N/A" -->

## Security checklist (delete if N/A)
- [ ] New third-party `uses:` is pinned to commit SHA with `# v<semver>` comment
- [ ] New third-party `uses:` owner is in the allowlist (`.claude/rules/workflow-conventions.md`)
- [ ] No `${{ inputs.* }}` interpolated directly in `run:` scripts
- [ ] All caller-provided inputs validated by regex
- [ ] `permissions:` is minimum
- [ ] All jobs have `timeout-minutes:`

## Notes for the reviewer
<!-- Anything non-obvious from the diff -->
