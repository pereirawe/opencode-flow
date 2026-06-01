# ブランチ戦略

## 命名規則

```
issue-<id>-<slug>
```

- `<id>`: `known_issues.md` またはリモートトラッカーの Issue 番号
- `<slug>`: ハイフン区切りの小文字説明

例：
- `issue-3-weak-url-validation`
- `issue-12-add-analytics-endpoint`

## ワークフロー

1. ベースブランチを選択（デフォルトまたは PM プロモーション時に選択した既存ブランチ）
2. ベースブランチをチェックアウトしてプル
3. ベースブランチからフィーチャーブランチ `issue-<id>-<slug>` を作成
4. 変更を実装してコミット
5. プッシュして PR/MR を開く
6. マージ後にブランチを削除
