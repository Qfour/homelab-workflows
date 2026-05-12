---
name: add-workflow
description: Step-by-step procedure for adding a new minimal reusable workflow to .github/workflows/
type: skill
---

# 新規 reusable workflow 追加手順

## 1. 名前と責務を決める

| 良い例 | 悪い例 |
|---|---|
| `helm-lint.yaml` (lint だけ) | `helm-deploy.yaml` (lint + apply 混在) |
| `gosec-scan.yaml` (scan だけ) | `go-ci.yaml` (test + scan + build 混在) |

1 file = 1 責務。混ぜたくなったら orchestrator (`image-pipeline.yaml`)
で合成する。

## 2. ファイルを作る

```bash
NAME=helm-lint  # 例
touch .github/workflows/${NAME}.yaml
```

## 3. テンプレ

```yaml
name: <Human Name> (reusable)

on:
  workflow_call:
    inputs:
      # 必須 input
      foo:
        description: ...
        required: true
        type: string
      # 任意 input
      bar:
        type: string
        default: ""
    secrets:
      # 必要なら
      some-token:
        required: true
    outputs:
      # caller に渡したい値
      result:
        value: ${{ jobs.main.outputs.result }}

permissions: {}

jobs:
  main:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    permissions:
      contents: read
    outputs:
      result: ${{ steps.run.outputs.result }}
    env:
      FOO: ${{ inputs.foo }}
      BAR: ${{ inputs.bar }}
    steps:
      - name: Validate inputs
        run: |
          set -euo pipefail
          if [[ ! "$FOO" =~ ^[a-z0-9-]+$ ]]; then
            echo "::error::foo must match ^[a-z0-9-]+$"; exit 1
          fi
      - name: Checkout
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
        with:
          persist-credentials: false
      - name: Run
        id: run
        run: |
          set -euo pipefail
          # 実処理
          echo "result=ok" >> "$GITHUB_OUTPUT"
```

## 4. 入力検証の regex を決める

`.claude/rules/workflow-conventions.md` の "Caller input 契約" の表に
追記する。既存パターンを優先（`name`, `context`, `dockerfile` 等）。

## 5. 第三者 action を追加する場合

allowlist (`actions/`, `docker/`, `aws-actions/`, `github/codeql-action`,
`sysdiglabs/scan-action`, `imranismail/setup-kustomize`, `Qfour/`) に
入っているか確認。入っていなければ `/architect` でセキュリティ判断を
仰ぐ。

SHA pin の取得 (詳しくは `pin-action-sha.md`):

```bash
gh api repos/<owner>/<repo>/git/refs/tags/<tag> --jq '.object.sha'
```

annotated tag なら↑が tag object SHA を返すので、続けて:

```bash
gh api repos/<owner>/<repo>/git/tags/<sha> --jq '.object.sha'
```

`uses:` には `<sha> # v<semver>` の形で書く。

## 6. README を更新

```diff
| File | Purpose | Callers |
|---|---|---|
| `go-test.yaml` | ... | ... |
+| `helm-lint.yaml` | Helm chart lint | standalone use |
```

## 7. 動作確認

```bash
# ローカル
actionlint -no-color

# Claude セッションから
/validate
/review
```

## 8. コミットして PR

```bash
/commit
# review 通過後
gh pr create --title "feat(workflows): add helm-lint" --body "..."
```

## チェックリスト

- [ ] 1 file = 1 責務になっている
- [ ] `permissions: {}` を top-level に宣言
- [ ] 全 job に `timeout-minutes:`
- [ ] 全 input を regex 検証 (`Validate inputs` step)
- [ ] `run:` に `${{ inputs.* }}` を直書きしていない (env 経由)
- [ ] `actions/checkout` は `persist-credentials: false`
- [ ] 第三者 action は SHA pin + `# v<ver>` コメント
- [ ] README の Workflows テーブルに追記
- [ ] actionlint clean
