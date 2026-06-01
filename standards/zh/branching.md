# 分支策略

## 命名约定

```
issue-<id>-<slug>
```

- `<id>`: `known_issues.md` 或远程跟踪器中的 Issue 编号
- `<slug>`: 小写连字符分隔的描述

示例：
- `issue-3-weak-url-validation`
- `issue-12-add-analytics-endpoint`

## 工作流

1. 选择基础分支（默认分支或 PM 晋升时选择的其他现有分支）
2. 检出并拉取基础分支
3. 从基础分支创建功能分支 `issue-<id>-<slug>`
4. 实现更改并提交
5. 推送并打开 PR/MR
6. 合并后删除分支
