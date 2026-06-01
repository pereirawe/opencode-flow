# Issue 追跡

2層の Issue 追跡：
- **グローバル**: `~/.config/opencode/known_issues.md` — opencode 設定レベルの Issue
- **プロジェクト**: `<プロジェクト>/.opencode/known_issues.md` — プロジェクト固有の Issue

## エントリ形式

```markdown
### <id>. <タイトル>
- Status: backlog | ready | open | in-progress | in-review | in-qa | in-publish | resolved
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Report: <ユーザー名> | <モデル名>
- Reviewers: <数> (プロモーション時に設定、デフォルト 1)
- Remote: - | #<リモートID>
- Location: <ファイルパス>:<行>
- Description: <簡単な説明>
- Impact: <影響を受ける対象>
- Business rules: <固有のビジネスロジックとドメインルール>
- Acceptance criteria: <完了のために必要な条件>
- Suggested fix: <アプローチまたは次のステップ>
```

`Business rules:` は `feat` タイプに必須です。
`Reviewers:` はプロモーション時に設定され、シニアレビューと MR 作成時に使用されます。

## ライフサイクル

```
backlog -> ready -> open -> in-progress -> in-review -> in-qa -> in-publish -> resolved
```

| ステータス | 意味 |
|-----------|------|
| `backlog` | 記録済み、未精査 |
| `ready` | 明確、承認済み、テスト可能 — 開発準備完了 |
| `open` | 選択済み、リモート作成待ち |
| `in-progress` | リモート Issue 作成済み、作業開始 |
| `in-review` | シニアレビュー完了、QA 待ち |
| `in-qa` | QA がレビュー後を確認中（`in-progress` に戻る可能性あり） |
| `in-publish` | Committer 承認、MR 作成済み、マージ待ち |
| `resolved` | MR 承認・マージ済み（アーカイブに移動） |
