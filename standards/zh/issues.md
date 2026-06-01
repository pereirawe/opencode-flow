# Issue 跟踪

双层 Issue 跟踪：
- **全局**: `~/.config/opencode/known_issues.md` — opencode 配置级别 Issue
- **项目**: `<项目>/.opencode/known_issues.md` — 项目特定 Issue

## 条目格式

```markdown
### <id>. <标题>
- Status: backlog | ready | open | in-progress | in-review | in-qa | in-publish | resolved
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Report: <用户名> | <模型名>
- Reviewers: <数量> (晋升时设置，默认 1)
- Remote: - | #<远程ID>
- Location: <文件路径>:<行号>
- Description: <简要描述>
- Impact: <影响的对象>
- Business rules: <具体业务逻辑和领域规则>
- Acceptance criteria: <完成必须满足的条件>
- Suggested fix: <方法或下一步>
```

`Business rules:` 对于 `feat` 类型是必需的。
`Reviewers:` 在晋升时设置，在高级审查和 MR 创建时使用。

## 生命周期

```
backlog -> ready -> open -> in-progress -> in-review -> in-qa -> in-publish -> resolved
```

| 状态 | 含义 |
|------|------|
| `backlog` | 已记录，尚未细化 |
| `ready` | 清晰、已批准、可测试 — 准备开发 |
| `open` | 已选择，等待远程创建 |
| `in-progress` | 远程 Issue 已创建，工作开始 |
| `in-review` | 高级审查完成，等待 QA |
| `in-qa` | QA 验证审查后（可能返回 `in-progress`） |
| `in-publish` | Committer 已批准，MR 已创建，等待合并 |
| `resolved` | MR 已批准并合并（移至归档） |
