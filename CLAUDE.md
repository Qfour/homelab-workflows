# qfour-workflows — Claude 開発ガイド

このリポジトリは Qfour 配下の全リポジトリで共有する **再利用可能 GitHub
Actions ワークフロー** を最小単位で集めたもの。Claude Code はこの
ガイドと `.claude/rules/*.md` を **正典** として動作する。

## まず読むファイル

| 用途 | ファイル |
|---|---|
| モデル使い分け / `/architect`・`/commit` の運用 | [`.claude/rules/model-routing.md`](.claude/rules/model-routing.md) |
| 変更パターン別フロー / 必須ゲート | [`.claude/rules/dev-flow.md`](.claude/rules/dev-flow.md) |
| Hard invariants / Security 規約 / Caller 入力契約 | [`.claude/rules/workflow-conventions.md`](.claude/rules/workflow-conventions.md) |
| 利用方法 / バージョニング | [`README.md`](README.md) |

詳細はそれぞれの正典を参照すること。**CLAUDE.md は概要のみ持つ**。
このファイルと正典で矛盾したら、正典側を信じて CLAUDE.md を直す。

## 一行要約

1. **GitHub Flow**: `main` 直接コミット禁止。`<type>/<slug>` の short-lived branch を切り、PR で squash merge。
2. 最小単位 1 責務、合成は orchestrator (`image-pipeline.yaml`) で。
3. 第三者 action は **commit SHA で pin**。内部 action は `@v1`。
4. `${{ inputs.* }}` を `run:` に直書きしない。`env:` 経由 `$VAR`。
5. 全 input を最初の step で regex 検証。
6. `permissions: {}` を top-level、各 job で最小権限。
7. caller を壊さないため input/output rename は `v2` を切るまで禁止。
8. レビューは `/review` (Opus × 2 並列 + Haiku) を必ず通す。
9. commit は `/commit` (Haiku)、PR は `gh pr create`、merge は squash + branch 削除。

## ディレクトリ早見

```
.github/
├── workflows/         # 再利用可能ワークフロー (workflow_call)
│   ├── go-test.yaml
│   ├── kustomize-lint.yaml
│   ├── docker-build.yaml
│   ├── sysdig-scan.yaml
│   ├── image-push.yaml
│   ├── image-pipeline.yaml  # build → scan → push orchestrator
│   └── ci.yaml              # self-check (actionlint)
├── actions/compute-tag/     # 共有 composite action
├── dependabot.yaml          # weekly action SHA bump
└── actionlint.yaml          # lint config

.claude/
├── settings.json            # default Sonnet + permissions + hooks
├── rules/                   # 正典 (詳細はここ)
├── agents/                  # subagents (opus/sonnet/haiku)
├── commands/                # slash command (薄い委譲レイヤー)
└── skills/                  # how-to procedures

scripts/
├── claude-hook-postedit.sh  # PostEdit: actionlint
└── claude-hook-stop.sh      # Stop: sanity summary
```

## Claude Code の使い方

| 場面 | コマンド | モデル |
|---|---|---|
| 設計を聞きたい | `/architect <topic>` | Opus |
| 普通の workflow 編集 | (main session のまま) | Sonnet |
| pre-PR レビュー | `/review` | Opus × 2 + Haiku |
| セキュリティ深掘り | `/security-audit` | Opus |
| actionlint だけ | `/validate` | Haiku |
| 新規 workflow scaffold | `/add-workflow <name> "<purpose>"` | Sonnet |
| commit | `/commit` | Haiku |
| release タグ | `/release-tag vX.Y.Z` | Sonnet |

詳細フローは [`.claude/rules/dev-flow.md`](.claude/rules/dev-flow.md)。
