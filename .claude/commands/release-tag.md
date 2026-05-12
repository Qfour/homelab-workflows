---
description: Cut a v<X.Y.Z> tag and advance the matching v<X> moving major tag. Follow .claude/skills/release-tag.md.
argument-hint: <vX.Y.Z>
---

Release `$ARGUMENTS` (e.g. `v1.2.3`) following the procedure in
[`.claude/skills/release-tag.md`](../skills/release-tag.md).

Hard rules:
- Working tree must be clean. Branch must be `main`.
- Breaking change → bump to `v2.0.0`, do NOT advance `v1`.
- pinned tag (`v1.2.3`) is **immutable** once pushed.
- `v<X>` moving tag is the only `--force` push allowed.
- Always ask for explicit user confirmation before `git push`.
