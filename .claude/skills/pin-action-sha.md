---
name: pin-action-sha
description: How to pin a third-party GitHub Action to a commit SHA from a tag.
type: skill
---

# Third-party action を SHA pin する手順

## いつ使うか

- 新しい `uses:` を追加するとき
- Dependabot PR の SHA を手で確認するとき
- 既存の moving tag (`@v3`) を SHA に変換するとき

## 1. tag → commit SHA に解決

GitHub のタグは **annotated tag** と **lightweight tag** の 2 種類。
GitHub Actions の公式系は annotated が多い。

```bash
OWNER=actions
REPO=checkout
TAG=v6.0.2

# 1 段目: ref を取得
gh api "repos/${OWNER}/${REPO}/git/refs/tags/${TAG}" \
  --jq '{type: .object.type, sha: .object.sha}'
```

出力が:

| `.type` | 意味 | 次に何をするか |
|---|---|---|
| `commit` | lightweight tag。`.sha` がそのまま commit SHA | そのまま使う |
| `tag` | annotated tag。`.sha` は **tag object** の SHA | 続けて `git/tags/<sha>` を引く |

```bash
# 2 段目 (annotated tag のとき): tag object → commit SHA
gh api "repos/${OWNER}/${REPO}/git/tags/<sha-from-step-1>" \
  --jq '.object.sha'
```

## 2. ワンライナー

```bash
resolve_sha() {
  local repo="$1" tag="$2"
  local t s
  read t s < <(gh api "repos/${repo}/git/refs/tags/${tag}" \
    --jq '"\(.object.type) \(.object.sha)"')
  if [ "$t" = "tag" ]; then
    gh api "repos/${repo}/git/tags/${s}" --jq '.object.sha'
  else
    echo "$s"
  fi
}
resolve_sha actions/checkout v6.0.2
# → de0fac2e4500dabe0009e67214ff5f5447ce83dd
```

## 3. workflow に書く

```yaml
- uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
  with:
    persist-credentials: false
```

`# v<semver>` コメントは **必須**。Dependabot がここを読んで新バージョン
を提案する。

## 4. Dependabot との連携

`.github/dependabot.yaml` で `package-ecosystem: github-actions` を
設定済み。weekly で SHA 更新 PR が来る。

- PR のラベル: `dependencies`, `github-actions`
- minor/patch はグルーピング (`actions-minor`)
- レビュー時に PR の "Changed files" で `<old-sha> # vX.Y.Z` →
  `<new-sha> # vX.Y.Z+1` の差分を確認

## やってはいけないこと

- `@v3` のような moving tag を SHA なしで使う (供給チェーン攻撃の入口)
- `@main` / `@master` のような branch ref を使う (タグ pinning の効果が消える)
- `# v3` のような major-only コメントを書く (Dependabot が patch を見落とす)
- SHA を 7 文字に切る (`@1234567`)。**40 char full SHA** を必ず使う
- コメントなしで SHA だけ書く (人間が読めない)

## allowlist (本リポで認める owner)

`.claude/rules/workflow-conventions.md` に列挙。新規 owner を加えるときは
`/architect` でセキュリティ判断を仰ぐ。
