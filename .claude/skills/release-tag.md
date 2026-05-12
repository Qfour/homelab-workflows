---
name: release-tag
description: Cut a vX.Y.Z release tag and advance the matching vX moving major tag.
type: skill
---

# Release タグ発行手順

## 1. 前提

- working tree が clean (`git status` で何も出ない)
- 現在のブランチが `main`
- ローカル `main` が `origin/main` と同じ commit (`git fetch && git status`)
- 破壊的変更があるか **事前に判断** (input/output rename, default 変更)

破壊的変更 → 新メジャー (`v2.0.0` 等)。`v1` を進めない。

## 2. バージョンを決める

```bash
# 直近のタグ
git tag --list 'v*' --sort=-v:refname | head -5
```

SemVer:
- patch (`v1.0.1`): docs, internal refactor, action SHA bump
- minor (`v1.1.0`): 新 input 追加 (default 値あり、後方互換)、新 workflow 追加
- major (`v2.0.0`): input/output rename, default 変更、workflow 削除

## 3. pinned tag を切る

```bash
VER=v1.2.3
git tag "${VER}"
```

## 4. moving major tag を進める

```bash
MAJOR=$(echo "${VER}" | sed -E 's/^(v[0-9]+)\..*/\1/')
git tag -f "${MAJOR}"
```

`-f` (force) は **moving tag のみ** 許可。pinned tag (`v1.2.3`) は
絶対に書き換えない。

## 5. ユーザー承認 → push

```bash
echo "About to push:"
echo "  git push origin ${VER}"
echo "  git push origin ${MAJOR} --force"
```

ユーザーに見せて **OK を得てから** 実行する。

```bash
git push origin "${VER}"
git push origin "${MAJOR}" --force
```

## 6. リリースノート

```bash
gh release create "${VER}" --generate-notes
```

PR 一覧から自動生成される。手動で要約を追加してもよい。

## 7. caller への通知 (必要なら)

破壊的変更を含む `vN` 発行時:

- caller repo (`falco-ctf-app`, `falco-ctf-platform`) の所有者に通知
- マイグレーション手順を release notes に書く
- 旧 `v(N-1)` は当面残す (deprecation 期間)

## チェックリスト

- [ ] working tree clean
- [ ] branch = main、origin と同期
- [ ] 破壊的変更の有無を判断
- [ ] pinned tag (`vX.Y.Z`) 作成
- [ ] moving major (`vX`) を force update
- [ ] ユーザー承認後に push
- [ ] `gh release create --generate-notes`
- [ ] (major bump 時) caller に通知

## やってはいけないこと

- `main` に `--force` push する
- pinned tag を書き換える / 削除する
- 破壊的変更を含んだまま `v1` を進める
- ユーザー承認なしで `git push` する
- 承認なく `gh release create` で publish する (draft で確認したい場合は `--draft`)
