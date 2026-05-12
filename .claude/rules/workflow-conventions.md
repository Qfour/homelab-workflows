# Workflow Conventions — Source of Truth

このファイルが **唯一の正典**。CLAUDE.md は概要のみ持ち、詳細な制約は
ここを参照する。

## 設計思想 (Hard Invariants)

| # | ルール |
|---|---|
| I1 | **1 ファイル = 1 責務**。test と build、build と push を混ぜない |
| I2 | 合成は orchestrator (`image-pipeline.yaml` 等) で行う。最小単位側にロジックを足さない |
| I3 | caller は matrix で 1 entry だけ渡す。pipeline は単一イメージを処理 |
| I4 | タグ計算は pipeline 冒頭で 1 回だけ。`sha-tag` / `release-tag` を全 job で共有 |
| I5 | 既存の input / output 名は破壊的変更。`v2` を切るまで rename しない |
| I6 | `default:` を変更したら README の表と齟齬がないこと |
| I7 | 第三者 action は **commit SHA で pin**。moving tag (`@v3` 等) 直接禁止 |
| I8 | 内部 action (`Qfour/qfour-workflows/...`) は `@v1` を使う。`@main` 禁止 |

## Security 規約

| # | ルール |
|---|---|
| S1 | `permissions:` は top-level で `{}` (deny default)、各 job で最小権限のみ宣言 |
| S2 | OIDC を使う。long-lived AWS access key 禁止 |
| S3 | `${{ inputs.* }}` を `run:` に直書きしない。`env:` 経由 `$VAR` 参照 |
| S4 | 全 caller-provided input を最初の step で regex 検証 (下表) |
| S5 | `actions/checkout` は `persist-credentials: false`。`GITHUB_TOKEN` を runner に残さない |
| S6 | 全 job に `timeout-minutes:` を付ける |
| S7 | secret は `secrets:` で受け取り `with:` または `env:` に bind。`run:` に直書きしない |
| S8 | `.env` / `*.key` / `*.pem` / `*.db` をコミットしない。`git add -A` / `git add .` 禁止 |

## Caller input 契約

| Input | Regex |
|---|---|
| `name` | `^[a-z0-9-]+$` |
| `context`, `dockerfile` | `^[A-Za-z0-9._/-]+$` (`..` 不可) |
| `sha-tag` | `^[a-f0-9]{7,40}$` |
| `release-tag` | `^v[A-Za-z0-9._-]+$` |
| `registry` | `^[0-9]{12}\.dkr\.ecr\.[a-z0-9-]+\.amazonaws\.com(\.cn)?$` |
| `aws-region` | `^[a-z]{2}-[a-z]+-[0-9]+$` |
| `severity-at-least` | `critical` \| `high` \| `medium` \| `low` |

## バージョニング

- `@v1` — moving major tag。非破壊変更を受け取る。caller のデフォルト
- `@v1.x.y` — 監査・固定が必要な caller 用の pinned tag
- `@main` — **本番禁止**。CI 開発時のみ
- 破壊的変更を入れる場合は `v2` を切る。`v1` を書き換えない

## 必須シークレット / 変数 (caller 側)

| 名前 | 種別 | 用途 |
|---|---|---|
| `SYSDIG_SECURE_TOKEN` | secret | scan |
| `AWS_ROLE_ARN` | secret | push (OIDC) |
| `ECR_REGISTRY` | variable | push |
| `AWS_REGION` | variable | push |

## 第三者 action allowlist

新規 `uses:` を追加するときはこの owner に限る。それ以外はセキュリティ
レビューを経て本ファイルに追記する。

- `actions/*` (公式)
- `docker/*` (Docker, Inc.)
- `aws-actions/*` (AWS)
- `github/codeql-action`
- `sysdiglabs/scan-action`
- `imranismail/setup-kustomize`
- `Qfour/*` (社内)

## SHA pin の取得方法

```bash
gh api repos/<owner>/<repo>/git/refs/tags/<tag> --jq '.object.sha'
# annotated tag の場合は↑が tag object の SHA を返すので
gh api repos/<owner>/<repo>/git/tags/<sha> --jq '.object.sha'
# で commit SHA を取り直す
```

Dependabot (`.github/dependabot.yaml`) が weekly で更新 PR を出す。
レビュー必須。

## Scope / 影響範囲

| 変更箇所 | 影響 |
|---|---|
| `.github/workflows/<name>.yaml` | その workflow を呼ぶ全 caller |
| `.github/actions/compute-tag/` | `docker-build.yaml`, `image-pipeline.yaml` の両方 |
| `image-pipeline.yaml` の input | 全 caller。破壊的変更は `v2` |
| `.github/workflows/ci.yaml` | このリポ内のみ (self-check) |

## Cross-repo 契約 (caller との接点)

| 接点 | 詳細 |
|---|---|
| `uses:` ref | caller は `Qfour/qfour-workflows/.github/workflows/<name>.yaml@v1` で参照 |
| Image tag 形式 | `${REGISTRY}/falco-ctf-<name>:<git-sha>` または `:<release-tag>` |
| caller required secrets | `sysdig-token`, `aws-role-arn` (push=true 時) |
| OIDC trust | caller の `AWS_ROLE_ARN` の IAM trust policy が GitHub OIDC issuer を許可している前提 |
