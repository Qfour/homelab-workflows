# Model routing for Claude Code

qfour-workflows での Claude Code 利用時の、モデルとサブエージェントの
使い分けルール。default は Sonnet で、目的別に Opus / Haiku のサブ
エージェントへ委譲する。

## TL;DR

| やりたいこと | 何を使うか | モデル |
|---|---|---|
| 設計提案・トレードオフ分析・原因調査 | `/architect <topic>` | **Opus** |
| 仕様が明確な workflow YAML 実装・編集 | main session のまま | **Sonnet** (default) |
| pre-PR レビュー (設計 + セキュリティ + lint 並走) | `/review` | **Opus × 2 + Haiku** |
| セキュリティ深掘りレビュー | `/security-audit` | **Opus** |
| actionlint だけ走らせる | `/validate` | **Haiku** |
| git commit | `/commit` | **Haiku** |
| 広範な探索 (>3 grep 相当) | 組込 `Explore` agent | Sonnet |

## なぜサブエージェントに分けるのか

サブエージェントは **独立 context** で動く。効果は 2 つ:

1. **コスト最適化** — 定型作業 (git commit, actionlint 実行) を Haiku に
   振り、深い推論 (設計, セキュリティレビュー) を Opus に振る。中間
   (workflow 編集) は default Sonnet が担当。
2. **main context 保護** — `git diff` の長い出力やレビュー agent の
   長考を main session に持ち込まない。次のターンで cache を再利用
   しやすい。

## 主要な切り分けポイント

### 「提案 / 検討 / 設計」キーワード → `/architect`

例: 「再利用可能 workflow をもう一段抽象化したい」「matrix の組み方は
今の caller 設計で OK?」「`compute-tag` の release-tag 抽出をもっと
robust にできないか?」

ユーザーが提案を求めているフェーズで実装しない。`/architect` は
コードを書かず、option 列挙 + 推奨 + 将来の signposts を返す。
承認後の実装は **main Sonnet session に戻って実施**。再委譲しない
(planning context が main にあるため二度払いになる)。

### 「コミット」依頼 → 無条件で `/commit`

git status / diff / log の出力で main context が汚れるのを避ける。
半定型作業なので Haiku で十分。`/commit` は push しない。

### 「actionlint だけ走らせて」「lint 通って?」 → `/validate`

機械的な lint 実行。Haiku で十分。出力を main に持ち込まずに結果だけ
要約させる。

### 「PR 出す前にレビューして」→ `/review`

workflow-reviewer (設計) と security-reviewer (脆弱性) を **並列 Opus** で、
actionlint-runner (構文) を Haiku で走らせ、結果をマージする。

### セキュリティ視点だけ深く → `/security-audit`

permissions / OIDC / SHA pin / 入力検証 など qfour-workflows 固有の
threat model に anchored したレビューを Opus で実行。

## やってはいけないこと

- **委譲の二度払い**: `/architect` で提案 → 受け取った推奨を別の
  agent に投げ直す、はやらない。提案後の実装は main session のまま。
- **3 行の編集を Haiku agent に投げる**: agent spawn のオーバーヘッド
  (数百トークン) があるので、本当に **routine workflow** にだけ使う。
  単発のファイル編集は main session で直接やる。
- **`/architect` でコードを書かせる**: 設計エージェントの責務違反。
  実装させたいときは main session に戻る。
- **`/commit` で push する**: commit までで止まる仕様。push は人間
  の判断で。
- **`/review` を sequential に走らせる**: 必ず 1 メッセージ内で複数
  Agent tool を並列起動する。

## モデルの選定理由

| モデル | 強み | ここでの役割 |
|---|---|---|
| **Opus 4.7** | 多択判断、長考、cross-file 関連性、トレードオフ言語化 | 設計・レビュー (低頻度・高価値) |
| **Sonnet 4.6** | 明確な仕様の実装、テスト生成、tool 使用 | 日常的な workflow 編集 (高頻度・中価値) |
| **Haiku 4.5** | 短いコンテキストで I/O 重視の定型作業を高速に | git commit、actionlint、簡単な rename (高頻度・低価値) |

将来モデルが更新されたら `.claude/agents/*.md` の `model:` フィールド
を見直す。`opus` / `sonnet` / `haiku` のエイリアスを使っているので、
Claude Code 側のエイリアス解決が自動で最新を指す想定。
